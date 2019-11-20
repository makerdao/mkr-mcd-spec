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

if __name__ == '__main__':
    (symbolic_configuration, init_cells) = get_init_config(KConstant('.MCDSteps_KMCD-DRIVER_MCDSteps'))
    initial_configuration = pyk.substitute(symbolic_configuration, init_cells)

    if len(sys.argv) <= 1:
        fastPrinted = pyk.prettyPrintKast(initial_configuration['args'][0], MCD_definition_llvm_symbols)
        _notif('fastPrinted output')
        print(fastPrinted)
        sys.stdout.flush()

    elif len(sys.argv) > 1:
        input_scrape = sys.argv[1]
        scrape = None
        with open(input_scrape, 'r') as scrape_file:
            scrape = json.load(scrape_file)

        txs = []
        for txKey in scrape.keys():
            if scrape[txKey]['status'] != 'ok':
                continue
            tx_result = scrape[txKey]['response']
            tx_calls = [ call for call in tx_result['calls'] if call['contract_name'] == 'Vat' ]
            if len(tx_calls) > 0:
                txs.append({ 'calls': tx_calls, 'state_diffs': tx_result['state_diffs'] })
            print(tx_result)
            print(tx_calls)
            sys.stdout.flush()

        for tx in txs:
            print([ pyk.prettyPrintKast(buildStep(call), MCD_definition_llvm_symbols) for call in tx['calls'] ])
            _notif("state diff")
            print(tx['state_diffs'])
            sys.stdout.flush()
