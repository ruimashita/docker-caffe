FROM ubuntu:14.04

MAINTAINER takuya.wakisaka@moldweorp.com

RUN echo "deb http://ftp.jaist.ac.jp/ubuntu/ trusty main restricted universe multiverse \n\
deb-src http://ftp.jaist.ac.jp/ubuntu/ trusty main restricted universe multiverse \n\
deb http://ftp.jaist.ac.jp/ubuntu/ trusty-updates main restricted universe multiverse \n\
deb-src http://ftp.jaist.ac.jp/ubuntu/ trusty-updates main restricted universe multiverse \n\
deb http://ftp.jaist.ac.jp/ubuntu/ trusty-backports main restricted universe multiverse \n\
deb-src http://ftp.jaist.ac.jp/ubuntu/ trusty-backports main restricted universe multiverse \n\
deb http://security.ubuntu.com/ubuntu trusty-security main restricted universe multiverse \n\
deb-src http://security.ubuntu.com/ubuntu trusty-security main restricted universe multiverse" > /etc/apt/sources.list


####
# CUDA
####
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  git \ 
  unzip \
  wget \
  curl \ 

  # for cuda
  build-essential \

  # for caffe
  libprotobuf-dev \
  libleveldb-dev \
  libsnappy-dev \
  libopencv-dev \
  libhdf5-serial-dev \
  protobuf-compiler \
  libatlas-base-dev \  
  libgflags-dev \ 
  libgoogle-glog-dev \
  liblmdb-dev \
  libboost-all-dev \ 

  # for caffe python
  python-dev \  
  python-pip \ 
  python-numpy \
  python-skimage \
  python-scipy \

  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

RUN cd /tmp && \
# Download run file
  wget http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run && \
# Make the run file executable and extract
  chmod +x cuda_*_linux.run && ./cuda_*_linux.run -extract=`pwd` && \
# Install CUDA drivers (silent, no kernel)
  ./NVIDIA-Linux-x86_64-*.run -s --no-kernel-module && \
# Install toolkit (silent)  
  ./cuda-linux64-rel-*.run -noprompt && \
# Clean up
  rm -rf *

###########
# caffe
###########
ENV PYTHONPATH /opt/caffe/python
ENV PATH $PATH:/opt/caffe/.build_release/tools

# Clone the Caffe repo 
RUN cd /opt && git clone https://github.com/BVLC/caffe.git && cd caffe &&  git checkout tags/rc2

WORKDIR /opt/caffe

# Build Caffe core
RUN cp Makefile.config.example Makefile.config && \
  make -j"$(nproc)" all

# Install python deps
RUN pip install -r python/requirements.txt

# Build Caffe python bindings
RUN make -j"$(nproc)" pycaffe

# test + run tests
RUN make -j"$(nproc)" test
# RUN cd /opt/caffe && make runtest

# for bug
RUN ln /dev/null /dev/raw1394
