#!/bin/sh
/usr/bin/kubectl delete \
 --namespace ingress secret/tls-certs
 
/usr/bin/kubectl create secret tls \
 --namespace ingress tls-certs \
 --cert="${HOME}/vault/config/live/gautier.org/fullchain.pem" \
 --key="${HOME}/vault/config/live/gautier.org/privkey.pem"

/usr/bin/kubectl rollout restart \
 --namespace ingress \
 daemonset/nginx-ingress-microk8s-controller