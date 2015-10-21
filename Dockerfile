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

RUN apt-get update && sudo apt-get upgrade

############
# CUDA
############
RUN apt-get update && apt-get install -y \
  linux-headers-$(uname -r) \
  build-essential \
  wget

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

# Add to path
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

###########
# caffe
###########

ENV PYTHONPATH /opt/caffe/python

# Add caffe binaries to path
ENV PATH $PATH:/opt/caffe/.build_release/tools

# Get dependencies
RUN apt-get update && apt-get install -y \
  bc \ 
  cmake \ 
  curl \ 
  gfortran \ 
  git \ 
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
  unzip \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

# Clone the Caffe repo 
RUN cd /opt && git clone https://github.com/BVLC/caffe.git && cd caffe &&  git checkout tags/rc2

# Build Caffe core
RUN cd /opt/caffe && \
  cp Makefile.config.example Makefile.config && \
  make -j"$(nproc)" all


# Install python deps
# RUN cd /opt/caffe && easy_install numpy
# RUN cd /opt/caffe && easy_install pillow
RUN apt-get update && apt-get install -y \
  python-dev \  
  python-pip \ 
  python-numpy \
  python-skimage \
  python-scipy \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/
RUN cd /opt/caffe && pip install -r python/requirements.txt
 

# Numpy include path hack - github.com/BVLC/caffe/wiki/Setting-up-Caffe-on-Ubuntu-14.04
# RUN NUMPY_EGG=`ls /usr/local/lib/python2.7/dist-packages | grep -i numpy` && \
#   ln -s /usr/local/lib/python2.7/dist-packages/$NUMPY_EGG/numpy/core/include/numpy /usr/include/python2.7/numpy

# Build Caffe python bindings
RUN cd /opt/caffe && make pycaffe

 
# Make + run tests
RUN cd /opt/caffe && make -j"$(nproc)" test
# RUN cd /opt/caffe && make runtest

# for bug
sudo ln /dev/null /dev/raw1394
