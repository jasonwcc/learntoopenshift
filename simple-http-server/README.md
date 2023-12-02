# Local build & push  [![Docker Repository on Quay](https://quay.io/repository/openshift-examples/simple-http-server/status "Docker Repository on Quay")](https://quay.io/repository/openshift-examples/simple-http-server)

```
sudo podman build --squash -t simple-http-server:latest .
sudo skopeo inspect containers-storage:localhost/simple-http-server:latest

sudo skopeo copy --authfile=/home/cloud-user/rbo-demo-demo-auth.json containers-storage:localhost/simple-http-server:latest docker://quay.io/rbo-demo/simple-http-server:latest
```




