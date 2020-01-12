#!/usr/bin/env python3

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

def printerr(msg):
    sys.stderr.write(msg + '\n')

MCD_main_file_name = 'kmcd-prelude'

MCD_definition_llvm_dir    = '.build/defn/llvm'
MCD_definition_haskell_dir = '.build/defn/haskell'

MCD_definition_llvm_kompiled    = MCD_definition_llvm_dir    + '/' + MCD_main_file_name + '-kompiled/compiled.json'
MCD_definition_haskell_kompiled = MCD_definition_haskell_dir + '/' + MCD_main_file_name + '-kompiled/compiled.json'

def kast_llvm(inputFile, *kastArgs):
    return pyk.kast(MCD_definition_llvm_dir, inputFile, kastArgs = list(kastArgs))

def kast_haskell(inputFile, *kastArgs):
    return pyk.kast(MCD_definition_haskell_dir, inputFile, kastArgs = list(kastArgs))

def krun_llvm(inputFile, *krunArgs):
    return pyk.krun(MCD_definition_llvm_dir, inputFile, krunArgs = list(krunArgs))

def krun_haskell(inputFile, *krunArgs):
    return pyk.krun(MCD_definition_haskell_dir, inputFile, krunArgs = list(krunArgs))

def kastJSON_llvm(inputJSON, *kastArgs):
    return pyk.kastJSON(MCD_definition_llvm_dir, inputJSON, kastArgs = list(kastArgs))

def kastJSON_haskell(inputJSON, *kastArgs):
    return pyk.kastJSON(MCD_definition_haskell_dir, inputJSON, kastArgs = list(kastArgs))

def krunJSON_llvm(inputJSON, *krunArgs):
    return pyk.krunJSON(MCD_definition_llvm_dir, inputJSON, krunArgs = list(krunArgs))

def krunJSON_haskell(inputJSON, *krunArgs):
    return pyk.krunJSON(MCD_definition_haskell_dir, inputJSON, krunArgs = list(krunArgs))

MCD_definition_llvm    = pyk.readKastTerm(MCD_definition_llvm_kompiled)
MCD_definition_haskell = pyk.readKastTerm(MCD_definition_haskell_kompiled)

bytesToken   = lambda x: KToken(x.decode('latin-1'), 'Bytes')
intToken     = lambda x: KToken(str(x), 'Int')
boolToken    = lambda x: KToken(str(x).lower(), 'Bool')
stringToken  = lambda x: KToken('"' + str(x) + '"', 'String')
hexIntToken  = lambda x: intToken(int(x, 16))
addressToken = lambda x: hexIntToken(x) if x[0:2] == '0x' else stringToken(x)

unimplimentedToken = lambda x: KToken('UNIMPLEMENTED << ' + str(x) + ' >>', 'K')

def buildArgument(arg):
    if arg['type'] == 'address':
        return addressToken(arg['value'])
    if arg['type'] == 'bytes32':
        return hexIntToken(arg['value'])
    if arg['type'] == 'string':
        return stringToken(arg['value'])
    if arg['type'] == 'uint256':
        # TODO: Investigate rounding issues caused by casting large floats to int
        return intToken(int(arg['value']))
    else:
        return unimplimentedToken('buildArgument: ' + str(arg))

def buildStep(inputCall):
    contract_name = inputCall['contract_name']
    function_name = inputCall['function_name']
    arguments = [buildArgument(arg) for arg in inputCall['inputs']]
    function_klabel = function_name + '_'.join(['' for i in arguments]) + '_MKR-MCD_'
    return KApply(contract_name + 'Step', [KApply(function_klabel, arguments)])

MCD_definition_llvm_symbols    = pyk.buildSymbolTable(MCD_definition_llvm)
MCD_definition_haskell_symbols = pyk.buildSymbolTable(MCD_definition_haskell)

MCD_definition_llvm_symbols    [ '<_,_>Rat_RAT-COMMON_Rat_Int_Int' ] = pyk.underbarUnparsing('_/Rat_')
MCD_definition_haskell_symbols [ '<_,_>Rat_RAT-COMMON_Rat_Int_Int' ] = pyk.underbarUnparsing('_/Rat_')

MCD_definition_llvm_symbols    [ '_List_' ] = lambda l1, l2: pyk.newLines([l1, l2])
MCD_definition_haskell_symbols [ '_List_' ] = lambda l1, l2: pyk.newLines([l1, l2])

MCD_definition_llvm_symbols    [ '_Set_' ] = lambda s1, s2: pyk.newLines([s1, s2])
MCD_definition_haskell_symbols [ '_Set_' ] = lambda s1, s2: pyk.newLines([s1, s2])

MCD_definition_llvm_symbols    [ '_Map_' ] = lambda m1, m2: pyk.newLines([m1, m2])
MCD_definition_haskell_symbols [ '_Map_' ] = lambda m1, m2: pyk.newLines([m1, m2])

MCD_definition_llvm_symbols    [ '___KMCD-DRIVER_MCDSteps_MCDStep_MCDSteps' ] = lambda s1, s2: pyk.newLines([s1, s2])
MCD_definition_haskell_symbols [ '___KMCD-DRIVER_MCDSteps_MCDStep_MCDSteps' ] = lambda s1, s2: pyk.newLines([s1, s2])

def randomSeedArgs(seedbytes = b''):
    return [ '-cRANDOMSEED=' + '#token("' + seedbytes.decode('latin-1') + '", "Bytes")', '-pRANDOMSEED=printf %s' ]

def get_init_config(init_term):
    kast_json = { 'format': 'KAST', 'version': 1, 'term': init_term }
    (_, init_config, _) = krunJSON_llvm(kast_json, *randomSeedArgs())
    return pyk.splitConfigFrom(init_config)

def detect_violations(config):
    (_, configSubst) = pyk.splitConfigFrom(config)
    properties = configSubst['PROPERTIES_CELL']
    violations = []
    def _gatherViolations(fsmMap):
        if pyk.isKApply(fsmMap) and fsmMap['label'] == '_|->_':
            if fsmMap['args'][1] == pyk.KConstant('Violated_KMCD-PROPS_ViolationFSM'):
                violations.append(fsmMap['args'][0]['token'])
        return fsmMap
    pyk.traverseTopDown(properties, _gatherViolations)
    return violations

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

def randombytes(size):
    return bytearray(random.getrandbits(8) for _ in range(size))

def sanitizeBytes(kast):
    def _sanitizeBytes(_kast):
        if pyk.isKToken(_kast) and _kast['sort'] == 'Bytes':
            if len(_kast['token']) > 2 and _kast['token'][0:2] == 'b"' and _kast['token'][-1] == '"':
                return KToken(_kast['token'][2:-1], 'Bytes')
        return _kast
    return pyk.traverseBottomUp(kast, _sanitizeBytes)

def consJoin(elements, join, unit, assoc = False):
    if len(elements) == 0:
        return KConstant(unit)
    elif assoc and len(elements) == 1:
        return elements[0]
    else:
        return KApply(join, [elements[0], consJoin(elements[1:], join, unit)])

genStep  = KConstant('GenStep_KMCD-GEN_GenStep')
genSteps = KConstant('GenSteps_KMCD-GEN_MCDSteps')

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
                                          , KApply( 'GenPotJoin__KMCD-GEN_GenPotStep_Address' , [ KToken('"Alice"', "String") ] )
                                          , KConstant('GenPotDrip_KMCD-GEN_GenPotStep')
                                          , KApply( 'GenPotExit__KMCD-GEN_GenPotStep_Address' , [ KToken('"Alice"', "String") ] )
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
                                              , KApply( 'GenEndSkim__KMCD-GEN_GenEndStep_CDPID' , [ KApply( '{_,_}_VAT_CDPID_String_Address' , [ KToken('"gold"', "String") , KToken('"Alice"', "String") ] ) ] )
                                              , KApply( 'GenEndSkim__KMCD-GEN_GenEndStep_CDPID' , [ KApply( '{_,_}_VAT_CDPID_String_Address' , [ KToken('"gold"', "String") , KToken('"Bobby"', "String") ] ) ] )
                                              , KConstant('GenEndThaw_KMCD-GEN_GenEndStep')
                                              , KConstant('GenEndFlow_KMCD-GEN_GenEndStep')
                                              , KApply('GenPotJoin__KMCD-GEN_GenPotStep_Address' , [ KToken('"Alice"', "String") ] )
                                              , KConstant('GenPotFileDSR_KMCD-GEN_GenPotStep')
                                              , KConstant('GenTimeStep_KMCD-GEN_GenTimeStep')
                                              , KConstant('GenPotDrip_KMCD-GEN_GenPotStep')
                                              , KApply('GenPotExit__KMCD-GEN_GenPotStep_Address' , [ KToken('"Alice"', "String") ] )
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
generator_lucash_flip_end = generatorSequence( [ KApply( 'GenGemJoinJoin___KMCD-GEN_GenGemJoinStep_String_Address' , [ KToken('"gold"', 'String')
                                                                                                                     , KToken('"Bobby"', 'String')
                                                                                                                     ]
                                                       )
                                               , KConstant('GenEndCage_KMCD-GEN_GenEndStep')
                                               , KConstant('GenEndCageIlk_KMCD-GEN_GenEndStep')
                                               , KConstant('GenTimeStep_KMCD-GEN_GenTimeStep')
                                               , KConstant('GenEndThaw_KMCD-GEN_GenEndStep')
                                               , KConstant('GenEndFlow_KMCD-GEN_GenEndStep')
                                               , KApply( 'GenFlipKick____KMCD-GEN_GenFlipStep_CDPID_Address_Address' , [ KApply('{_,_}_VAT_CDPID_String_Address', [ KToken('"gold"', 'String'), KToken('"Bobby"', 'String') ])
                                                                                                                       , KConstant('End_END_EndContract')
                                                                                                                       , KConstant('Flap_FLAP_FlapContract')
                                                                                                                       ]
                                                       )
                                               , KApply( 'GenEndSkip__KMCD-GEN_GenEndStep_String', [ KToken('"gold"', 'String') ] )
                                               ]
                                             )

#AddGenerator ( GenVatMove "Alice" Vow
#             ; GenGemJoinJoin "gold" "Bobby"
#             ; GenVatHope "Alice" Flap
#             ; GenFlapKick "Alice"
#             ; GenEndCage
#             ; GenFlapYank
#             )
generator_lucash_flap_end = generatorSequence( [ KApply( 'GenVatMove___KMCD-GEN_GenVatStep_Address_Address', [ KToken('"Alice"', "String")
                                                                                                             , KConstant('Vow_VOW_VowContract')
                                                                                                             ]
                                                       )
                                               , KApply( 'GenGemJoinJoin___KMCD-GEN_GenGemJoinStep_String_Address' , [ KToken('"gold"', "String")
                                                                                                                     , KToken('"Bobby"', "String")
                                                                                                                     ]
                                                       )
                                               , KApply( 'GenVatHope___KMCD-GEN_GenVatStep_Address_Address' , [ KToken('"Alice"', "String")
                                                                                                              , KConstant('Flap_FLAP_FlapContract')
                                                                                                              ]
                                                       )
                                               , KApply( 'GenFlapKick__KMCD-GEN_GenFlapStep_Address' , [ KToken('"Alice"', "String") ] )
                                               , KConstant('GenEndCage_KMCD-GEN_GenEndStep')
                                               , KConstant('GenFlapYank_KMCD-GEN_GenFlapStep')
                                               ]
                                             )

if __name__ == '__main__':
    randseed = sys.argv[1]
    gendepth = int(sys.argv[2])
    numruns  = int(sys.argv[3])

    config_loader = mcdSteps( [ steps(KConstant('ATTACK-PRELUDE'))
                              , addGenerator(generator_lucash_pot_end)
                              , addGenerator(generator_lucash_pot)
                              , addGenerator(generator_lucash_flap_end)
                              , addGenerator(generator_lucash_flip_end)
                              ]
                            )

    (symbolic_configuration, init_cells) = get_init_config(config_loader)
    print()

    startTime = time.time()
    all_violations = []
    for i in range(numruns):
        curRandSeed = bytearray(randseed, 'utf-8') + randombytes(gendepth)

        init_cells['RANDOM_CELL'] = bytesToken(curRandSeed)
        init_cells['K_CELL']      = genSteps

        initial_configuration = sanitizeBytes(pyk.substitute(symbolic_configuration, init_cells))
        # print(pyk.prettyPrintKast(initial_configuration, MCD_definition_llvm_symbols))
        (_, output, _) = krunJSON_llvm({ 'format': 'KAST' , 'version': 1 , 'term': initial_configuration }, '--term')
        print()
        violations = detect_violations(output)
        if len(violations) > 0:
            all_violations.append({ 'properties': violations , 'seed': str(curRandSeed), 'output': output })
    stopTime = time.time()

    elapsedTime = stopTime - startTime
    perRunTime  = elapsedTime / numruns
    print('\n\nTime Elapsed: ' + str(elapsedTime))
    print('\nTime Per Run: ' + str(perRunTime))

    if len(all_violations) > 0:
        print('\nViolations Found!')
        print('=================')
        for violation in all_violations:
            print('\nViolation:')
            print('    Seed: ' + violation['seed'])
            print('    Properties: ' + '\n              , '.join(violation['properties']))
    sys.stdout.flush()
    sys.exit(len(all_violations))
