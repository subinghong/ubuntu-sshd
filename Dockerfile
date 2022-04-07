FROM       ubuntu:18.04
#MAINTAINER subinghong

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    TAILSCALE_KEY=${TAILSCALE_KEY} \
    TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME}

RUN apt-get update
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd

RUN echo 'root:root_password' |chpasswd
#RUN useradd -m alpine  && echo "alpine:atthemine" | /usr/sbin/chpasswd  && adduser alpine sudo
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN mkdir /root/.ssh

#install tailscale
RUN apt-get install -y curl gnupg gnupg2 gnupg1
RUN curl https://pkgs.tailscale.com/stable/ubuntu/bionic.gpg | apt-key add -
RUN curl https://pkgs.tailscale.com/stable/ubuntu/bionic.list | tee /etc/apt/sources.list.d/tailscale.list
RUN apt-get update
RUN apt-get install -y tailscale

RUN rm -rf /tmp/tailscaled
RUN mkdir -p /tmp/tailscaled
RUN rm -rf /var/run/tailscale
RUN mkdir -p /var/run/tailscale

RUN echo "#!/bin/bash" > start.sh
RUN echo "nohup tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --socket=/var/run/tailscale/tailscaled.sock --port 41641 &" >> /start.sh
RUN echo "tailscale up --auth-key=\${TAILSCALE_KEY} --hostname=\${TAILSCALE_HOSTNAME}" >> start.sh
RUN echo "/usr/sbin/sshd -D" >> start.sh
RUN chmod +x /start.sh


RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 22

ENTRYPOINT [ "/start.sh" ]
