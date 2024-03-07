# %labels
#     Author jmrodriguezc@cnic.es
#     Version v0.0.1
# 
# %help
#     This file create the Nextflow image


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
RUN apt-get install -y openjdk-19-jre-headless

# Install the requirements for nf-core
RUN apt-get -y install python-is-python3 python3-pip

# # Install the requirements for singularity
# RUN apt-get -y install build-essential libseccomp-dev libglib2.0-dev pkg-config squashfs-tools cryptsetup runc


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


# ###############
# # SINGULARITY #
# ###############

# # Install go
# RUN export VERSION=1.20.5 OS=linux ARCH=amd64 && cd /tmp && wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && rm go$VERSION.$OS-$ARCH.tar.gz

# # Set the Environment variable PATH to point to Go
# RUN echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc && source ~/.bashrc

# # Download SingularityCE from a release
# RUN export VERSION=3.11.3 && wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz && tar -xzf singularity-ce-${VERSION}.tar.gz && cd singularity-ce-${VERSION}

# # Compile the SingularityCE source code
# RUN ./mconfig && make -C builddir && make -C builddir install


####################################
# ENVIRONMENT variables and EXPOSE #
####################################

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
WORKDIR /workspace



# Expose port 8080 (the port your server will listen on).
EXPOSE 8080

# Define the command to execute when the container starts.
CMD ["/mnt/tierra/nextflow-api/scripts/startup-local.sh file"]




# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   INSTALLATION OF THE REST OF MODULES 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# THE REST HAS TO BE CREATED IN SINGULARITY ---------
# BAD IDEA!!!! Because...
# It is strongly recommended that you don't use the Docker container for running Singularity images, only for creating them, since the Singularity command runs within the container as the root user.
#############
# MSFragger #
#############
# # Copy Singuilarity container
# COPY singularity/search_engine.sif  /opt/.
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





#
# SEARCH_ENGINE ----------
#
# %help
#     This Singularity container is used for the search engine:
#     1. Obtain the DECOY using the DecoyPYrat (modified by jmrodriguezc)
#         https://www.sanger.ac.uk/science/tools/decoypyrat
# 
#     2. Convert the raw file to mZML format using the ThermoRawFileParser:
#         https://github.com/compomics/ThermoRawFileParser
#         https://pubmed.ncbi.nlm.nih.gov/31755270/
# 
#     3. Execution of MSFragger:
#         https://msfragger.nesvilab.org/
# 

ARG BUILD_PATH=search_engine

# Update apt package
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y


# Install packages
RUN apt-get install -y vim
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git
RUN apt-get install -y unzip


################
# REQUIREMENTS #
################

# Requirements for MSFragger
RUN apt-get install -y openjdk-19-jre-headless

# Requeriments for ThermoRawFileParser
RUN apt-get install -y ca-certificates gnupg
# install mono (ThermoRawFileParser)
RUN gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt-get update -y
RUN apt-get install -y mono-devel

# Requirements for DecoyPYrat
RUN apt-get -y install python-is-python3 python3-pip

# Requirements for Python
COPY ${BUILD_PATH}/python_requirements.txt /tmp/.
RUN pip install -r /tmp/python_requirements.txt


# Setting up the environment variables
ENV MSF_HOME "/opt/msfragger"
ENV RAWPARSER_HOME "/opt/thermorawfileparser"


#############
# MSFRAGGER #
#############

# Install MSFragger
COPY ${BUILD_PATH}/MSFragger-3.8.zip /tmp/.
RUN unzip /tmp/MSFragger-3.8.zip -d /opt/
# rename the files because we don't want versions in the name
RUN mv /opt/MSFragger-3.8 ${MSF_HOME}
RUN mv ${MSF_HOME}/MSFragger-3.8.jar ${MSF_HOME}/MSFragger.jar


###################
# THERMORAWPARSER #
###################

# Install ThermoRawFileParser
COPY ${BUILD_PATH}/ThermoRawFileParser1.4.2.zip /tmp/.
RUN unzip /tmp/ThermoRawFileParser1.4.2.zip -d ${RAWPARSER_HOME}


##############
# DECOYPYRAT #
##############

# Clone the CNIC dbscripts repository that contains the DecoyPYrat
RUN git clone https://github.com/CNIC-Proteomics/iSanXoT-dbscripts.git /opt/dbscripts


################
# MZ_EXTRACTOR #
################

# Clone the programa that extract the qauntifications
RUN git clone https://github.com/CNIC-Proteomics/mz_extractor.git /opt/mz_extractor



#
# REFRAG ----------
#
# %help
# ReCom rebuilt for MSFragger. Developed at the Cardiovascular Proteomics Lab / Proteomic Unit at CNIC (National Centre for Cardiovascular Research).
# 
# Requires:
# -i or --infile: Results file from MSFragger, in tab-separated text format.
# -r or --rawfile: MS Data file, in MGF or mzML format.
# -d or --dmfile: A theoretical DMs file, in tab-separated text format.
# -c or --config: A configuration file.
# 

ARG BUILD_PATH=refrag

# Update apt package
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y


# Install packages
RUN apt-get install -y vim
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git
RUN apt-get install -y unzip


################
# REQUIREMENTS #
################

# Requirements for ReFrag
RUN apt-get -y install python-is-python3 python3-pip

# Requirements for Python
COPY ${BUILD_PATH}/python_requirements.txt /tmp/.
RUN pip install -r /tmp/python_requirements.txt

# Setting up the environment variables
ENV REFRAG_HOME "/opt/refrag"


##########
# ReFrag #
##########

# Dowloand the tagged version
# RUN wget https://github.com/CNIC-Proteomics/ReFrag/archive/refs/tags/${REFRAG_VERSION}.zip
COPY ${BUILD_PATH}/ReFrag-0.4.0.zip /tmp/.
RUN unzip /tmp/ReFrag-0.4.0.zip -d /tmp/
RUN mv /tmp/ReFrag-0.4.0 ${REFRAG_HOME}

