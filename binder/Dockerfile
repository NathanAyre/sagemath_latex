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
    chktex \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# Jupyter config (system level)
# • including the creation of the sagemath Jupyter kernel
# -------------------------
ENV PATH="/sage:/sage/venv/bin:${PATH}"
RUN echo "\
from sage.repl.ipython_kernel.install import SageKernelSpec\n\
SageKernelSpec.update()\
" > /tmp/init_sage_kernel.py
RUN sage -python3 /tmp/init_sage_kernel.py
# jupyter server config
RUN mkdir -p /etc/jupyter
RUN echo "\
c = get_config()\n\
c.LatexConfig.shell_escape = 'allow'\n\
c.LatexConfig.latex_command = 'tectonic'\n\
" > /etc/jupyter/jupyter_server_config.py
# Create user with uid 1000
ARG NB_USER=user
ARG NB_UID=1000
ENV NB_USER user
ENV NB_UID 1000
ENV HOME /home/${NB_USER}
RUN adduser --disabled-password --gecos "Default user" --uid ${NB_UID} ${NB_USER}

COPY notebooks/* ${HOME}/
RUN chown -R ${NB_USER}:${NB_USER} ${HOME}
USER ${NB_USER}
WORKDIR /home/${NB_USER}
# ------------------------
# Installing Node (using nvm package manager)
# -------------------------
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
RUN . ~/.bashrc
RUN bash -c "nvm install node"
# -------------------------
# TeX + SageTeX setup
# -------------------------
RUN mkdir -p ${HOME}/texmf && \
    cp -a /sage/venv/share/texmf/. ${HOME}/texmf/ || true

RUN cp /sage/venv/share/texmf/tex/latex/sagetex/sagetex.sty ${HOME}/

RUN wget -O ${HOME}/fastrecompile.sty \
    https://raw.githubusercontent.com/user202729/tex-fast-recompile/refs/heads/main/tex/fastrecompile.sty
# tectonic (manual install)
RUN wget -qO- "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.15.0/tectonic-0.15.0-x86_64-unknown-linux-gnu.tar.gz" \
    | tar xz -C ${HOME}/.local/bin/ --strip-components=1
# texlab (manual install)
RUN wget -q "https://github.com/latex-lsp/texlab/releases/latest/download/texlab-x86_64-linux.tar.gz" -O texlab.tar.gz && \
    tar -xzf texlab.tar.gz && \
    mv texlab ${HOME}/.local/bin/ && \
    rm texlab.tar.gz
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
RUN pip install basedpyright
RUN pip install zuban

RUN mkdir -p ${HOME}/.local/bin/
COPY sagetex-run.py ${HOME}/.local/bin/
COPY compile-latex.sh ${HOME}/.local/bin/
RUN chmod +x ${HOME}/.local/bin/sagetex-run.py
RUN chmod +x ${HOME}/.local/bin/compile-latex.sh
ENV PATH="/home/user/.local/bin:${PATH}"
# -------------------------
# Node-based language servers
# -------------------------
RUN npm config set prefix "${HOME}/.npm-global"
ENV PATH="${HOME}/.npm-global/bin:${PATH}"
# RUN npm init -y
RUN npm install --global \
    bash-language-server \
    dockerfile-language-server-nodejs \
    pyright \
    sql-language-server \
    typescript-language-server \
    unified-language-server \
    vscode-css-languageserver-bin \
    vscode-html-languageserver-bin \
    vscode-json-languageserver-bin \
    yaml-language-server
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
