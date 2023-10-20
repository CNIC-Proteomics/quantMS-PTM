# nextflow-CORE ----

# our base image
FROM ubuntu:22.04

# Update apt package
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y


# Install packages
RUN apt-get install -y vim
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git


# BEGIN: for debugging ----

# Install VSC
# RUN apt-get install -y gpg
# COPY code_1.82.3-1696245001_amd64.deb /tmp/.
# RUN  apt-get install -y /tmp/code_1.82.3-1696245001_amd64.deb

# END: for debugging ----

################
# REQUIREMENTS #
################

# Install the requirements for nextflow
RUN apt-get update -y
RUN apt-get install -y openjdk-19-jre-headless

# Install the requirements for nf-core
RUN apt-get -y install python-is-python3 python3-pip

# Install the requirements for singularity
RUN apt-get -y install build-essential libseccomp-dev libglib2.0-dev pkg-config squashfs-tools cryptsetup runc


############
# NEXTFLOW #
############

# Install nextflow
RUN mkdir -p /usr/local/bin && cd /usr/local/bin && curl -s https://get.nextflow.io | bash
# RUN echo 'export PATH=/usr/local/nextflow:$PATH' >> /home/nextflow/.bashrc && source /home/nextflow/.bashrc
# RUN echo 'export PATH=/usr/local/nextflow:$PATH' >> /home/nextflow/.bashrc

# Setting up the environment variables
ENV NXF_HOME "/opt/nextflow"
RUN mkdir -p "${NXF_HOME}"
ENV NXF_WORK "/opt/nextflow/work"
RUN mkdir -p "${NXF_WORK}"
ENV NXF_LOG "/opt/nextflow/log"
RUN mkdir -p "${NXF_LOG}"


###########
# NF-CORE #
###########

# Python Package Index
RUN pip install nf-core


###############
# SINGULARITY #
###############

# Install go
RUN export VERSION=1.20.5 OS=linux ARCH=amd64 && cd /tmp && wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && rm go$VERSION.$OS-$ARCH.tar.gz

# Set the Environment variable PATH to point to Go
RUN echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc && source ~/.bashrc

# Download SingularityCE from a release
RUN export VERSION=3.11.3 && wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz && tar -xzf singularity-ce-${VERSION}.tar.gz && cd singularity-ce-${VERSION}

# Compile the SingularityCE source code
RUN ./mconfig && make -C builddir && make -C builddir install


# THE REST HAS TO BE CREATED IN SINGULARITY ---------

#############
# MSFragger #
#############

# Copy Singuilarity container
COPY singularity/search_engine.sif  /opt/.


###################
# SHIFTS & SOLVER #
##################

# # Copy Singuilarity container
# COPY singularity/shifts.sif  /opt/.
# COPY singularity/solver.sif  /opt/.

###############
# PTM-compass #
###############

# # Copy Singuilarity container
# COPY singularity/ptm-compass.sif  /opt/.


# ENVIRONMENT variables ---------


####################
# USER environment #
####################

# Setting up the enviroment of 'root' and 'nextflow' user
# COPY setup.root.sh /tmp/.
# RUN cat "/tmp/setup.root.sh" >> /root/.bashrc
# RUN chmod -R og+w /opt/nextflow/cache /opt/nextflow/tmp
# RUN addgroup nextflow
# RUN adduser --ingroup nextflow --disabled-password --gecos '' nextflow
# COPY setup.nextflow.sh /tmp/.
# RUN cat "/tmp/setup.nextflow.sh" >> /home/nextflow/.bashrc
USER root
COPY setup.root.sh /tmp/.
RUN cat "/tmp/setup.root.sh" >> /root/.bashrc

# Setting up the environment variables
# WORKDIR /opt/PTM-compass
WORKDIR /mnt/tierra/PTM-compass

