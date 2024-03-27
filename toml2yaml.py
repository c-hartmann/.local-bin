#!/usr/bin/python3

import sys

if len(sys.argv) < 2:
	print("error: file argument required")
	sys.exit(1)

import toml
import yaml

dict=toml.load(open(sys.argv[1],"r"))
print(yaml.dump(dict))
