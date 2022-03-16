#!/usr/bin/python3

import sys
import json

hostname = sys.argv[-1]

with open('ubuntu.json', 'r') as file:
  json_data = json.load(file)
  json_data["Name"]=hostname
  for key in json_data["PropertyMapping"]:
    if key["Key"] == "hostname":
      key["Value"] = hostname
with open ('temp.json', 'w') as file:
  json.dump(json_data, file, indent=2)
