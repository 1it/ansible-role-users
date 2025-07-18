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
WORKDIR /ansible-role-users

# Copy role files
COPY . .

# Create proper Ansible role structure
RUN mkdir -p /ansible-role-users/tests/roles/users
RUN cp -r defaults /ansible-role-users/tests/roles/users/ 2>/dev/null || true
RUN cp -r tasks /ansible-role-users/tests/roles/users/ 2>/dev/null || true
RUN cp -r meta /ansible-role-users/tests/roles/users/ 2>/dev/null || true
RUN cp -r vars /ansible-role-users/tests/roles/users/ 2>/dev/null || true
RUN cp -r handlers /ansible-role-users/tests/roles/users/ 2>/dev/null || true
RUN cp -r files /ansible-role-users/tests/roles/users/ 2>/dev/null || true
RUN cp -r templates /ansible-role-users/tests/roles/users/ 2>/dev/null || true

# Set up SSH for testing
RUN mkdir -p /var/run/sshd
RUN echo 'root:testpassword' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Create inventory file for testing
RUN echo '[all]\nlocalhost ansible_connection=local' > /ansible-role-users/tests/inventory

# Expose SSH port
EXPOSE 22

# Default command
CMD ["/bin/bash"]