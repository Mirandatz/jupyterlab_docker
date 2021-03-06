#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# we must use absolute paths because we want to mount them on containers
SCRIPT_PATH=$(realpath "${BASH_SOURCE[0]}")
DIR_PATH=$(dirname "$SCRIPT_PATH")
echo "$DIR_PATH"

# used to ensure files/directories are created with the correct user:group
USER_ID="$(id -u)"
GROUP_ID="$(id -g)"
USER_NAME="$(whoami)"

PYTHON_VERSION="3.10.4"
JUPORT=13130

# build container, if necessary
export DOCKER_BUILDKIT=1
ENV_TAG="mirandatz/jupyterlab:bioinfo03"
docker build \
    -f Dockerfile \
    --build-arg HOME="/jupyterlab" \
    --build-arg USER_NAME="$USER_NAME" \
    --build-arg USER_ID="$USER_ID" \
    --build-arg GROUP_ID="$GROUP_ID" \
    --build-arg PYTHON_VERSION="$PYTHON_VERSION" \
    -t "$ENV_TAG" .

# create shared dir
mkdir -p jupyterlab_storage

# run container
docker run \
    --rm \
    --runtime nvidia \
    --user "$USER_ID":"$GROUP_ID" \
    -v "${DIR_PATH}/jupyterlab_storage":/jupyterlab/storage \
    -p "$JUPORT":"$JUPORT" \
    --workdir /jupyterlab/storage \
    --env TF_XLA_FLAGS="--tf_xla_auto_jit=2 --tf_xla_cpu_global_jit" \
    --env TF_CPP_MIN_LOG_LEVEL=1 \
    --env TF_FORCE_GPU_ALLOW_GROWTH=true \
    --env JUPORT="$JUPORT" \
    --env JUPYTER_DATA_DIR="/jupyterlab/storage/.jupyter/data" \
    --env HOME="/jupyterlab/storage/" \
    "$ENV_TAG" \
    /bin/bash -c \
    'jupyter lab --port="$JUPORT" --no-browser --ip=0.0.0.0 --NotebookApp.token="" --NotebookApp.password=""'
