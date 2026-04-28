FROM docker:dind

RUN apk add --update --no-cache python3 py3-pip && ln -sf python3 /usr/bin/python

RUN apk add sudo

RUN apk add --no-cache bash ansible

RUN addgroup -g 1000 ansible && \
    adduser -D -u 1000 -G ansible -s /bin/sh ansible && \
    echo "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /ansible