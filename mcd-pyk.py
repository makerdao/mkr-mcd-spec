#!/usr/bin/env python3

import argparse
import difflib
import json
import random
import os
import sys
import tempfile
import time

from functools import reduce

import pyk
from pyk import KApply, KConstant, KSequence, KVariable, KToken, _notif, _warning, _fatal

# Definition Loading/Running
# --------------------------

MCD_main_file_name = 'kmcd-prelude'

MCD_definition_llvm_dir      = '.build/defn/llvm'
MCD_definition_llvm_kompiled = MCD_definition_llvm_dir    + '/' + MCD_main_file_name + '-kompiled/compiled.json'
MCD_definition_llvm          = pyk.readKastTerm(MCD_definition_llvm_kompiled)

def krun(inputJSON, *krunArgs):
    return pyk.krunJSON(MCD_definition_llvm_dir, inputJSON, krunArgs = list(krunArgs))

def randomSeedArgs(seedbytes = b''):
    return [ '-cRANDOMSEED=' + '#token("' + seedbytes.decode('latin-1') + '", "Bytes")', '-pRANDOMSEED=printf %s' ]

def get_init_config(init_term):
    kast_json = { 'format': 'KAST', 'version': 1, 'term': init_term }
    (_, init_config, _) = krun(kast_json, *randomSeedArgs())
    return pyk.splitConfigFrom(init_config)

# Misc Utilities
# --------------

def randombytes(size):
    return bytearray(random.getrandbits(8) for _ in range(size))

def sanitizeBytes(kast):
    def _sanitizeBytes(_kast):
        if pyk.isKToken(_kast) and _kast['sort'] == 'Bytes':
            if len(_kast['token']) > 2 and _kast['token'][0:2] == 'b"' and _kast['token'][-1] == '"':
                return KToken(_kast['token'][2:-1], 'Bytes')
        return _kast
    return pyk.traverseBottomUp(kast, _sanitizeBytes)

def fromItem(input):
    if pyk.isKApply(input) and input['label'] in [ 'ListItem' , 'SetItem' ]:
        return input['args'][0]
    return None

def flattenAssoc(input, col, elemConverter = lambda x: x):
    if not (pyk.isKApply(input) and input['label'] == '_' + col + '_'):
        return [elemConverter(input)]
    output = []
    work = [ arg for arg in input['args'] ]
    while len(work) > 0:
        first = work.pop(0)
        if pyk.isKApply(first) and first['label'] == '_' + col + '_':
            work.extend(first['args'])
        else:
            output.append(elemConverter(first))
    return output

def flattenList(l):
    return flattenAssoc(l, 'List', elemConverter = fromItem)

def flattenSet(s):
    return flattenAssoc(s, 'Set', elemConverter = fromItem)

def flattenMap(m):
    def _fromMapItem(mi):
        if pyk.isKApply(mi) and mi['label'] == '_|->_':
            return (mi['args'][0], mi['args'][1])
        return None
    return flattenAssoc(m, 'Map', elemConverter = _fromMapItem)

def kMapToDict(s, keyConvert = lambda x: x, valueConvert = lambda x: x):
    return { keyConvert(k): valueConvert(v) for (k, v) in flattenMap(s) }

# Symbol Table (for Unparsing)
# ----------------------------

MCD_definition_llvm_symbols = pyk.buildSymbolTable(MCD_definition_llvm)

MCD_definition_llvm_symbols [ '<_,_>Rat_RAT-COMMON_Rat_Int_Int' ]          = pyk.underbarUnparsing('_/Rat_')
MCD_definition_llvm_symbols [ '_List_' ]                                   = lambda l1, l2: pyk.newLines([l1, l2])
MCD_definition_llvm_symbols [ '_Set_' ]                                    = lambda s1, s2: pyk.newLines([s1, s2])
MCD_definition_llvm_symbols [ '_Map_' ]                                    = lambda m1, m2: pyk.newLines([m1, m2])
MCD_definition_llvm_symbols [ '___KMCD-DRIVER_MCDSteps_MCDStep_MCDSteps' ] = lambda s1, s2: pyk.newLines([s1, s2])

def printMCD(k):
    return pyk.prettyPrintKast(k, MCD_definition_llvm_symbols)

# Building KAST MCD Terms
# -----------------------

bytesToken   = lambda x: KToken(x.decode('latin-1'), 'Bytes')
intToken     = lambda x: KToken(str(x), 'Int')
boolToken    = lambda x: KToken(str(x).lower(), 'Bool')
stringToken  = lambda x: KToken('"' + str(x) + '"', 'String')
hexIntToken  = lambda x: intToken(int(x, 16))
addressToken = lambda x: hexIntToken(x) if x[0:2] == '0x' else stringToken(x)

def steps(step):
    return KApply('STEPS(_)_KMCD-PRELUDE_MCDStep_MCDSteps', [step])

def depthBound(step, bound):
    if type(bound) is int:
        bound = intToken(bound)
    elif type(bound) is str and bound == "*":
        bound = KConstant('*_KMCD-GEN_DepthBound')
    else:
        _fatal('Unknown depth bound: ' + str(bound))
    return KApply('___KMCD-GEN_GenStep_GenStep_DepthBound', [step, bound])

def consJoin(elements, join, unit, assoc = False):
    if len(elements) == 0:
        return KConstant(unit)
    elif assoc and len(elements) == 1:
        return elements[0]
    else:
        return KApply(join, [elements[0], consJoin(elements[1:], join, unit)])

genStep  = KConstant('GenStep_KMCD-GEN_GenStep')
genSteps = KConstant('GenSteps_KMCD-GEN_MCDSteps')
snapshot = KConstant('snapshot_KMCD-GEN_AdminStep')

def mcdSteps(steps):
    return consJoin(steps, '___KMCD-DRIVER_MCDSteps_MCDStep_MCDSteps', '.MCDSteps_KMCD-DRIVER_MCDSteps')

def generatorSequence(genSteps):
    return consJoin(genSteps, '_;__KMCD-GEN_GenStep_GenStep_GenStep', '.GenStep_KMCD-GEN_GenStep', assoc = True)

def generatorChoice(genSteps):
    return consJoin(genSteps, '_|__KMCD-GEN_GenStep_GenStep_GenStep', '.GenStep_KMCD-GEN_GenStep', assoc = True)

def addGenerator(generator):
    return KApply('AddGenerator(_)_KMCD-GEN_AdminStep_GenStep', [generator])

#AddGenerator ( GenPotFileDSR
#             ; GenTimeStep
#             ; GenPotJoin "Alice"
#             ; GenPotDrip
#             ; GenPotExit "Alice"
#             )
generator_lucash_pot = generatorSequence( [ KConstant('GenPotFileDSR_KMCD-GEN_GenPotStep')
                                          , KConstant('GenTimeStep_KMCD-GEN_GenTimeStep')
                                          , KConstant('GenPotJoin_KMCD-GEN_GenPotStep')
                                          , KConstant('GenPotDrip_KMCD-GEN_GenPotStep')
                                          , KConstant('GenPotExit_KMCD-GEN_GenPotStep')
                                          ]
                                        )

#AddGenerator ( GenEndCage
#             ; GenEndCageIlk
#             ; GenEndSkim { "gold" , "Alice" }
#             ; GenEndSkim { "gold" , "Bobby" }
#             ; GenEndThaw
#             ; GenEndFlow
#             ; GenPotJoin "Alice"
#             ; GenPotFileDSR
#             ; GenTimeStep
#             ; GenPotDrip
#             ; GenPotExit "Alice"
#             )
generator_lucash_pot_end = generatorSequence( [ KConstant('GenEndCage_KMCD-GEN_GenEndStep')
                                              , KConstant('GenEndCageIlk_KMCD-GEN_GenEndStep')
                                              , KConstant('GenEndSkim_KMCD-GEN_GenEndStep')
                                              , KConstant('GenEndSkim_KMCD-GEN_GenEndStep')
                                              , KConstant('GenEndThaw_KMCD-GEN_GenEndStep')
                                              , KConstant('GenEndFlow_KMCD-GEN_GenEndStep')
                                              , KConstant('GenPotJoin_KMCD-GEN_GenPotStep')
                                              , KConstant('GenPotFileDSR_KMCD-GEN_GenPotStep')
                                              , KConstant('GenTimeStep_KMCD-GEN_GenTimeStep')
                                              , KConstant('GenPotDrip_KMCD-GEN_GenPotStep')
                                              , KConstant('GenPotExit_KMCD-GEN_GenPotStep')
                                              ]
                                            )

#AddGenerator ( GenGemJoinJoin "gold" "Bobby"
#             ; GenEndCage
#             ; GenEndCageIlk
#             ; GenTimeStep
#             ; GenEndThaw
#             ; GenEndFlow
#             ; GenFlipKick { "gold" , "Bobby" } End Flap
#             ; GenEndSkip "gold"
#             )
generator_lucash_flip_end = generatorSequence( [ KConstant('GenGemJoinJoin_KMCD-GEN_GenGemJoinStep')
                                               , KConstant('GenEndCage_KMCD-GEN_GenEndStep')
                                               , KConstant('GenEndCageIlk_KMCD-GEN_GenEndStep')
                                               , KConstant('GenTimeStep_KMCD-GEN_GenTimeStep')
                                               , KConstant('GenEndThaw_KMCD-GEN_GenEndStep')
                                               , KConstant('GenEndFlow_KMCD-GEN_GenEndStep')
                                               , KConstant('GenFlipKick_KMCD-GEN_GenFlipStep')
                                               , KConstant('GenEndSkip_KMCD-GEN_GenEndStep')
                                               ]
                                             )

#AddGenerator ( GenVatMove "Alice" Vow
#             ; GenGemJoinJoin "gold" "Bobby"
#             ; GenVatHope "Alice" Flap
#             ; GenFlapKick "Alice"
#             ; GenEndCage
#             ; GenFlapYank
#             )
generator_lucash_flap_end = generatorSequence( [ KConstant('GenVatMove_KMCD-GEN_GenVatStep')
                                               , KConstant('GenGemJoinJoin_KMCD-GEN_GenGemJoinStep')
                                               , KConstant('GenVatHope_KMCD-GEN_GenVatStep')
                                               , KConstant('GenFlapKick_KMCD-GEN_GenFlapStep')
                                               , KConstant('GenEndCage_KMCD-GEN_GenEndStep')
                                               , KConstant('GenFlapYank_KMCD-GEN_GenFlapStep')
                                               ]
                                             )

# Violation Detection
# -------------------

def detect_violations(config):
    (_, configSubst) = pyk.splitConfigFrom(config)
    properties = configSubst['PROPERTIES_CELL']
    violations = []
    for (prop, value) in flattenMap(properties):
        if pyk.isKApply(value) and value['label'] == 'Violated(_)_KMCD-PROPS_ViolationFSM_ViolationFSM':
            violations.append(prop['token'])
    return violations

# Solidity Generation
# -------------------

def variablize(input):
    return input.replace('Alice', 'alice')          \
                .replace('Bobby', 'bobby')          \
                .replace('ADMIN', 'admin')          \
                .replace('ANYONE', 'anyone')        \
                .replace('Vat', 'vat')              \
                .replace('Vow', 'vow')              \
                .replace('Cat', 'cat')              \
                .replace('Pot', 'pot')              \
                .replace('Flap', 'flap')            \
                .replace('Flop', 'flop')            \
                .replace('End', 'end')              \
                .replace('Spot', 'spotter')         \
                .replace('Flip_gold', 'goldFlip')   \
                .replace('GemJoin_gold', 'goldJoin')

def solidify(input):
    return variablize(input.replace(' ', '_').replace('"', ''))

def argify(arg):
    newArg = solidify(arg)
    if    newArg in ['alice', 'bobby', 'admin', 'anyone']                                      \
       or newArg in ['cat', 'dai', 'end', 'flap', 'flop', 'jug', 'pot', 'spotter', 'vat', 'vow'] \
       or newArg.endswith('Flip') or newArg.endswith('Join'):
        newArg = 'address(' + newArg + ')'
    if newArg in ['gold']:
        newArg = '"' + newArg + '"'
    return newArg

def unimplemented(s):
    return '// UNIMPLEMENTED << ' + '\n    //'.join(s.split('\n')) + ' >>'

def extractCallEvent(logEvent):
    if pyk.isKApply(logEvent) and logEvent['label'] == 'LogNote':
        caller = solidify(printMCD(logEvent['args'][0]))
        contract = solidify(printMCD(logEvent['args'][1]['args'][0]))
        functionCall = logEvent['args'][1]['args'][1]
        function = functionCall['label'].split('_')[0]
        if function.startswith('init'):
            return []
        if function.endswith('Cage'):
            function = 'cage'
        args = []
        if function.endswith('file'):
            fileable = functionCall['args'][0]['label'].split('_')[0]
            if fileable.endswith('-file'):
                fileable = fileable[0:-5]
            fileargs = functionCall['args'][0]['args']
            args.append('"' + fileable + '"')
            for arg in fileargs:
                args.append(argify(printMCD(arg)))
        else:
            args = [ argify(printMCD(arg)) for arg in functionCall['args'] ]
        return [ caller + '.' + contract + '_' + function + '(' + ', '.join(args) + ');' ]
    elif pyk.isKApply(logEvent) and logEvent['label'] == 'LogTimeStep':
        return [ 'hevm.warp(' + printMCD(logEvent['args'][0]) + ');' ]
    elif pyk.isKApply(logEvent) and logEvent['label'] == 'LogException':
        return [ unimplemented('assertRevert( ' + printMCD(logEvent) + ');') ]
    elif pyk.isKApply(logEvent) and ( logEvent['label'] in [ 'LogMeasure' , 'LogGenStep' , 'LogGenStepFailed' ] ):
        return []
    elif pyk.isKApply(logEvent) and ( logEvent['label'] in [ 'Bite' , 'Transfer' , 'Approval' , 'FlapKick' , 'FlipKick' , 'FlopKick' , 'Poke' , 'NoPoke' ] ):
        return [ unimplemented('assertEvent( ' + printMCD(logEvent) + ');') ]
    else:
        return [ unimplemented(printMCD(logEvent)) ]

def extractTrace(config):
    (_, subst) = pyk.splitConfigFrom(config)
    pEvents = subst['PROCESSED_EVENTS_CELL']
    log_events = flattenList(pEvents)
    call_events = []
    last_event = None
    for event in log_events:
        if pyk.isKApply(event) and event['label'] == 'LogMeasure':
            if last_event is not None:
                call_events.extend(extractCallEvent(last_event))
        last_event = event
    return call_events

def noRewriteToDots(config):
    (cfg, subst) = pyk.splitConfigFrom(config)
    for cell in subst.keys():
        if not pyk.isKRewrite(subst[cell]):
            subst[cell] = pyk.ktokenDots
    return pyk.substitute(cfg, subst)

def buildAssert(contract, field, value):
    assertionData = []
    if pyk.isKToken(value) and value['sort'] == 'Bool':
        actual     = contract + '.' + field + '()'
        comparator = '=='
        expected   = printMCD(intToken(0))
        if value['token'] == 'true':
            comparator = '!='
        assertionData.append((actual, comparator, expected, True))
    elif pyk.isKApply(value) and value['label'] == '_Map_':
        for (k, v) in flattenMap(value):
            if pyk.isKApply(v) and v['label'] == '_Set_':
                for si in flattenSet(v):
                    actual     = contract + '.' + field + '(' + argify(printMCD(k)) + ', ' + argify(printMCD(si)) + ')'
                    comparator = '!='
                    expected   = printMCD(intToken(0))
                    assertionData.append((actual, comparator, expected, True))
            else:
                actual     = contract + '.' + field + '(' + argify(printMCD(k)) + ')'
                comparator = '=='
                expected   = printMCD(v)
                assertionData.append((actual, comparator, expected, False))
    else:
        actual = contract + '.' + field + '()'
        assertionData.append((actual, '==', printMCD(value), False))
    assertions = []
    for (actual, comparator, expected, implemented) in assertionData:
        aStr = 'assertTrue( ' + actual + ' ' + comparator + ' ' + expected + ' );'
        assertions.append(aStr if implemented else unimplemented(aStr))
    return [ variablize(a) for a in assertions ]

def extractAsserts(config):
    (_, subst) = pyk.splitConfigFrom(config)
    snapshots = subst['KMCD_SNAPSHOTS_CELL']
    [preState, postState] = flattenList(snapshots)
    stateDelta = pyk.pushDownRewrites(pyk.KRewrite(preState, postState))
    (_, subst) = pyk.splitConfigFrom(stateDelta)
    asserts = []
    for cell in subst.keys():
        if pyk.isKRewrite(subst[cell]):
            contract = cell.split('_')[0]
            contract = contract[0] + contract[1:].lower()
            field    = cell.split('_')[1].lower()
            if contract == 'Vat' and field == 'line':
                field = 'Line'
            rhs = subst[cell]['rhs']
            asserts.extend(buildAssert(contract, field, rhs))
    stateDelta = noRewriteToDots(stateDelta)
    stateDelta = pyk.collapseDots(stateDelta)
    return (printMCD(stateDelta), asserts)

# Main Functionality
# ------------------

mcdArgs = argparse.ArgumentParser()

mcdCommands = mcdArgs.add_subparsers()

mcdRandomTestArgs = mcdCommands.add_parser('random-test', help = 'Run random tester and check for property violations.')
mcdRandomTestArgs.add_argument( 'depth'           , type = int  ,               help = 'Number of bytes to feed as random input into each run' )
mcdRandomTestArgs.add_argument( 'numRuns'         , type = int  ,               help = 'Number of runs per random seed.'                       )
mcdRandomTestArgs.add_argument( 'initSeeds'       , type = str  , nargs = '*' , help = 'Random seeds to use as run prefixes.'                  )
mcdRandomTestArgs.add_argument( '--emit-solidity' , action = 'store_true'     , help = 'Emit Solidity code reproducing the trace.'             )
mcdRandomTestArgs.set_defaults(emit_solidity = False)

if __name__ == '__main__':
    args = vars(mcdArgs.parse_args())

    gendepth  = args['depth']
    numruns   = args['numRuns']
    randseeds = args['initSeeds']
    emitSol   = args['emit_solidity']

    if len(randseeds) == 0:
        randseeds = [""]

    config_loader = mcdSteps( [ steps(KConstant('ATTACK-PRELUDE'))
                              , addGenerator(generator_lucash_pot_end)
                              , addGenerator(generator_lucash_pot)
                              , addGenerator(generator_lucash_flap_end)
                              , addGenerator(generator_lucash_flip_end)
                              ]
                            )

    (symbolic_configuration, init_cells) = get_init_config(config_loader)
    print()

    all_violations = []
    startTime = time.time()
    for randseed in randseeds:
        for i in range(numruns):
            curRandSeed = bytearray(randseed, 'utf-8') + randombytes(gendepth)

            init_cells['RANDOM_CELL'] = bytesToken(curRandSeed)
            init_cells['K_CELL']      = KSequence([snapshot, genSteps, snapshot])

            initial_configuration = sanitizeBytes(pyk.substitute(symbolic_configuration, init_cells))
            (_, output, _) = krun({ 'format': 'KAST' , 'version': 1 , 'term': initial_configuration }, '--term', '--no-sort-collections')
            print()
            violations = detect_violations(output)
            if len(violations) > 0:
                violation = { 'properties': violations , 'seed': str(curRandSeed), 'output': output }
                all_violations.append(violation)
                print()
                print('### Violation Found')
                print('-------------------')
                print('    Seed: ' + violation['seed'])
                print('    Properties: ' + '\n              , '.join(violation['properties']))
                print(printMCD(violation['output']))
            if emitSol:
                trace = extractTrace(output)
                (stateDelta, asserts) = extractAsserts(output)
                print()
                print('### Solidity')
                print('#### ID:'+str(i))
                print('------------')
                print()
                print('    // Test Run')
                print('    ' + '\n    '.join(trace))
                print()
                print('    // Assertions')
                print('    ' + '\n    '.join(asserts))
                print()
                print('------------')
                print('### /Solidity')
                print()
                print('### State Delta')
                print('---------------')
                print()
                print(stateDelta)
            sys.stdout.flush()
    stopTime = time.time()

    elapsedTime = stopTime - startTime
    perRunTime  = elapsedTime / (numruns * len(randseeds))
    print('\n\nTime Elapsed: ' + str(elapsedTime))
    print('\nTime Per Run: ' + str(perRunTime))

    sys.stdout.flush()
    sys.exit(len(all_violations))
