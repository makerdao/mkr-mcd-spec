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
                                                                              , KApply ( '<vat>'      , [ KApply ( '<ward>' , [ KVariable('WARD_CELL') ] )
                                                                                                        , KApply ( '<can>'  , [ KVariable('CAN_CELL')  ] )
                                                                                                        , KApply ( '<ilks>' , [ KVariable('ILKS_CELL') ] )
                                                                                                        , KApply ( '<urns>' , [ KVariable('URNS_CELL') ] )
                                                                                                        , KApply ( '<gem>'  , [ KVariable('GEM_CELL')  ] )
                                                                                                        , KApply ( '<dai>'  , [ KVariable('DAI_CELL')  ] )
                                                                                                        , KApply ( '<sin>'  , [ KVariable('SIN_CELL')  ] )
                                                                                                        , KApply ( '<debt>' , [ KVariable('DEBT_CELL') ] )
                                                                                                        , KApply ( '<vice>' , [ KVariable('VICE_CELL') ] )
                                                                                                        , KApply ( '<Line>' , [ KVariable('LINE_CELL') ] )
                                                                                                        , KApply ( '<live>' , [ KVariable('LIVE_CELL') ] )
                                                                                                        ]
                                                                                       )
                                                                              ]
                                                              )
                                                     , KApply ( '<generatedCounter>' , [ KVariable('GENERATED_COUNTER_CELL') ] )
                                                     ]
                                )


init_cells = { 'K_CELL'                 : KSequence([KConstant('.MCDStep_MKR-MCD_')])
             , 'MSGSENDER_CELL'         : KToken('0', 'Address')
             , 'VATSTACK_CELL'          : KConstant('.List')
             , 'WARD_CELL'              : KConstant('.Map')
             , 'CAN_CELL'               : KConstant('.Map')
             , 'ILKS_CELL'              : KConstant('.Map')
             , 'URNS_CELL'              : KConstant('.Map')
             , 'GEM_CELL'               : KConstant('.Map')
             , 'DAI_CELL'               : KConstant('.Map')
             , 'SIN_CELL'               : KConstant('.Map')
             , 'DEBT_CELL'              : KToken('0', 'Rad')
             , 'VICE_CELL'              : KToken('0', 'Rad')
             , 'LINE_CELL'              : KToken('0', 'Rad')
             , 'LIVE_CELL'              : KToken('true', 'Bool')
             , 'GENERATED_COUNTER_CELL' : KToken('0', 'Int')
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
