#!/usr/bin/env python3

import difflib
import json
import sys
import tempfile

from functools import reduce

import pyk

from pyk.kast      import combineDicts, appliedLabelStr, constLabel, underbarUnparsing, K_symbols, KApply, KConstant, KSequence, KVariable, KToken, _notif, _warning, _fatal
from pyk.kastManip import substitute, prettyPrintKast

def printerr(msg):
    sys.stderr.write(msg + '\n')

def kast(inputFile, *kastArgs):
    return pyk.kast('.build/defn/llvm', inputFile, kastArgs = list(kastArgs), kRelease = 'deps/k/k-distribution/target/release/k')

def krun(inputFile, *krunArgs):
    return pyk.krun('.build/defn/llvm', inputFile, krunArgs = list(krunArgs), kRelease = 'deps/k/k-distribution/target/release/k')

MKR_MCD_symbols = { '.List'             : constLabel('.List')
                  , '.MCDStep_MKR-MCD_' : constLabel('.MCDStep')
                  }
ALL_symbols = combineDicts(K_symbols, MKR_MCD_symbols)

symbolic_configuration = KApply ( '<generatedTop>' , [ KApply ( '<mkr-mcd>' , [ KApply ( '<k>', [ KVariable('K_CELL') ] )
                                                                              , KApply ( '<msgSender>', [ KVariable('MSGSENDER_CELL') ] )
                                                                              , KApply ( '<vatStack>' , [ KVariable('VATSTACK_CELL')  ] )
                                                                              , KApply ( '<vat>'      , [ KApply ( '<vat-ward>' , [ KVariable('VAT_WARD_CELL') ] )
                                                                                                        , KApply ( '<vat-can>'  , [ KVariable('VAT_CAN_CELL')  ] )
                                                                                                        , KApply ( '<vat-ilks>' , [ KVariable('VAT_ILKS_CELL') ] )
                                                                                                        , KApply ( '<vat-urns>' , [ KVariable('VAT_URNS_CELL') ] )
                                                                                                        , KApply ( '<vat-gem>'  , [ KVariable('VAT_GEM_CELL')  ] )
                                                                                                        , KApply ( '<vat-dai>'  , [ KVariable('VAT_DAI_CELL')  ] )
                                                                                                        , KApply ( '<vat-sin>'  , [ KVariable('VAT_SIN_CELL')  ] )
                                                                                                        , KApply ( '<vat-debt>' , [ KVariable('VAT_DEBT_CELL') ] )
                                                                                                        , KApply ( '<vat-vice>' , [ KVariable('VAT_VICE_CELL') ] )
                                                                                                        , KApply ( '<vat-Line>' , [ KVariable('VAT_LINE_CELL') ] )
                                                                                                        , KApply ( '<vat-live>' , [ KVariable('VAT_LIVE_CELL') ] )
                                                                                                        ]
                                                                                       )
                                                                              ]
                                                              )
                                                     , KApply ( '<generatedCounter>' , [ KVariable('GENERATED_COUNTER_CELL') ] )
                                                     ]
                                )


init_cells = { 'K_CELL'                     : KSequence([KConstant('.MCDStep_MKR-MCD_')])
             , 'MSGSENDER_CELL'             : KToken('0', 'Address')
             , 'VATSTACK_CELL'              : KConstant('.List')
             , 'VAT_WARD_CELL'              : KConstant('.Map')
             , 'VAT_CAN_CELL'               : KConstant('.Map')
             , 'VAT_ILKS_CELL'              : KConstant('.Map')
             , 'VAT_URNS_CELL'              : KConstant('.Map')
             , 'VAT_GEM_CELL'               : KConstant('.Map')
             , 'VAT_DAI_CELL'               : KConstant('.Map')
             , 'VAT_SIN_CELL'               : KConstant('.Map')
             , 'VAT_DEBT_CELL'              : KToken('0', 'Rad')
             , 'VAT_VICE_CELL'              : KToken('0', 'Rad')
             , 'VAT_LINE_CELL'              : KToken('0', 'Rad')
             , 'VAT_LIVE_CELL'              : KToken('true', 'Bool')
             , 'GENERATED_COUNTER_CELL'     : KToken('0', 'Int')
             }

initial_configuration = substitute(symbolic_configuration, init_cells)

if __name__ == '__main__':
    with tempfile.NamedTemporaryFile(mode = 'w') as tempf:
        kast_json = { 'format': 'KAST', 'version': 1, 'term': initial_configuration }
        json.dump(kast_json, tempf)
        tempf.flush()
        (returnCode, kastPrinted, _) = kast(tempf.name, '--input', 'json', '--output', 'pretty')
        if returnCode != 0:
            _fatal('kast returned non-zero exit code reading/printing the initial configuration')
            sys.exit(returnCode)

    fastPrinted = prettyPrintKast(initial_configuration['args'][0], ALL_symbols)
    _notif('fastPrinted output')
    print(fastPrinted)

    kastPrinted = kastPrinted.strip()
    if fastPrinted != kastPrinted:
        _warning('kastPrinted and fastPrinted differ!')
        for line in difflib.unified_diff(kastPrinted.split('\n'), fastPrinted.split('\n'), fromfile='kast', tofile='fast', lineterm='\n'):
            sys.stderr.write(line + '\n')
        sys.stderr.flush()
