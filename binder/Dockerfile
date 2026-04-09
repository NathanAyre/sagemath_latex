# Dockerfile for Binder (optimized for caching)

FROM ghcr.io/sagemath/sage-binder-env:10.8.beta1

USER root

# -------------------------
# System packages (slow → cache this)
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

    # -------------------------
# Install Miniforge (conda + mamba)
# -------------------------
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh

# Make sure conda is usable
RUN conda config --system --set auto_update_conda false && \
    conda config --system --add channels conda-forge && \
    conda config --system --set channel_priority strict

# Install mamba (fast solver)
RUN conda install -y mamba && conda clean -ya
# Conda packages (slow → cache this)
RUN mamba install -y -c conda-forge \
    jupyterlab-lsp \
    jupyterlab-latex \
    python-lsp-server \
    texlab \
    tectonic \
    chktex \
    nodejs \
    && mamba clean -ya

# -------------------------
# Pip packages (still relatively slow)
# -------------------------
RUN pip install jupyter-offlinenotebook
RUN pip install "httpx[cli]"
RUN pip install nbgitpuller
RUN pip install git+https://github.com/user202729/tex-fast-recompile
RUN httpx "https://raw.githubusercontent.com/user202729/tex-fast-recompile/refs/heads/main/tex/fastrecompile.sty"\
    --download /home/jovyan/fastrecompile.sty
RUN pip install sage-lsp
# Enable extensions (still cacheable)
RUN jupyter server extension enable --py jupyter_offlinenotebook --sys-prefix
RUN jupyter server extension enable --py jupyterlab_latex --sys-prefix
# -------------------------
# Create user (Binder-compatible)
# -------------------------
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV NB_USER=jovyan
ENV NB_UID=1000
ENV HOME=/home/${NB_USER}

# (User already exists in base image, so don't adduser)

# -------------------------
# Switch to user
# -------------------------
USER ${NB_USER}
WORKDIR /home/${NB_USER}

# -------------------------
# Jupyter config (lightweight → keep late)
# -------------------------
RUN mkdir -p ${HOME}/.jupyter
RUN echo "\
c = get_config()\n\
c.LatexConfig.shell_escape = 'allow'\n\
c.LatexConfig.latex_command = 'tectonic'\n\
" > ${HOME}/.jupyter/jupyter_server_config.py

# Suppress NodeJS warning
RUN echo "\
import logging\n\
class NoNodeJSWarningFilter(logging.Filter):\n\
    def filter(self, record):\n\
        return 'Could not determine jupyterlab build status without nodejs' not in record.getMessage()\n\
logging.getLogger('LabApp').addFilter(NoNodeJSWarningFilter())\n\
" > ${HOME}/.jupyter/jupyter_lab_config.py

# -------------------------
# Sage init + scripts (MOST frequently changed → very last)
# -------------------------
RUN mkdir -p ${HOME}/.sage
COPY init.sage ${HOME}/.sage/init.sage

# User-local bin (instead of /usr/local/bin)
RUN mkdir -p ${HOME}/.local/bin
COPY sagetex-run.py ${HOME}/.local/bin/
COPY compile-latex.sh ${HOME}/.local/bin/
RUN chmod +x ${HOME}/.local/bin/*

# Ensure it's on PATH
ENV PATH="${HOME}/.local/bin:${PATH}"

# -------------------------
# Optional: texmf copy (can be removed if not needed)
# -------------------------
RUN mkdir -p ${HOME}/texmf && \
    cp -a /srv/conda/envs/notebook/share/texmf/. ${HOME}/texmf/ || true
# COPY /srv/conda/envs/notebook/share/texmf/tex/latex/sagetex.sty ${HOME}/
# -------------------------
# Notebooks (also late so edits don’t bust cache)
# -------------------------
COPY notebooks/ ${HOME}/

# -------------------------
# Permissions
# -------------------------
USER root
RUN chown -R ${NB_USER}:users ${HOME}
USER ${NB_USER}
