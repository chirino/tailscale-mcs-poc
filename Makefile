# Copyright (c) 2021 Tailscale Inc & AUTHORS All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

AUTH_KEY ?= tskey-...
IMAGE_TAG ?= chirino/tailscale-k8s:latest
SA_NAME ?= tailscale
KUBE_SECRET ?= tailscale
SERVICE ?= nginx

#
# build with docker buildx so we get a multi arch image that can run on amd64 and arm64 platforms.
#
setup-buildx:
	@docker buildx create --name mybuilder || true
	@docker buildx use mybuilder
build: setup-buildx
	@docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_TAG) .
push: setup-buildx
	@docker buildx build --platform linux/amd64,linux/arm64 -t $(IMAGE_TAG) --push .

server:
	kind delete clusters server || true
	kind create cluster --name server
	kubectl create deployment $(SERVICE) --image nginx || true
	kubectl expose deployment $(SERVICE) --port 80 || true
	# this should give the service enough time to get a clusterIP allocated..
	kubectl wait --timeout=300s --for=condition=available deployments nginx 
	cat server.yaml |\
		sed -e "s;{{AUTH_KEY}};$(AUTH_KEY);g" |\
		sed -e "s;{{KUBE_SECRET}};$(KUBE_SECRET);g" |\
		sed -e "s;{{SA_NAME}};$(SA_NAME);g" |\
		sed -e "s;{{IMAGE_TAG}};$(IMAGE_TAG);g" |\
		sed -e "s;{{SERVICE}};$(SERVICE);g" |\
	 kubectl apply --force -f-

client:
	kind delete clusters client || true
	kind create cluster --name client
	cat client.yaml |\
		sed -e "s;{{AUTH_KEY}};$(AUTH_KEY);g" |\
		sed -e "s;{{KUBE_SECRET}};$(KUBE_SECRET);g" |\
		sed -e "s;{{SA_NAME}};$(SA_NAME);g" |\
		sed -e "s;{{IMAGE_TAG}};$(IMAGE_TAG);g" |\
		sed -e "s;{{SERVICE}};$(SERVICE);g" |\
		sed -e "s;{{DEST_HOST}};server-gw;g" |\
	 kubectl apply --force -f-

cli:
	kubectl delete pod cli > /dev/null || true
	kubectl run -it cli --image=registry.access.redhat.com/ubi8 --restart=Never -- bash