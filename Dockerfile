FROM ubuntu:bionic-20190612

LABEL maintainer="sameer@damagehead.com"

ENV MYSQL_USER=mysql \
    MYSQL_VERSION=5.7.28 \
    MYSQL_DATA_DIR=/var/lib/mysql \
    MYSQL_RUN_DIR=/run/mysqld \
    MYSQL_LOG_DIR=/var/log/mysql

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server=${MYSQL_VERSION}* \
 && rm -rf ${MYSQL_DATA_DIR} \
 && rm -rf /var/lib/apt/lists/*

# Use default answers for all setup prompts.
ARG DEBIAN_FRONTEND=noninteractive

# Add Ruby Version Manager (rvm) to PATH.
ENV PATH="/usr/local/rvm/bin/:$PATH"



# update
# update
RUN apt-get update -y

RUN apt-get -y install sudo

# create a new user called ubuntu
RUN groupadd ubuntu

RUN useradd ubuntu -d /home/ubuntu -ms /bin/bash -g ubuntu -G ubuntu

# Set ownership defaults.
RUN chown -R ubuntu:ubuntu /home/ubuntu

# grant ubuntu sudo rights
RUN adduser ubuntu sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# continue to install the rest of dependencies
RUN apt-get install -y curl

RUN apt-get install -y git

RUN apt-get -y install sudo

RUN apt-get -y install make

RUN apt-get -y install gcc

RUN apt-get -y install locales-all

RUN apt-get -y install dialog

# Install Node.js.
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs

# Populate environment variables that are required by Cloud9 Core.
RUN echo "export USER=ubuntu\n\
export C9_PROJECT=c9-offline\n\
export C9_USER=ubuntu\n\
export C9_HOSTNAME=\$IP\n\
export C9_PORT=\$PORT\n\
export IDE_OFFLINE=1\n\
alias c9=/var/c9sdk/bin/c9" >/etc/profile.d/offline.sh

USER ubuntu
# install c9

# Download Cloud9 Core into the Docker container.
WORKDIR /var
RUN sudo rm -rf c9sdk && \
    sudo mkdir c9sdk && \
    sudo chown ubuntu:ubuntu c9sdk && \
    git clone https://github.com/c9/core.git c9sdk

# Install Cloud9 Core within the Docker container.
WORKDIR c9sdk
RUN scripts/install-sdk.sh

RUN git checkout HEAD -- node_modules

RUN mkdir /home/ubuntu/workspace

# Set additional ownership defaults.
RUN sudo chown -R ubuntu:ubuntu /home/ubuntu/workspace/ && \
    sudo chown -R ubuntu:ubuntu /home/ubuntu/.c9/

# Have the Docker container listen to these ports at run time.
EXPOSE 5050 8080 8081 8082

USER root

COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod 755 /sbin/entrypoint.sh


# Run Cloud9 Core within the Docker container.
ENTRYPOINT ["npx", "concurrently", "/sbin/entrypoint.sh", "su - ubuntu  -c \"cd /var/c9sdk && node server.js -w /home/ubuntu/workspace --port 5050 --listen 0.0.0.0 --auth : \""]

CMD ["/usr/bin/mysqld_safe"]
