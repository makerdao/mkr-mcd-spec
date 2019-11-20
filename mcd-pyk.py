#!/usr/bin/env python3

import difflib
import json
import random
import sys
import tempfile
import os

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
    return pyk.krunJSON(MCD_definition_llvm_dir, inputJSON, krunArgs = list(krunArgs), keepTemp = True)

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

if __name__ == '__main__':
    gendepth = int(sys.argv[1])

    config_loader = mcdSteps([steps(KConstant('ATTACK-PRELUDE'))])

    (symbolic_configuration, init_cells) = get_init_config(config_loader)
    init_cells['RANDOM_CELL'] = bytesToken(randombytes(gendepth))
    init_cells['K_CELL']      = genSteps

    initial_configuration = sanitizeBytes(pyk.substitute(symbolic_configuration, init_cells))
    print(pyk.prettyPrintKast(initial_configuration, MCD_definition_llvm_symbols))
    (_, output, _) = krunJSON_llvm({ 'format': 'KAST' , 'version': 1 , 'term': initial_configuration }, '--term')
    print(pyk.prettyPrintKast(output, MCD_definition_llvm_symbols))
    sys.stdout.flush()
