FROM ubuntu:16.04

# default values
ARG target_os=android

# Update depedency of V8
RUN apt-get -qq update && \
	DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
				lsb-release \
				sudo \
				apt-utils \
				git \
				python \
				lbzip2 \
				curl 	\
				wget	\
				xz-utils

RUN mkdir -p /v8build
WORKDIR /v8build

# DEPOT TOOLS install
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH /v8build/depot_tools:"$PATH"
RUN echo $PATH

# Fetch V8 code
RUN fetch v8
WORKDIR /v8build/v8
RUN git checkout 8.3.110.9
WORKDIR /v8build

RUN echo "target_os= ['${target_os}']">>.gclient
RUN gclient sync

WORKDIR /v8build/v8
RUN echo y | ./build/install-build-deps-android.sh

# generate the build files
RUN ./tools/dev/v8gen.py arm.release -vv
RUN ./tools/dev/v8gen.py arm64.release -vv
RUN ./tools/dev/v8gen.py x64.release -vv
RUN ./tools/dev/v8gen.py x86.release -vv

# set build arguments: monolithic, no snapshot, no custom libc++, no debug symbols
# change the build arguments to build a different version of v8
RUN rm out.gn/arm.release/args.gn
RUN rm out.gn/arm64.release/args.gn
RUN rm out.gn/x64.release/args.gn
RUN rm out.gn/x86.release/args.gn
COPY ./android-arm out.gn/arm.release/args.gn
COPY ./android-arm64 out.gn/arm64.release/args.gn
COPY ./android-x64 out.gn/x64.release/args.gn
COPY ./android-x86 out.gn/x86.release/args.gn

# make sure that argument changes are recognized
RUN touch out.gn/arm.release/args.gn
RUN touch out.gn/arm64.release/args.gn
RUN touch out.gn/x64.release/args.gn
RUN touch out.gn/x86-64.release/args.gn

# Build the V8 monolithic static liblary
RUN ninja -C out.gn/arm.release -t clean
RUN ninja -C out.gn/arm.release v8_monolith
RUN ninja -C out.gn/arm64.release -t clean
RUN ninja -C out.gn/arm64.release v8_monolith
RUN ninja -C out.gn/x64.release -t clean
RUN ninja -C out.gn/x64.release v8_monolith
RUN ninja -C out.gn/x86.release -t clean
RUN ninja -C out.gn/x86.release v8_monolith

# copy built v8 to common folder
WORKDIR /v8build
RUN mkdir libs libs/arm64-v8a libs/armeabi-v7a libs/x86 libs/x86_64
RUN cp v8/out.gn/arm.release/obj/libv8_monolith.a libs/armeabi-v7a
RUN cp v8/out.gn/arm64.release/obj/libv8_monolith.a libs/arm64-v8a
RUN cp v8/out.gn/x64.release/obj/libv8_monolith.a libs/x86
RUN cp v8/out.gn/x86.release/obj/libv8_monolith.a libs/x86_64

# copy header files into include directory
RUN mkdir libs libs/include
RUN cp v8/include libs/include

# libv8 and header files are now in v8build/lib