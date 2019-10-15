#!/usr/bin/env python3

import difflib
import json
import sys
import tempfile

from functools import reduce

import pyk
from pyk import KApply, KConstant, KSequence, KVariable, KToken, _notif, _warning, _fatal

def printerr(msg):
    sys.stderr.write(msg + '\n')

def kast(inputFile, *kastArgs):
    return pyk.kast('.build/defn/llvm', inputFile, kastArgs = list(kastArgs))

def krun(inputFile, *krunArgs):
    return pyk.krun('.build/defn/llvm', inputFile, krunArgs = list(krunArgs))

def kastJSON(inputJSON, *kastArgs):
    return pyk.kastJSON('.build/defn/llvm', inputJSON, kastArgs = list(kastArgs))

def krunJSON(inputJSON, *krunArgs):
    return pyk.krunJSON('.build/defn/llvm', inputJSON, krunArgs = list(krunArgs))

MCD_definition_llvm_dir    = '.build/defn/llvm/kmcd-bmc-kompiled/compiled.json'
MCD_definition_haskell_dir = '.build/defn/haskell/kmcd-bmc-kompiled/compiled.json'

MCD_definition_llvm    = pyk.readKastTerm(MCD_definition_llvm_dir)
MCD_definition_haskell = pyk.readKastTerm(MCD_definition_haskell_dir)

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

def get_init_config():
    kast_json = { 'format': 'KAST', 'version': 1, 'term': KConstant('.MCDSteps_KMCD-DRIVER_MCDSteps') }
    (_, init_config, _) = krunJSON(kast_json)
    return pyk.splitConfigFrom(init_config)

(symbolic_configuration, init_cells) = get_init_config()
initial_configuration = pyk.substitute(symbolic_configuration, init_cells)

if __name__ == '__main__':
    if len(sys.argv) <= 1:
        with tempfile.NamedTemporaryFile(mode = 'w') as tempf:
            kast_json = { 'format': 'KAST', 'version': 1, 'term': initial_configuration }
            json.dump(kast_json, tempf)
            tempf.flush()
            (returnCode, kastPrinted, _) = kast(tempf.name, '--input', 'json', '--output', 'pretty')
            if returnCode != 0:
                _fatal('kast returned non-zero exit code reading/printing the initial configuration')
                sys.exit(returnCode)

        fastPrinted = pyk.prettyPrintKast(initial_configuration['args'][0], MCD_symbols)
        _notif('fastPrinted output')
        print(fastPrinted)

        kastPrinted = kastPrinted.strip()
        if fastPrinted != kastPrinted:
            _warning('kastPrinted and fastPrinted differ!')
            for line in difflib.unified_diff(kastPrinted.split('\n'), fastPrinted.split('\n'), fromfile='kast', tofile='fast', lineterm='\n'):
                sys.stderr.write(line + '\n')
            sys.stderr.flush()

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
            print([ pyk.prettyPrintKast(buildStep(call), MCD_symbols) for call in tx['calls'] ])
            _notif("state diff")
            print(tx['state_diffs'])
            sys.stdout.flush()
