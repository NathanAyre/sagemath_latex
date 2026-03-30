#!/bin/bash

FILE="$1"

# strip extension
JOBNAME="${FILE%.tex}"

# ensure ./ prefix if no path
if [[ "$JOBNAME" != */* ]]; then
    JOBNAME="./$JOBNAME"
fi

# first LaTeX pass
pdflatex -synctex=1 -interaction=nonstopmode -file-line-error -shell-escape "$FILE"

# run your custom SageTeX script
python3 /usr/local/bin/sagetex-run.py "$JOBNAME"

# second LaTeX pass
pdflatex  -synctex=1 -interaction=nonstopmode -file-line-error -shell-escape "$FILE"
