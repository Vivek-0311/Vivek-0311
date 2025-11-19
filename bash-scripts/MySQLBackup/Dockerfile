FROM ubuntu:latest

# Install AWS CLI
RUN apt-get update && apt-get install -y net-tools netcat vim curl pigz tar zip unzip mysql-client

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc  --create-dirs  -o /opt/mc

RUN chmod +x /opt/mc
RUN mv /opt/mc /usr/local/bin/
RUN export PATH=$PATH:/usr/local/bin/


# Copy the dump script
COPY ./MySQLBackup /opt/MySQLBackup

#Sets the Working Directory
WORKDIR /opt/MySQLBackup

