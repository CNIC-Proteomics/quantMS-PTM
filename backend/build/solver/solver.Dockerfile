#
# SOLVER ---------------------------------------------------------------------------------------------
#
# %help
# SOLVER description...
# 


# our base image
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive

# Install main packages
RUN apt-get update -y
RUN apt-get install -y vim
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git
RUN apt-get install -y unzip

# Declare local variables
ARG LOCAL_DIR=""
ARG INSTALLATION_HOME=/opt/ptm-compass
RUN mkdir -p "${INSTALLATION_HOME}"


################
# REQUIREMENTS #
################

# Install Python packages
RUN apt-get -y install python-is-python3 python3-pip python3-venv
RUN python -m pip install --upgrade pip


#################
# ENV VARIABLES #
#################

# Setting up the environment variables
ENV SRC_HOME ${INSTALLATION_HOME}/solver


################
# INSTALLATION #
################

# Dowloand the tagged version
# RUN wget https://github.com/CNIC-Proteomics/SHIFTS-4/archive/refs/tags/v0.4.1.zip
# # Clone the SHIFTS repository
# RUN git clone https://github.com/CNIC-Proteomics/Solvers-PTMap.git ${SRC_HOME}
# RUN git clone https://github.com/CristinaDevesaA/TFM.git ${SRC_HOME}
COPY ${LOCAL_DIR}Solvers-PTMap ${SRC_HOME}


###############
# PYTHON VENV #
###############

# Change working directory
WORKDIR ${SRC_HOME}

# Create venv
RUN python -m venv env

# Requirements for Python
COPY ${LOCAL_DIR}python_requirements.txt /tmp/.
RUN /bin/sh env/bin/activate && pip install -r /tmp/python_requirements.txt