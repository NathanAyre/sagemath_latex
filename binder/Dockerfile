# Dockerfile for Binder (clean Sage-native setup)

FROM ghcr.io/sagemath/sage-binder-env:10.8.beta1

USER root

# -------------------------
# System packages (separate for caching)
# -------------------------
RUN apt-get update && apt-get install -y \
    texlive-base \
    texlive-latex-recommended \
    texlive-extra-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    dvipng \
    pdf2svg \
    ghostscript \
    imagemagick \
    dvisvgm \
    perl-doc \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Optional tools (replace conda ones)
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    chktex \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# tectonic (manual install)
RUN wget -qO- https://github.com/tectonic-typesetting/tectonic/releases/latest/download/tectonic-x86_64-unknown-linux-gnu.tar.gz \
    | tar xz -C /usr/local/bin --strip-components=1

# texlab (manual install)
RUN wget -q https://github.com/latex-lsp/texlab/releases/latest/download/texlab-x86_64-linux.tar.gz -O texlab.tar.gz && \
    tar -xzf texlab.tar.gz && \
    mv texlab /usr/local/bin/ && \
    rm texlab.tar.gz

# -------------------------
# Scripts
# -------------------------
RUN mkdir -p /usr/local/bin
COPY sagetex-run.py /usr/local/bin/
COPY compile-latex.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/sagetex-run.py
RUN chmod +x /usr/local/bin/compile-latex.sh

ENV PATH="/usr/local/bin:${PATH}"

# -------------------------
# Jupyter config (system level)
# -------------------------
RUN mkdir -p /etc/jupyter
RUN echo "\
c = get_config()\n\
c.LatexConfig.shell_escape = 'allow'\n\
c.LatexConfig.latex_command = 'tectonic'\n\
" > /etc/jupyter/jupyter_server_config.py

# -------------------------
# USE DEFAULT USER (IMPORTANT)
# -------------------------
# DO NOT create your own user — use jovyan

USER jovyan
WORKDIR /home/jovyan

# -------------------------
# Notebooks
# -------------------------
COPY notebooks/ ${HOME}/

# -------------------------
# Sage kernel (same as template)
# -------------------------
RUN mkdir -p $(jupyter --data-dir)/kernels && \
    ln -s /sage/venv/share/jupyter/kernels/sagemath \
          $(jupyter --data-dir)/kernels

ENV PATH="/sage:${PATH}"

# -------------------------
# TeX + SageTeX setup
# -------------------------
RUN mkdir -p ${HOME}/texmf && \
    cp -a /sage/venv/share/texmf/. ${HOME}/texmf/ || true

RUN cp /sage/venv/share/texmf/tex/latex/sagetex/sagetex.sty ${HOME}/

RUN wget -O ${HOME}/fastrecompile.sty \
    https://raw.githubusercontent.com/user202729/tex-fast-recompile/refs/heads/main/tex/fastrecompile.sty

# -------------------------
# Pip installs (separate for caching, using plain pip)
# -------------------------
RUN pip install jupyterlab-lsp
RUN pip install jupyterlab-latex
RUN pip install "python-lsp-server[all]"

RUN pip install jupyter-offlinenotebook
RUN pip install "httpx[cli]"
RUN pip install nbgitpuller
RUN pip install tex-fast-recompile
RUN pip install sage-lsp

# -------------------------
# Node-based language servers
# -------------------------
RUN npm install -g unified-language-server
RUN npm install -g vscode-html-languageserver-bin

# -------------------------
# Enable extensions
# -------------------------
RUN jupyter server extension enable --py jupyter_offlinenotebook --sys-prefix
RUN jupyter server extension enable --py jupyterlab_latex --sys-prefix

# -------------------------
# User Jupyter config
# -------------------------
RUN mkdir -p ${HOME}/.jupyter
RUN cp /etc/jupyter/jupyter_server_config.py ${HOME}/.jupyter/jupyter_server_config.py

RUN echo "\
import logging\n\
class NoNodeJSWarningFilter(logging.Filter):\n\
    def filter(self, record):\n\
        return 'Could not determine jupyterlab build status without nodejs' not in record.getMessage()\n\
logging.getLogger('LabApp').addFilter(NoNodeJSWarningFilter())\n\
" > ${HOME}/.jupyter/jupyter_lab_config.py

# -------------------------
# Sage init (last for caching)
# -------------------------
RUN mkdir -p ${HOME}/.sage
COPY init.sage ${HOME}/.sage/init.sage
