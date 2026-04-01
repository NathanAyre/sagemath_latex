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

RUN pip install jupyter-offlinenotebook
RUN jupyter server extension enable --py jupyter_offlinenotebook --sys-prefix
# Rebuild JupyterLab frontend (this is the critical step)
# RUN /sage/venv/bin/jupyter lab build

COPY sagetex-run.py /usr/local/bin/sagetex-run.py
RUN chmod +x /usr/local/bin/sagetex-run.py

COPY compile-latex.sh /usr/local/bin/compile-latex.sh
RUN chmod +x /usr/local/bin/compile-latex.sh

# Download and install nvm:
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

# in lieu of restarting the shell
RUN "/home/user/.nvm/nvm.sh"

# Download and install Node.js:
RUN nvm install 25

# Verify the Node.js version:
RUN node -v

# Verify npm version:
RUN npm -v
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

RUN pip install jupyterlab-latex
# Force JupyterLab to recognise and enable it
RUN jupyter server extension enable --py jupyterlab_latex --sys-prefix

RUN echo "try:\n\
    print(c)\n\
except BaseException:\n\
    c = get_config()\n\
c.LatexConfig.shell_escape = 'allow'\
\n\
c.LatexConfig.run_times = 1\
\n\
c.LatexConfig.manual_cmd_args = [\
    'compile-latex.sh',\
    '{filename}'\
]\n\
print(c.LatexConfig.manual_cmd_args)\
" > /home/${NB_USER}/.jupyter/jupyter_config.py

RUN pip install --upgrade setuptools[core]
