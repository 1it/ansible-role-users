FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openssh-client \
    python3 \
    python3-apt \
    python3-pip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages ansible-core

RUN ansible-galaxy collection install ansible.posix

WORKDIR /ansible

COPY . .

RUN mkdir -p /ansible/roles/users \
    && cp -r defaults vars tasks templates meta /ansible/roles/users/

CMD ["/bin/bash"]
