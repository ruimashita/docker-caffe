FROM kaixhin/cuda:7.5

MAINTAINER takuya.wakisaka@moldweorp.com

RUN echo "deb http://jp.archive.ubuntu.com/ubuntu/ trusty main restricted \n\
deb-src http://jp.archive.ubuntu.com/ubuntu/ trusty main restricted \n\
deb http://jp.archive.ubuntu.com/ubuntu/ trusty-updates main restricted \n\
deb-src http://jp.archive.ubuntu.com/ubuntu/ trusty-updates main restricted \n\
deb http://jp.archive.ubuntu.com/ubuntu/ trusty universe \n\
deb-src http://jp.archive.ubuntu.com/ubuntu/ trusty universe \n\
deb http://jp.archive.ubuntu.com/ubuntu/ trusty-updates universe \n\
deb-src http://jp.archive.ubuntu.com/ubuntu/ trusty-updates universe \n\
deb http://jp.archive.ubuntu.com/ubuntu/ trusty multiverse \n\
deb-src http://jp.archive.ubuntu.com/ubuntu/ trusty multiverse \n\
deb http://jp.archive.ubuntu.com/ubuntu/ trusty-updates multiverse \n\
deb-src http://jp.archive.ubuntu.com/ubuntu/ trusty-updates multiverse \n\
deb http://jp.archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse \n\
deb-src http://jp.archive.ubuntu.com/ubuntu/ trusty-backports main restricted universe multiverse \n\
deb http://security.ubuntu.com/ubuntu trusty-security main restricted \n\
deb-src http://security.ubuntu.com/ubuntu trusty-security main restricted \n\
deb http://security.ubuntu.com/ubuntu trusty-security universe \n\
deb-src http://security.ubuntu.com/ubuntu trusty-security universe \n\
deb http://security.ubuntu.com/ubuntu trusty-security multiverse \n\
deb-src http://security.ubuntu.com/ubuntu trusty-security multiverse" > /etc/apt/sources.list


ENV PYTHONPATH /opt/caffe/python

# Add caffe binaries to path
ENV PATH $PATH:/opt/caffe/.build_release/tools

# Get dependencies
RUN rm -rf /var/lib/apt/lists/ && apt-get update && apt-get install -y \
  bc \ 
  cmake \ 
  curl \ 
  gcc-4.6 \ 
  g++-4.6 \ 
  gcc-4.6-multilib \  
  g++-4.6-multilib \ 
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
  python-dev \  
  python-pip \ 
  unzip \
  wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

# Use gcc 4.6
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-4.6 30 && \
  update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-4.6 30 && \ 
  update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 30 && \
  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.6 30


# Allow it to find CUDA libs
 RUN echo "/usr/local/cuda/lib64" > /etc/ld.so.conf.d/cuda.conf && \
  ldconfig 

# Clone the Caffe repo 
RUN cd /opt && git clone https://github.com/BVLC/caffe.git && cd caffe &&  git checkout tags/rc2

# Build Caffe core
RUN cd /opt/caffe && \
  cp Makefile.config.example Makefile.config && \
  echo "CXX := /usr/bin/g++-4.6" >> Makefile.config && \
  sed -i 's/CXX :=/CXX ?=/' Makefile && \
  make all


# Install python deps
RUN cd /opt/caffe && easy_install numpy
RUN cd /opt/caffe && easy_install pillow
RUN apt-get update && apt-get install -y python-scipy
RUN cd /opt/caffe && pip install -r python/requirements.txt
 

# Numpy include path hack - github.com/BVLC/caffe/wiki/Setting-up-Caffe-on-Ubuntu-14.04
RUN NUMPY_EGG=`ls /usr/local/lib/python2.7/dist-packages | grep -i numpy` && \
  ln -s /usr/local/lib/python2.7/dist-packages/$NUMPY_EGG/numpy/core/include/numpy /usr/include/python2.7/numpy

# Build Caffe python bindings
RUN cd /opt/caffe && make pycaffe

 
# Make + run tests
RUN cd /opt/caffe && make test
# RUN cd /opt/caffe && make runtest
