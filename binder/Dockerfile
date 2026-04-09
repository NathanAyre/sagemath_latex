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

RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh

# # Make sure conda is usable
# RUN conda config --system --set auto_update_conda false && \
#     conda config --system --add channels conda-forge && \
#     conda config --system --set channel_priority strict

# Install mamba (fast solver)
RUN ${CONDA_DIR}/bin/conda install -y mamba && ${CONDA_DIR}/bin/conda clean -ya
# Conda packages (slow → cache this)
RUN ${CONDA_DIR}/bin/mamba install -y -c conda-forge \
    texlab \
    tectonic \
    chktex \
    nodejs \
    && ${CONDA_DIR}/bin/mamba clean -ya
# -------------------------
RUN mkdir -p /usr/local/bin
COPY sagetex-run.py /usr/local/bin/
COPY compile-latex.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/sagetex-run.py
RUN chmod +x /usr/local/bin/compile-latex.sh
# Ensure it's on PATH
ENV PATH="/usr/local/bin:${PATH}"

RUN mkdir -p /etc/jupyter
RUN echo "\
c = get_config()\n\
c.LatexConfig.shell_escape = 'allow'\n\
c.LatexConfig.latex_command = 'tectonic'\n\
" > /etc/jupyter/jupyter_server_config.py
# -------------------------
# Create user (Binder-compatible)
# -------------------------
ARG NB_USER=user
ARG NB_UID=1000
ENV NB_USER=user
ENV NB_UID=1000
ENV HOME=/home/${NB_USER}
RUN adduser --disabled-password --gecos "Default user" --uid ${NB_UID} ${NB_USER}

# -------------------------
# Switch to user
# -------------------------
USER ${NB_USER}
# -------------------------
RUN mkdir -p $(/sage/venv/bin/jupyter --data-dir)/kernels && \
    ln -s /sage/venv/share/jupyter/kernels/sagemath \
          $(/sage/venv/bin/jupyter --data-dir)/kernels
          
RUN mkdir -p ${HOME}/texmf && \
    cp -a /sage/venv/share/texmf/. ${HOME}/texmf/ || true
    
RUN cp /sage/venv/share/texmf/tex/latex/sagetex/sagetex.sty ${HOME}/

RUN wget -O ${HOME}/fastrecompile.sty \
    "https://raw.githubusercontent.com/user202729/tex-fast-recompile/refs/heads/main/tex/fastrecompile.sty"
# -------------------------
ENV PATH="/sage:${PATH}"
WORKDIR /home/${NB_USER}

RUN /sage/venv/bin/pip install \
    jupyterlab-lsp \
    jupyterlab-latex \
    python-lsp-server
RUN pip install jupyter-offlinenotebook
RUN pip install "httpx[cli]"
RUN pip install nbgitpuller
RUN pip install tex-fast-recompile
RUN pip install sage-lsp
ENV PATH="${HOME}/.local/bin:${PATH}"
ENV PATH="${HOME}/.sage/local/bin:${PATH}"
# Enable extensions (still cacheable)
RUN jupyter server extension enable --py jupyter_offlinenotebok --sys-prefix
RUN jupyter server extension enable --py jupyterlab_latex --sys-prefix
# copying the Jupyter config
RUN mkdir -p ${HOME}/.jupyter
RUN cp /etc/jupyter/jupyter_server_config.py ${HOME}/.jupyter/jupyter_server_config.py

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
# -------------------------
# Notebooks (also late so edits don’t bust cache)
# -------------------------
COPY notebooks/* ${HOME}/

# -------------------------
# Permissions
# -------------------------
USER root
RUN chown -R ${NB_USER}:${NB_USER} ${HOME}
USER ${NB_USER}
