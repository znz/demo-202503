# syntax=docker/dockerfile:1

FROM ubuntu:24.04

WORKDIR /r

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update -qq && apt-get --no-install-recommends install -y git ssh

RUN mkdir -p /run/sshd

RUN useradd git --create-home --shell /bin/bash
COPY id_git.pub /home/git/.ssh/authorized_keys

EXPOSE 22

CMD ["/sbin/sshd", "-D"]
