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
    print("Usage: change-deps.py <folder> <package> <revision, version, tag or branch>")
    print("  prepend a t_ when using a tag")
    print("  prepend a b_ when using a branch")
    print("  prepend a v_ when using a version")
    sys.exit(-1)

folder = sys.argv[1]
package = sys.argv[2]
revision = sys.argv[3]

files = [os.path.join(folder, f, 'Cargo.toml') for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f, 'Cargo.toml')) and f != 'example']

if("b_" in revision):
    print("setting package", package, "to branch", revision.replace("b_", ""))
elif("v_" in revision):
    print("setting package", package, "to version", revision.replace("v_", ""))
elif("t_" in revision):
    print("setting package", package, "to tag", revision.replace("t_", ""))
else:
    print("setting package", package, "to revision", revision)

for f in files:
    print("  updating", f)
    toml_file = TOMLFile(f)
    content = toml_file.read()

    if package in content["dependencies"]:

        print(content["dependencies"][package])

        if "tag" in content["dependencies"][package]: content["dependencies"][package].remove("tag")
        if "rev" in content["dependencies"][package]: content["dependencies"][package].remove("rev")
        if "branch" in content["dependencies"][package]: content["dependencies"][package].remove("branch")

        # check for revision or branch or version
        if "b_" in revision:
            content["dependencies"][package]["branch"] = revision.replace("b_", "")
        elif "v_" in revision:
            content["dependencies"][package] = revision.replace("v_", "")
        elif "t_" in revision:
            content["dependencies"][package]["tag"] = revision.replace("t_", "")
        else:
            content["dependencies"][package]["rev"] = revision
        print("    new content:", package, " = ", content["dependencies"][package])

        toml_file.write(content)

    print("")

print("all done")