FROM ruimashita/caffe-cpu

RUN cd /opt && git clone https://github.com/alexgkendall/caffe-segnet.git && cd caffe-segnet

WORKDIR /opt/caffe-segnet

# Build Caffe core
RUN cp Makefile.config.example Makefile.config && \
    echo "CPU_ONLY := 1" >> Makefile.config && \
    make -j"$(nproc)" all

# Install python deps
RUN pip install --upgrade pip && \
    # fix: InsecurePlatformWarning: A true SSLContext object is not available.
    pip install pyopenssl ndg-httpsclient pyasn1 && \
    for req in $(cat python/requirements.txt); do pip install $req; done

# Build Caffe python
RUN make -j"$(nproc)" pycaffe

# test + run tests
RUN make -j"$(nproc)" test
# RUN cd /opt/caffe && make runtest
