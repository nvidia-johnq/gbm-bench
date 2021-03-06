ARG CUDA_VERSION
ARG XGB_HASH=6d293020fbfa2c67b532d550fe5d55689662caac
FROM nvidia/cuda:$CUDA_VERSION-devel-ubuntu16.04
SHELL ["/bin/bash", "-c"]
# Install conda (and use python 3.7)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        doxygen \
        git \
        graphviz \
        libcurl4-openssl-dev \
        libboost-all-dev \
        make \
        tar \
        unzip \
        wget \
        zlib1g-dev && \
    rm -rf /var/lib/apt/*

RUN curl -o /opt/miniconda.sh \
	https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x /opt/miniconda.sh && \
    /opt/miniconda.sh -b -p /opt/conda && \
    /opt/conda/bin/conda update -n base conda && \
    rm /opt/miniconda.sh
ENV PATH /opt/conda/bin:$PATH

RUN conda install -c conda-forge \
        bokeh \
        h5py \
        ipython \
        ipywidgets \
        jupyter \
        matplotlib \
        nose \
        numpy \
        pandas \
        Pillow \
        pydot \
        pylint\
        psutil\
        scikit-learn \
        scipy \
        six \
        dask \
        distributed \
        tqdm && \
        conda clean -ya && \
        pip install kaggle tqdm && \
        conda install -c rapidsai -c nvidia -c conda-forge -c defaults cudf=0.15.0 dask-cuda rmm librmm rapids-xgboost cuml=0.15

# cmake
ENV CMAKE_SHORT_VERSION 3.14
ENV CMAKE_LONG_VERSION 3.14.7
RUN wget --no-check-certificate \
        "https://cmake.org/files/v${CMAKE_SHORT_VERSION}/cmake-${CMAKE_LONG_VERSION}.tar.gz" && \
    tar xf cmake-${CMAKE_LONG_VERSION}.tar.gz && \
    cd cmake-${CMAKE_LONG_VERSION} && \
    ./bootstrap --system-curl && \
    make -j && \
    make install && \
    cd .. && \
    rm -rf cmake-${CMAKE_LONG_VERSION}.tar.gz cmake-${CMAKE_LONG_VERSION}

# lightgbm
RUN pip install lightgbm

# catboost
RUN pip install catboost

# xgboost
RUN git config --global http.sslVerify false && \
    git clone --recursive https://github.com/dmlc/xgboost /opt/xgboost && \
    cd /opt/xgboost && \
    git checkout $XGB_HASH && \
    git submodule update --init --recursive && \
    mkdir build && \
    cd build && \
    RMM_ROOT=/opt/conda cmake .. \
        -DUSE_CUDA=ON \
        -DUSE_NCCL=ON \
        -DPLUGIN_RMM=ON && \
    make -j4 && \
    git log > xgb_log.txt && \
    cd ../python-package && \
    pip uninstall -y xgboost && \
    python setup.py install
