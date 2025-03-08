ARG ALPINE_VERSION=latest

# │ STAGE: CONTAINER
# ╰――――――――――――――――――――――――――――――――――――――――――――――――――――――
FROM docker.io/gautada/alpine:$ALPINE_VERSION as _container

# ╭――――――――――――――――――――╮
# │ VERSION            │
# ╰――――――――――――――――――――╯
ARG IMAGE_VERSION="3.2.0"

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL org.opencontainers.image.title="certbot"
LABEL org.opencontainers.image.description="An opinionated implementation of ACME Certbot."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/certbot"
LABEL org.opencontainers.image.source="https://github.com/gautada/certbot"
LABEL org.opencontainers.image.version="${IMAGE_VERSION}"
LABEL org.opencontainers.image.license="Upstream"

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
# │ PRIVILEGES         │
# ╰――――――――――――――――――――╯
COPY privileges /etc/container/privileges

# ╭――――――――――――――――――――╮
# │ ENTRYPOINT         │
# ╰――――――――――――――――――――╯
COPY entrypoint /etc/container/entrypoint

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯
RUN /bin/sed -i 's|dl-cdn.alpinelinux.org/alpine/|mirror.math.princeton.edu/pub/alpinelinux/|g' /etc/apk/repositories \
 && /sbin/apk add --no-cache python3 kubectl 

USER $USER
WORKDIR /home/$USER
RUN python -m venv .venv
COPY certbot-client.sh /home/$USER/.venv/bin/certbot-client
COPY update-cluster.sh /home/$USER/.venv/bin/update-cluster
COPY requirements.txt /home/$USER/requirements.txt
COPY cloudflare.py /home/$USER/.venv/bin/cloudflare

RUN . /home/$USER/.venv/bin/activate \
 && /home/$USER/.venv/bin/pip install --upgrade pip \
 && /home/$USER/.venv/bin/pip install -r /home/$USER/requirements.txt \
 && /bin/mkdir /home/$USER/.kube \
 && /bin/ln -fsv /mnt/volumes/configmaps/kube.conf /home/$USER/.kube/config \
 && /bin/ln -fsv /mnt/volumes/container/vault /home/$USER/vault \
 && deactivate 
USER root
RUN /bin/ln -fsv /home/$USER/.venv/bin/certbot-client /usr/bin/certonly \
 && /bin/ln -fsv /home/$USER/.venv/bin/certbot-client /usr/bin/renew

# COPY test.sh /usr/bin/test
#  RUN ln -fsv /usr/bin/test /etc/periodic/15min/test


USER $USER