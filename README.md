# Overview
This is simple demo of exporting and importing a service accross private kind cluster using a Tailscale VPN network.  

## Instructions
### Setup
1. Create a following secret to automate tailscale login.<br>
   You will need to get an [auth key](https://tailscale.com/kb/1085/auth-keys/) from [Tailscale Admin Console](https://login.tailscale.com/admin/authkeys).<br>

   Edit the Makefile and set the AUTH_KEY variable.
   ```
   AUTH_KEY ?= tskey-...
   ```

   alternatively, you can export it in a AUTH_KEY env variable.

### Server Cluster
This exposes a nginx service via a gateway on the Tailscale network.

1. Create a server kind cluster with the deployments.

   ```bash
   make server
   ```

1. Verify that it's exported on the Tailscale network.

   ```bash
   curl http://server-gw
   ```

   Or, if you have [MagicDNS](https://tailscale.com/kb/1081/magicdns/) disabled:

   ```bash
   curl "http://$(tailscale ip -4 exporter)"
   ```

### Client Cluster
This cluster imports the service and makes it avaiable to be consumed
by deployments on the cluster.

1. Create a client kind cluster with the deployments.

   ```bash
   make client
   ```

1. Start a pod and attach a CLI to it:

   ```bash
   make cli
   ```

   In the shell it creates run:

   ```bash
   curl "http://$NGINX_SERVICE_HOST"
   ```

