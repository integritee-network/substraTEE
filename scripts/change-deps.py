#!/usr/bin/env python3

# script to change dependencies of packages

# the module tomlkit needs to be installed for python3: pip3 install tomlkit
# if you don't have pip3 installed: sudo apt install python3-pip

import sys
import os
import tomlkit

from tomlkit.toml_document import TOMLDocument
from tomlkit.toml_file import TOMLFile

if len(sys.argv) != 4:
    print("Usage: change-deps.py <folder> <package> <revision or branch>")
    sys.exit(-1)

folder = sys.argv[1]
package = sys.argv[2]
revision = sys.argv[3]

files = [os.path.join(folder, f, 'Cargo.toml') for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f, 'Cargo.toml')) and f != 'example']

for f in files:
    print("updating ", f)
    toml_file = TOMLFile(f)
    content = toml_file.read()

    if package in content["dependencies"]:

        if "tag" in content["dependencies"][package]: content["dependencies"][package].remove("tag")
        if "rev" in content["dependencies"][package]: content["dependencies"][package].remove("rev")
        content["dependencies"][package]["rev"] = revision
        print("  new content =", content["dependencies"][package])

        toml_file.write(content)

    print("")

print("all done")