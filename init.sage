from IPython.core.magic import register_cell_magic
from pathlib import Path
from sage.repl.preparse import preparse_file_named, preparse_file   
from sage.misc.latex_standalone import Standalone
# from sage.misc.latex import pdf, png
from time import time
import base64
from sage.symbolic.units import *

__tmp__ = !pip install "httpx[cli]"
__tmp__ = !mktexlsr ~/texmf
fn = tmp_filename(ext = ".zip")
__tmp__ = !httpx "https://mirrors.ctan.org/macros/generic/luatex85.zip" --follow-redirects --download {fn}
__tmp__ = !unzip -o {fn} -d ~/texmf/tex/latex
__tmp__ = get_ipython().run_cell_magic("script", "bash", """
cd ~/texmf/tex/latex/luatex85
latex luatex85.ins > /dev/null 2>&1
""");
__tmp__ = !mktexlsr ~/texmf

preamble = tmp_filename(ext = ".tex")
preamble = Path(preamble)
__tmp__ = !httpx "https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/preamble.tex" --download {preamble}

latex.extra_preamble( preamble.read_text() + "\n" + "\\pagenumbering{gobble}" )

def PDF(f):
    # Read PDF file as binary
    with open(f"{f}.pdf", "rb") as pdf_file:
        # Encode to base64 bytes
        encoded_bytes = base64.b64encode(pdf_file.read())

        # Convert bytes to a UTF-8 string for HTML use
        pdf_base64_string = encoded_bytes.decode('utf-8')

    # Format for HTML
    data_uri = f"data:application/pdf;base64,{pdf_base64_string}"
    id = f"pdf-viewer{time()}"
    display(html(f"""
    <div id="{id}" style="height: 65vh"></div>

    <script type="module">
    import EmbedPDF from 'https://cdn.jsdelivr.net/npm/@embedpdf/snippet@2/dist/embedpdf.js';

    EmbedPDF.init({{
        type: 'container',
        target: document.getElementById('{id}'),
        src: '{data_uri}',
        theme: {{ preference: 'system' }}
    }});
    </script>
    """))

@register_cell_magic
def quick_latex(line, cell):
    """
    IT TAKES A FILENAME (just the base), A DOCUMENTCLASS (IF "standalone", do normal behaviour) AND THEN A DICTIONARY (if not present, it defaults to globals())
    """
    line = line.split()
    f = line[0]
    try:
        if line[1].lower() != "standalone":
            full = True
        else:
            full = False
        doc_class = line[1]
    except BaseException:
        full = False
        # no need to set doc_class
    try:
        line_locals = dict(line[2])
    except BaseException:
        line_locals = globals()
    # print(full, "line: {}".format(line))
    s = cell
    t = Standalone(s, use_sage_preamble = True)
    raw_path_to_tex = t.tex(f + ".tex")
    if full:
        Path(f + ".tex").write_text(
            Path(f + ".tex").read_text().replace(r"\documentclass{standalone}", rf"\documentclass{{{doc_class}}}")
        )

    __tmp__ = !pdflatex -shell-escape -draftmode -interaction=batchmode {f}.tex
    try:
        sage_file = Path(f"{f}.sagetex.sage")
        cmd = preparse_file(sage_file.read_text(), line_locals)
        __tmp__ = get_ipython().run_cell(cmd, silent = True)
    except BaseException:
        print("file \'%s.sagetex.sage\' not found or failed to run."%f)
    __tmp__ = !pdflatex -shell-escape -interaction=batchmode {f}.tex
    # !pdf2svg {f}.pdf {f}.svg 1
    # display(html(f" <h2> {f}.tex </h2> <img src='cell://{f}.svg' style='display:block; margin: 0'> "))
    try:
        PDF(f)
    except BaseException:
        print("pdf display failed")

from sage.misc.parser import Parser
def parse(expr):
    return Parser(
        make_int = ZZ,
        make_float = RR,
        make_var = var,
        make_function = globals(),
        implicit_multiplication = True
    ).parse_sequence(expr)

def safe_parse(expr):
    return Parser(
        make_int = ZZ,
        make_float = RR,
        make_var = lambda x: globals()[x] if x in globals() else SR(x),
        make_function = globals(),
        implicit_multiplication = True
    ).parse_sequence(expr)

def frac(a, b=None):
    if b is None and type(a) == str:
        a, b = safe_parse(a)
        return a/b
    "endif"
    a, b = [
        safe_parse(expr) if type(expr) == str else expr
        for expr in (a, b)
    ];
    return a/b

get_ipython().Completer.use_jedi = False
