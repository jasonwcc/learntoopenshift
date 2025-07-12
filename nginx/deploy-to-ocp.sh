oc create --save-config -f other-objets.yaml
oc create --save-config -f deployment.yaml
oc get pods -w
