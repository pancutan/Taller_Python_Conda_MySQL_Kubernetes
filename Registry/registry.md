# Registry con autenticación basica

## Opcion usar GCE

Ver ../Cursado.md

## Opcion usar Amazon, con ECR (EC2_Container_Registry)

### Pasos con Amazon

* Instalarse el aws CLI
  https://docs.aws.amazon.com/es_es/cli/latest/userguide/cli-chap-install.html#install-tool-venv
  Yo lo instalé en forma parecida, con conda, sin python 3.4 que conda ya no lo soporta:

```bash
conda create -n py35-para-aws python=3.5
conda activate py35-para-aws
pip install --upgrade pip
pip install awscli --upgrade --user
```

* Obtener un repo
  https://docs.aws.amazon.com/es_es/AmazonECR/latest/userguide/ECR_GetStarted.html

* Loguearse con aws ecr get-login, de acuerdo a
  https://us-west-2.console.aws.amazon.com/ecr/repositories?region=us-west-2

```bash
$(aws ecr get-login --no-include-email --region us-west-2)
```

* Probar de subir una imagen. Por ejemplo las definidas en este proyecto

  * Arrancamos los contenedores para saber a que images están conectados, con
    docker-compose up db
    docker-compose run programa

  * Buscamos que imagenes fueron instanciadas, con portainer y docker images

    CONTAINER ID   IMAGE                                  NAMES
    936a5ce737d1   pythonsimpleconcondaymysql_programa  pythonsimpleconcondaymysql_programa_run_1
    116339c28a80   mysql:5.7                            pythonsimpleconcondaymysql_db_1

    * Como se puede ver, la imagen de MySQL no me interesa subirla. Entonces taggeo la que contiene el programa. La primer vez uso la latest, pero podría pushear una "estable"

    docker tag pythonsimpleconcondaymysql_programa:latest 599651702009.dkr.ecr.us-west-2.amazonaws.com/inventario-repo:latest

    * Ahora si, pusheo la que está taggeada:
    docker push 599651702009.dkr.ecr.us-west-2.amazonaws.com/inventario-repo:latest

    * Otro ejemplo, para el caso de taggear y pushear al ejemplo on premise que viene enseguida:

    $ docker images
    REPOSITORY                                                 TAG                 IMAGE ID            CREATED             SIZE
    python-inventario-imagen  ← ESTE QUIERO                    0.1                 23c34bfe0d60        3 days ago          1.03GB
    gcr.io/api-project-430007987702/python-inventario-imagen   0.1                 23c34bfe0d60        3 days ago          1.03GB
    python                                                     3.6                 1bf411c4dc77        8 days ago          913MB

    $ docker tag 23c34bfe0d60 hub.supercanal.tv:5000/python-inventario-imagen

    $ docker images
    REPOSITORY                                                       TAG                 IMAGE ID            CREATED             SIZE
    python-inventario-imagen                                         0.1                 23c34bfe0d60        3 days ago          1.03GB
    gcr.io/api-project-430007987702/python-inventario-imagen         0.1                 23c34bfe0d60        3 days ago          1.03GB
    hub.supercanal.tv:5000/python-inventario-imagen ← SE AGREGO ESTA latest              23c34bfe0d60        3 days ago          1.03GB
    python                                                           3.6                 1bf411c4dc77        8 days ago          913MB

    $ docker push hub.supercanal.tv:5000/python-inventario-imagen
    Si sale error  "http: server gave HTTP response to HTTPS client", ver abajo en errores conocidos

## On premise, sin autenticación, con docker-compose, y posibilidad de borrar imagenes por linea de comandos

Dejo aquí en ~/Dropbox/Trucos/Docker/Registry/docker-registry todo lo necesario para levantar un registry sin autenticación, que permite borrar por linea de comandos las imagenes viejas.

Lo dejo todo corriendo en 5001 en lugarde 5000, porque me daba conflicto con un puerto 5000 usado por dockerd

Levantarlo con docker-compose up, ignorar la parte de ui, o investigarla

Fuente: https://stackoverflow.com/a/43786939

La parte de borrado de imagenes es como se describe a continuación. Antes, al no estar autenticado, requiere de poner en la maquina clienta, un archivo /etc/docker/daemon.json y adentro

```json
{
  "insecure-registries" : ["hub.supercanal.tv:5000"]
}
```

Ahora si, para borrar imagenes, obtengo name de lo que tengo arriba, primero, y luego los tags

```bash
$ curl http://hub.supercanal.tv:5000/v2/_catalog
{"repositories":["python-inventario-imagen"]}

$ curl http://hub.supercanal.tv:5000/v2/python-inventario-imagen/tags/list
{"name":"python-inventario-imagen","tags":["latest"]}
```

Ahora ya tengo name y tag. Con eso articulo esto para obtener el sha256

```bash
$ curl -v --silent -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X GET http://hub.supercanal.tv:5000/v2/python-inventario-imagen/manifests/latest 2>&1 | grep Docker-Content-Digest | awk '{print ($3)}'

sha256:de537a693a6452b7dfb565e2bc6bc99126cfa2d364d799e6c5952ebbc33f76d9

```

Lo marco para borrado

```bash
curl -v --silent -H "Accept: application/vnd.docker.distribution.manifest.v2+json" -X DELETE http://hub.supercanal.tv:5001/v2/python-inventario-imagen/manifests/sha256:de537a693a6452b7dfb565e2bc6bc99126cfa2d364d799e6c5952ebbc33f76d9
```

Me voy al servidor Webhosting 8, me meto adentro de la caja y purgo

```bash
docker exec -it registry-srv /bin/sh

/ # bin/registry garbage-collect  /etc/docker/registry/config.yml
```

## Registry con autenticación básica, on premise

### Desde el server

#### Opción 1, correr solo un contenedor registry. No sirve para cuando hay muchas replicas

> Correr todo esto desde el ~

1. Primero generamos un htpasswd:

```bash
mkdir auth

docker run \
--entrypoint htpasswd \
registry:2 -Bbn testuser testpassword > auth/htpasswd
```

2. Luego creamos el registry expongo el 5000

```bash
docker run -d \
-p 5000:5000 \
--restart=unless-stopped \
--name registry \
-v `pwd`/auth:/auth \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
-e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
-v /home/salonso/certs:/certs \
-e "REGISTRY_HTTP_TLS_CERTIFICATE=/certs/hub.supercanal.tv.crt" \
-e "REGISTRY_HTTP_TLS_KEY=/certs/hub.supercanal.tv.key" \
-e "REGISTRY_STORAGE_DELETE_ENABLED=true" \
registry:2
```

> El REGISTRY_STORAGE_DELETE_ENABLED=true es para poder borrar imagenes viejas como dice https://stackoverflow.com/a/43786939
> Copiar todo este bollo de texto de vim, de less, sin los trailing spaces, usando :!less ~/Dropbox/Trucos/Docker/registry.md

### Desde la estación, antes del primer push

docker login -u testuser -ptestpassword hub.supercanal.tv:5000

Ya se puede pushear. Antes taggear, como se mencionó recien.

```bash
docker service create --name registry --publish published=5000,target=5000 registry:2
```

### Opcion 2, crear un servicio con autenticacion

1. Primero creamos con openssl un .crt y un .key como sale en seguimos https://docs.docker.com/registry/insecure/#use-self-signed-certificates

2. Luego persistimos esos certificados en un almacen de secretos
   (Ver docker secret para mas comandos sobre este almacen)

```bash
docker secret create hub.supercanal.tv.crt /home/salonso/certs/hub.supercanal.tv.crt
docker secret create hub.supercanal.tv.key /home/salonso/certs/hub.supercanal.tv.key
```

3. Luego avisamos en cada host cual va a ser el que va a portar el registry
   Supongo que hayque activar uno por cada replica que vayamos a tener

```bash
docker node update --label-add registry=true webhosting8
```

4. Luego seguimos https://docs.docker.com/registry/deploying/#run-the-registry-as-a-service

```bash
docker service create \
--name registry \
--secret hub.supercanal.tv.crt \
--secret hub.supercanal.tv.key \
--constraint 'node.labels.registry==true' \
--mount type=bind,src=/mnt/registry,dst=/var/lib/registry \
-e REGISTRY_HTTP_ADDR=0.0.0.0:80 \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/run/secrets/hub.supercanal.tv.crt \
-e REGISTRY_HTTP_TLS_KEY=/run/secrets/hub.supercanal.tv.key \
-e REGISTRY_STORAGE_DELETE_ENABLED=true \
--publish published=80,target=80 \
--replicas 1 \
registry:2
```

5. Para examinar que es lo que tiene adentro

```bash
$ curl http://hub.supercanal.tv:5000/v2/_catalog

=> {"repositories":["biblioteca","biblioteca-base"]}

curl http://hub.supercanal.tv:5000/v2/python-inventario-imagen/tags/list
```

## Errores conocidos

* The push refers to repository [hub.supercanal.tv:5000/python-inventario-imagen]
  Get https://hub.supercanal.tv:5000/v2/: http: server gave HTTP response to HTTPS client

  En este caso hay que poner/crear, tanto en el server como en el Linux cliente, un archivo /etc/docker/daemon.json y adentro

```json
{
  "insecure-registries" : ["hub.supercanal.tv:5000"]
}
```

  Fuente: https://stackoverflow.com/questions/38695515/can-not-pull-push-images-after-update-docker-to-1-12

* error creating overlay mount to /var/lib/docker/overlay2/ [...] /merged: device or resource busy
  Insistir en el push varias veces

## Investigar: Registry con UI, útil para borrar el exceso de imagenes remotas

Aprovecharse de una UI entre aquellas existentes por Internet, es mas complejo de lo que parece. La gente de
Docker no lo facilita, para vender el servicio. Y otras soluciones se encuentran demasiado acopladas al tipo 
de solución que crearon sus desarrolladores para resover sus problemas especificos. Tambien hay demasiados forks.

Esta solución es la que me parece más adecuada: [Pelado Nerd](https://www.youtube.com/watch?v=stVspIUHP4Q)
