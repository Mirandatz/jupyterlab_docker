FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04 as BASE

ENV TZ=America/Sao_Paulo
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# python build deps https://devguide.python.org/setup/#build-dependencies
# + git
# + curl, to download stuff
# + graphviz, to plot models
# + libgl1, for opencv2
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    build-essential gdb lcov pkg-config libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev \
    libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev lzma lzma-dev tk-dev uuid-dev zlib1g-dev \
    curl git graphviz libgl1 \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# create user, configure and install pyenv
FROM BASE as WITH_USER
ARG UNAME
ARG UID
ARG GID
RUN groupadd --gid $GID $UNAME
RUN useradd --create-home --uid $UID --gid $GID --shell /bin/bash $UNAME
USER $UNAME
ENV PYENV_ROOT /home/$UNAME/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

SHELL ["/bin/bash", "-c"]
RUN curl https://pyenv.run | bash


# download, compile and configure python
FROM WITH_USER as WITH_PYTHON
ARG PYTHON_VERSION
RUN CONFIGURE_OPTS="--enable-optimizations --with-lto" pyenv install $PYTHON_VERSION
RUN pyenv global $PYTHON_VERSION


# create project dir and change its owner
FROM WITH_PYTHON as WITH_PYTHON_REQUIREMENTS
ENV JUPYTER_LAB_DIR=/jupyterlab
USER root
RUN mkdir $JUPYTER_LAB_DIR && chown -R $UID:$GID $JUPYTER_LAB_DIR
USER $UNAME

ENV VIRTUAL_ENV=${JUPYTER_LAB_DIR}/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN python -m venv $VIRTUAL_ENV
COPY requirements.txt ${JUPYTER_LAB_DIR}/requirements.txt
RUN pip install -r ${JUPYTER_LAB_DIR}/requirements.txt --no-cache-dir

WORKDIR $JUPYTER_LAB_DIR
