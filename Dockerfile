FROM       ubuntu:18.04
MAINTAINER Aleksandar Diklic "https://github.com/rastasheep"

RUN apt-get update

RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd

RUN echo 'root:atthemine' |chpasswd

RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

RUN useradd -m alpine \
&& echo "alpine:atthemine" | /usr/sbin/chpasswd \
&& adduser alpine sudo



RUN apt-get install -y curl gnupg gnupg2 gnupg1
RUN curl https://pkgs.tailscale.com/stable/ubuntu/bionic.gpg | apt-key add -
RUN curl https://pkgs.tailscale.com/stable/ubuntu/bionic.list | tee /etc/apt/sources.list.d/tailscale.list
RUN apt-get update
RUN apt-get install tailscale

RUN rm -rf /tmp/tailscaled
RUN mkdir -p /tmp/tailscaled
RUN chown irc.irc /tmp/tailscaled
RUN rm -rf /var/run/tailscale
RUN mkdir -p /var/run/tailscale
RUN chown irc.irc /var/run/tailscale
RUN cp /var/lib/tailscaled/tailscaled.state /tmp/tailscaled/tailscaled.state
RUN chown irc.irc /tmp/tailscaled/tailscaled.state
RUN echo "nohup sudo -u irc tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --state=/tmp/tailscaled/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock --port 41641 &" > start.sh
RUN echo "until tailscale up; do sleep 1; done" > start.sh
RUN echo "/usr/sbin/sshd -D" >> start.sh
RUN chmod +x start.sh


RUN mkdir /root/.ssh

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 22

ENTRYPOINT [ "start.sh" ]

