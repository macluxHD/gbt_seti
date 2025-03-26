FROM nvidia/cuda:12.8.1-base-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive

# From https://github.com/cmbant/docker-cosmobox
#Install latex and python (skip pyside, assume only command line)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    texlive dvipng texlive-latex-extra texlive-fonts-recommended \
    python-setuptools \
    python-dev \
    cython \
    wget \
    zlib1g-dev \
    build-essential \
    ca-certificates \
    && apt-get clean

# In case want to run starcluster from here
#RUN pip install starcluster

#Install cfitsio library for reading FITS files
RUN oldpath=`pwd` && cd /tmp \
    && wget https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio_latest.tar.gz \
    && tar zxvf cfitsio_latest.tar.gz \
    && cd $(ls -d cfitsio-* | head -n 1) \
    && ./configure --prefix=/usr \
    && make -j 2 \
    && make install \
    && make clean \
    && cd $oldpath \
    && rm -Rf /tmp/cfitsio* 

#Install gfortran for building gbt_seti
RUN apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -qqy --no-install-recommends \
    gfortran \
    mysql-server \
    libmysqlclient-dev \
    mongodb-dev \
    libmongo-client-dev \
    git

RUN wget https://github.com/mongodb/mongo-c-driver/releases/download/1.6.2/mongo-c-driver-1.6.2.tar.gz && \
    tar xzf mongo* && \
    cd mongo* && \
    ./configure && \
    make && \
    make install

# Install more necessary packages
RUN apt-get update && \
    apt-get install -qqy --no-install-recommends \
    libcurlpp-dev \
    libpcap-dev \
    libssl-dev \
    libxml2-dev \
    fakeroot \
    libcurl4-gnutls-dev \
    libfftw3-dev \
    libgsl0-dev \
    nvidia-cuda-toolkit

# Install source libs3
RUN git clone https://github.com/bji/libs3.git && \
    cd libs3 && \
    make deb && \
    make install && \
    cd ..

COPY . /app

# Finally, install gbt_seti
RUN cd app/src && \
    make && \
    make install

RUN ["/bin/bash"]
