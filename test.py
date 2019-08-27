#!/usr/bin/env python3

import sys
import json

input_scrape = sys.argv[1]
scrape = None
with open(input_scrape, 'r') as scrape_file:
    scrape = json.load(scrape_file)

vat_functions = [ 'auth' , 'cage' , 'deny' , 'drip' , 'flux' , 'fold' , 'fork' , 'frob' , 'grab' , 'heal' , 'hope' , 'init' , 'move' , 'nope' , 'rely' , 'slip' , 'suck' , 'wish' ]

calls = []
for txKey in scrape.keys():
    if scrape[txKey]['status'] != 'ok':
        continue
    tx_result = scrape[txKey]['response']
    for call in tx_result['calls']:
        if call['function_name'] in vat_functions:
            call_entry = { 'call' : call , 'state_diffs' : tx_result['state_diffs'] }
            calls.append(call_entry)

print(json.dumps(calls, indent = 4))
