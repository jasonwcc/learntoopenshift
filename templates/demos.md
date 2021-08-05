## Example 1: 
	oc new-project e1-proj1
	oc new-app --name mysql --as-deployment-config \
	--docker.image docker.io/library/mysql:latest \
	-e MYSQL_USER=redhat \
	-e MYSQL_DATABASE=items \
	-e MYSQL_PASSWORD=redhat \
	-e MYSQL_ROOT_PASSWORD=redhat 

	oc get pods
	oc get dc
	oc get dc mysql -oyaml > mysql.yaml

	vi mysql.yaml
	# delete any namespace rows
	# delete any Time rows

	oc new-project e1-proj2
	oc create -f mysql.yaml

	oc get all


## Example 2: Use some of the predefined template by Openshift - A database server
	oc login
	oc project e3-proj1

	oc get template -n openshift

	oc get template mysql-ephemeral -n openshift

	oc new-app --template=mysql-ephemeral 

	oc get all

	oc logs mysql-<podname<

	oc rsh mysql-<podname>
	
	mysql -u<username-generated> -p<password genereated>


## Example 3: Use some of the predefined template by Openshift - A web server
	oc login
	oc project e4-proj1

	oc get template -n openshift

	oc get template -n openshift | grep -i apache

	oc new-app --template=httpd-example

	oc logs -f bc/httpd-example

	oc get route

	Open browser and point to httpd-example-e4-proj1.apps.ocp4.example.com


## Example 4: Access template from external
	oc login

	oc project e4-proj1

	oc create \
	-f https://raw.githubusercontent.com/openshift-evangelists/wordpress-quickstart/master/templates/classic-standalone.json

	oc get template wordpress-classic-standalone

	oc edit template wordpress-classic-standalone

	oc new-app --template=wordpress-classic-standalone

	oc get route

	open browser and point to <url>:8080

## Example 5: Process a template with parameters alterations
- Log into cluster and create new project
	oc login 
	oc project e5-proj1

- Find the desired template and download the yaml
	oc get template -n openshift | grep cakephp
	oc get template cakephp-mysql-example -oyaml > cake.yml
	grep kind cake.yml
	vi cake.yml

- Attempt to create resources based on the yaml
	oc create -f cake.yml
	NOTE: will get error

- Process the yml by setting some parameters 
``` bash
oc process -f cake.yml
oc process --parameters -f cake.yml
```
- Showing some of the important parameters

``` bash
oc process -f cake.yml \ 
-p NAME=dhl-app1 -p APPLICATION_DOMAIN=dhl-app1.apps.ocp4.example.com \
-p NAMESPACE=e5-proj1 -o yaml > processedcakephp.yml 

vi processedcakephp.yml
```	
- scrolls to cakephp-secret-token, cakephp-security.salt
- scrolls to kind: Route and notices those route name picks from your parameter

``` bash
oc create -f processedcakephp.yml
oc get all
```
- Once resources are created, lets attempt to build the app
``` bash
oc start-build dhl-app1
oc get all
oc get dc
oc describe dc/mysql
```

- Attempt to log into the mysql database
``` bash
oc ssh <podname>
```
mysql -udefault -pcakephp

- Find out the username and password in another terminal
``` bash
vi processedcakephp.yml
```
Look for MYSQL_PWD. There the password and user by default is cakephp
	
- Go back to the mysql command
``` bash
mysql -ucakephp -p"password from above"
show databases;
```

## Example 6 : Create a template using oc create
``` bash
oc create deployment hello \
     --image=quay.io/redhattraining/hello-world-nginx:v1.0 \
     --dry-run=client -o yaml > hello.yaml
oc status
```
Note: actually nothing happens above, just created the hello.yaml

- You may further review and modify the yaml definition
``` bash
vi hello.yaml
oc create --save-config -f hello.yaml
oc status
```

## Example 7 : Create template manually and deploy it
- Create the tododb deployment
``` bash
mkdir /mytemplates
vi /mytemplates/todo-db.yaml
appVersion: apps/v1
kind: Deployment
metadata:
    name: mysql
    labels: 
         app: todonodejs
         name: mysql
spec:
   replicas: 1
   selector:
      matchLabels:
           app: todonodejs
           name: mysql
   template:
      metadata:
           labels:
              app: todonodejs
              name: mysql
      spec:
        containers:
        - image: registry.access.redhat.com/rhscl/mysql-57-rhel7:5.7-47
          name: mysql
          env:
          - name: MYSQL_ROOT_PASSWORD
            value: r00tpa5
          - name: MYSQL_USER
            value: user1
          - name: MYSQL_PASSWORD
            value: mypa55
          - name: MYSQL_DATABASE
            value: items
          ports:
          - containerPort: 3306
            name: mysql
          volumeMounts:
          - mountPath: "/var/lib/mysql"
            name: db-volume
        volumes:
        - name: db-volume
          emptyDir: {}
        - name: db-init
          emptyDir: {}
...
appVersion: v1
kind: Service
metadata:
    name: mysql
    labels: 
         app: todonodejs
         name: mysql
spec:
   ports: 
   - port: 3306
   selector:
     name: mysql

oc create -f /mytemplates/todo-db.yaml
oc status
oc get pods
```

- Create SQL script file to create table and populate rows
``` bash
vi /mytemplates/db-data.sql
DROP TABLE IF EXISTS 'Item';
CREATE TABLE 'Item' ('id' BIGINT not null auto_increment primary key, 'description' varchar(100), 'done' BIT);
INSERT INTO 'Item' ('id', 'description', 'done') VALUES (1, 'Pick up newspaper', 0);
INSERT INTO 'Item' ('id', 'description', 'done') VALUES (1, 'Buy groceries', 1);

oc cp /mytemplates/db-data.sql mysql-<podname>:/tmp/
oc rsh mysql-<tab> bash
mysql -u root items < /tmp/db-data.sql
```

- Create the todo-frontend deployment
``` bash
vi /mytemplates/todo-frontend.yaml
appVersion: apps/v1
kind: Deployment
metadata:
    name: frontend
    labels: 
         app: todonodejs
         name: frontend
    namespace: network-sdn
spec:
   replicas: 1
   selector:
      matchLabels:
           app: todonodejs
           name: frontend
   template:
      metadata:
           labels:
              app: todonodejs
              name: frontend
      spec:
        containers:
        - resources:
               limits:
                  cpu: '0.5'
        - image: quay.io/redhattraining/todo-single:v1.0
          name: todonodejs
          env:
          - name: MYSQL_ENV_MYSQL_DATABASE
            value: items
          - name: MYSQL_ENV_MYSQL_USER
            value: user1
          - name: MYSQL_ENV_MYSQL_PASSWORD
            value: mypa55
          - name: APP_PORT
            value: '8080'
          ports:
          - containerPort: 8806
            name: nodejs-http
 ...
appVersion: v1
kind: Service
metadata:
    name: frontend
    labels: 
         app: todonodejs
         name: frontend
spec:
   ports: 
   - port: 8080
   selector:
     name: frontend

oc create -f /mytemplates/todo-frontend.yaml

oc get svc

oc expose svc/frontend --hostname todo.apps.ocp4.example.com
```

- Open up browser and point to todo.apps.ocp4.example.com/todo/


## Some codes explanations:
- the syntax available is not a full regular expression syntax. However, you can use�\w,�\d, and�\a�modifiers:

```
[\w]{10}�produces 10 alphabet characters, numbers, and underscores. This follows the PCRE standard and is equal to�[a-zA-Z0-9_]{10}.
[\d]{10}�produces 10 numbers. This is equal to�[0-9]{10}.
[\a]{10}�produces 10 alphabetical characters. This is equal to�[a-zA-Z]{10}.
```

