FROM ghcr.io/sagemath/sage-binder-env:10.7

USER root

# --- ADD THIS BLOCK ---
RUN apt-get update && apt-get install -y \
    texlive-fonts-recommended \
    texlive-plain-generic \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-latex-recommended \
    texlive-publishers \
    texlive-science \
    texlive-xetex \
    cm-super \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN /sage/venv/bin/pip install jupyterlab-latex
RUN jupyter labextension install @jupyterlab/latex
# --- END BLOCK ---

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

RUN mkdir -p $(jupyter --data-dir)/kernels
RUN ln -s /sage/venv/share/jupyter/kernels/sagemath $(jupyter --data-dir)/kernels

ENV PATH="/sage:$PATH"

WORKDIR /home/${NB_USER}

RUN mkdir -p /home/${NB_USER}/.jupyter
RUN echo "\
import logging\n\
\n\
class NoNodeJSWarningFilter(logging.Filter):\n\
    def filter(self, record):\n\
        return 'Could not determine jupyterlab build status without nodejs' not in record.getMessage()\n\
\n\
logging.getLogger('LabApp').addFilter(NoNodeJSWarningFilter())\n\
" > /home/${NB_USER}/.jupyter/jupyter_lab_config.py
