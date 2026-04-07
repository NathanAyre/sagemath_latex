from IPython.core.magic import register_cell_magic
from pathlib import Path
from sage.repl.preparse import preparse_file_named, preparse_file   
from sage.misc.latex_standalone import Standalone
from sage.misc.latex import pdf, png

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

    !pdflatex -shell-escape -draftmode -interaction=batchmode {f}.tex
    try:
        sage_file = Path(f"{f}.sagetex.sage")
        cmd = preparse_file(sage_file.read_text(), line_locals)
        exec(cmd)
    except BaseException:
        print("file \'%s.sagetex.sage\' not found or failed to run."%f)
    !pdflatex -shell-escape -interaction=batchmode {f}.tex
    !pdf2svg {f}.pdf {f}.svg 1

    display(html(f" <h2> {f}.tex </h2> <img src='cell://{f}.svg' style='display:block; margin: 0'> "))

from sage.misc.parser import Parser
def parse(expr):
    return Parser(
        make_int = ZZ,
        make_float = RR,
        make_var = var,
        make_function = globals(),
        implicit_multiplication = True
    ).parse_sequence(expr)

get_ipython().Completer.use_jedi = False
