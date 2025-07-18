FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN pip3 install ansible ansible-core

# Install required Ansible collections
RUN ansible-galaxy collection install ansible.posix community.general

# Create working directory
WORKDIR /ansible

# Copy role files
COPY . .

# Create proper Ansible role structure
RUN mkdir -p /ansible/roles/users
RUN cp -r defaults /ansible/roles/users/ 
RUN cp -r tasks /ansible/roles/users/ 
RUN cp -r meta /ansible/roles/users/

# Set up SSH for testing
RUN mkdir -p /var/run/sshd
RUN echo 'root:testpassword' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Default command
CMD ["/bin/bash"]