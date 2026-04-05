#!/home/sc_serv/sage/local/var/lib/sage/venv-python3.12.5/bin/python3
import hashlib
import sys
import os
import re
import subprocess
import shutil
import argparse
from sage.repl.preparse import *
# from sage.repl.load import load
from pathlib import Path
"""
Given a filename f, examines f.sagetex.sage and f.sagetex.sout and
runs Sage if necessary.
"""
def run(src):
    if src.endswith('.sagetex.sage'):
        src = src[:-13]
    else:
        src = os.path.splitext(src)[0]

    # Ensure results are output in the same directory as the source files
    os.chdir(os.path.dirname(src))
    src = os.path.basename(src)

    usepackage = r'usepackage(\[.*\])?{sagetex}'
    uses_sagetex = False

    # If it does not use sagetex, obviously running sage is unnecessary.
    if os.path.isfile(src + '.tex'):
        with open(src + '.tex') as texf:
            for line in texf:
                if line.strip().startswith(r'\usepackage') and re.search(usepackage, line):
                    uses_sagetex = True
                    break
    else:
        # The .tex file might not exist if LaTeX output was put to a different
        # directory, so in that case just assume we need to build.
        uses_sagetex = True

    if not uses_sagetex:
        print(src + ".tex doesn't seem to use SageTeX, exiting.", file=sys.stderr)
        # sys.exit(1)
        return;

    # if something goes wrong, assume we need to run Sage
    run_sage = True
    ignore = r"^( _st_.goboom|print\('SageT| ?_st_.current_tex_line)"

    try:
        with open(src + '.sagetex.sage', 'r') as sagef:
            h = hashlib.md5()
            for line in sagef:
                if not re.search(ignore, line):
                    h.update(bytearray(line,'utf8'))
    except IOError:
        print('{0}.sagetex.sage not found, I think you need to typeset {0}.tex f \
irst.'.format(src), file=sys.stderr)
        # sys.exit(1)
        return;

    try:
        with open(src + '.sagetex.sout', 'r') as outf:
            for line in outf:
                m = re.match('%([0-9a-f]+)% md5sum', line)
                if m:
                    print('computed md5:', h.hexdigest())
                    print('sagetex.sout md5:', m.group(1))
                    if h.hexdigest() == m.group(1):
                        run_sage = False
                        break
    except IOError:
        pass

    if run_sage:
        print('Need to run Sage on {0}.'.format(src))
        from sage.repl.interpreter import SageTerminalApp as z
        from sage.repl.ipython_extension import SageCustomizations as C

        app = z()
        app.init_shell()
        shell = app.shell
        o = C(shell)
        o.run_init()

        shell.run_cell(
            Path(f"{src}.sagetex.sage").read_text()
        )
    else:
        print('Not necessary to run Sage on {0}.'.format(src))



