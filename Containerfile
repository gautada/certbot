ARG ALPINE_VERSION=latest

# │ STAGE: CONTAINER
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――
FROM docker.io/gautada/alpine:$ALPINE_VERSION as CONTAINER

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/homepage-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"
LABEL description="A container for a homepage server"

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
ARG USER=coyote
# Set shell to /bin/ash and enable pipefail for Alpine-based images
SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN /usr/sbin/usermod -l $USER alpine \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER alpine \
 && /bin/echo "$USER:$USER" | /usr/sbin/chpasswd \

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
COPY container-version /usr/local/sbin/container-version

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY privileges /etc/container/privileges

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY entrypoint /etc/container/entrypoint

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
RUN /bin/sed -i 's|dl-cdn.alpinelinux.org/alpine/|mirror.math.princeton.edu/pub/alpinelinux/|g' /etc/apk/repositories
RUN /sbin/apk add --no-cache python3 
USER $USER
WORKDIR /home/$USER
RUN python -m venv .venv
COPY chatbot-client /home/$USER/.venv/bin/chatbot-client
COPY requirements.txt /home/$USER/requirements.txt
RUN . /home/$USER/.venv/bin/activate \
 && /home/$USER/.venv/bin/pip install --upgrade pip \
 && /home/$USER/.venv/bin/pip install -r /home/$USER/requirements.txt \
 && deactivate \
 && ln -fsv /home/$USER/.venv/bin/chatbot-client /usr/local/sbin/certonly \
 && ln -fsv /home/$USER/.venv/bin/chatbot-client /usr/local/sbin/renew
