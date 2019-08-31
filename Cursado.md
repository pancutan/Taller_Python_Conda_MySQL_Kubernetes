# Curso Python, Django, Docker, Kubernetes

> (2019) Copyleft Sergio A. Alonso
> Estudiante: Enrique Ramirez - 20 de julio de 2019
> Portainer del aula disponible, entrando a http://201.190.246.214:9000

## Objetivos

* Acostumbrarse al ciclo de integración continua que propone Docker y Kubernetes
* Obtener soltura en Linux, MySQL y Python
* Portar fácilmente aplicaciones hacia la nube.

![Ciclo de trabajo Docker segun Microsoft](inner-workflow.png)

## Introducción

### Entorno de trabajo

Los DevOps trabajan la mayor parte del tiempo en la terminal. Por lo tanto conviene setear ésta acordemente.

### Manejador de sesiones en consola

Conviene instalar con apt-get, yum, pacman, etc cualquiera de estos paquetes, y aprender a usarlos en sus páginas oficiales: Screen, Tmux o Byobu

#### Shell

Se propone por su similitud con Mac y por sus funciones avanzados de instrospección de comandos, al shell Zsh por sobre el clásico Bash que viene por defecto con Linux. Instrucciones generales para setear una maquina con Ubuntu:

```bash
sudo apt-get install zsh git rake curl
```

Cambiar "para siempre" de Bash a Zsh

```bash
 $ chsh
Contraseña:
Cambiando la consola de acceso para usuario
Introduzca el nuevo valor, o presione INTRO para el predeterminado
Consola de acceso [/bin/bash]: /usr/bin/zsh
```

Todavía hace falta "enchular" a Zsh. Le bajamos el instalador del proyecto

```bash
sh -c "$(wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```

Una vez instalado conviene ademas agregar algún tema como Powerlevel 10k

```bash
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
```

Ahora sí, alteramos las siguientes variables de ~/.zshrc

```bash
plugins=(git nvm node kubectl django python pip docker docker-compose)

ZSH_THEME="powerlevel10k/powerlevel10k"
```

Para probar los cambios, salimos de la sesión con exit y volvemos a entrar.

#### Vim como IDE

Si bien todos los Linux incluyen Vi, se recomienda instalar el último vim posible. La m de "vim" mnemotecnicamente la vamos a considerar para "mejorado".

```bash
sudo apt-get install vim
```

Se puede "enchular" también a Vim, agregando el paquete [Janus](https://github.com/carlhuda/janus):

```bash
curl -L https://bit.ly/janus-bootstrap | bash
```

Conviene ademas definir una Leader Key. En ~/.vimrc agregar

```bash
let mapleader = ","
```

La Leader key sirve para lanzar ciertas funciones, como el explorador de archivos "Nerd Tree", con , (coma) seguida de n. Puede ver una lista de teclas interesantes en
[Taza Vim](http://www.eim.esc.edu.ar/bunker.org.ar/incubadora.varios/TazaVimSoloJpeg/TazaVim11.jpg)

## 1. Codificar una primer versión estable del proyecto

Crearemos un pequeño programa en Python que consulta una base de datos MySQL llamada "inventario". El propósito es mostrar como a pesar de funcionar bien, es sumamente incómoda de portar a otros sistemas operativos. Docker por supuesto, vendrá luego a salvarnos.

### 1.1. MySQL

[Instalar MySql en Ubuntu 18:](https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04)
Resumen de comandos:

```bash
sudo apt-get install mysql-server
sudo mysql_secure_installation
```

En su primera sesión con MySQL, fabrique una base de datos, y asigne permisos para su uso:

```bash
$ mysql -u root -p
mysql> CREATE DATABASE inventario;
mysql> GRANT ALL PRIVILEGES ON inventario.* TO 'inventario_user'@'localhost' IDENTIFIED BY 'MiViejaMula' WITH GRANT OPTION;
mysql> FLUSH PRIVILEGES;
mysql> exit;
```

Inyecte ahora el archivo inventario.sql en su nueva base

```bash
mysql -u root -p inventario < inventario.sql
```

Pruebe que puede entrar a su nueva base, con el usuario creado a tal fin:

```bash
mysql -u inventario_user -p inventario
mysql> SELECT * FROM amigos;
```

### 1.2. Instalar Python (y Django) con Conda

Si bien Python ya viene instalado en todos los sistemas operativos Linux y Mac, éste se reserva para el uso del propio sistema operativo, y particularmente para ser usado por el root. Tampoco conviene llenar el sistema operativo con librerías cruzadas entre Python 2 y Python 3.
En su lugar conviene instalar un manejador de entornos o "VirtualEnv". El problema entonces es que tanto Windows, como Mac como Linux tienen formas distintas de acometer este paso. La mejor manera unificada de acometerlo es empleando una versión simple de Anaconda, llamada miniconda.

Sírvase acceder al excelente material documentativo creado en este sitio. No hace falta instalar todavía Django: basta con la parte de Python: [Instalar Python y Django](https://hcosta.github.io/instalardjango.com/). Resúmen de comandos:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
chmod u+x Miniconda3-latest-Linux-x86_64.sh
```

Mi única observación al respecto es que el instalador de Miniconda *no toma en cuenta* que estamos usando Zsh. Por tanto debemos setear nosotros mismos al final de ~/.zshrc las mismas y últimas líneas que fueron agregadas a ~/.bashrc - **no copie estas líneas**: saque las originales del ~/.bashrc

```bash
__conda_setup="$('/home/eramirez/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/eramirez/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/eramirez/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/eramirez/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
```

Tras estar seguros que estas líneas figuran al final ~/.zshrc y en ~/.bashrc, salimos de la terminal con exit, o reiniciamos el equipo, y volvemos a entrar. Tras lo cual, el comando "conda" debería respondernos, para por ejemplo, setear un primer entorno virtual:

```bash
python -V (para ver la versión de Python del sistema operativo que "no" queremos usar)

which python (para ver la ruta que no queremos usar, ejemplo, /usr/bin/python2.7)

conda create -n py36 python=3.6

conda info -e

conda activate py36

python -V (Python ahora debería sestar compilado por Anaconda Inc.)

which python (la ruta debería apuntar ahora a nuestro propio home)
```

### 1.3. Instalar las librerías necesarias para que Python trabaje con MySQL

Retomamos proyecto. Se incluye a modo de ejemplo un archivo requirements.txt para pip

```bash
conda activate py36
pip install -r requirements.txt
```

### 1.4. Probar el programa

El modo debug -m pudb es optativo, solo para tener un mejor control del programa.

```bash
python -m pudb inventario.py
```

## 2. Portar el programa a Docker

Se puede hacer

* Con un docker build, y adaptando / comiteando las imágenes de cada servicio necesario: python, mysql, redis, etc
  Se hace adaptando archivos Dockerfile que pueden obtenerse en Dockerhub.
* Con un archivo docker-compose.yml, útil para enlazar varios imagenes ya hechas, o llamando a los Dockerfile necesarios,
  Eventualmente el comando docker-compose termina orquestando todo el proyecto local, puesto que puede enlazar a varios
  contenedores a traves de su propia capa de red.

Secuencia de ejemplo para portar un programa en Python

* Entrar a [Proyecto Python en DockerHub](https://hub.docker.com/_/python/) y escojer algun tag que coincida con la versión
  de Python empleada en nuestro programa.
* Buscar el Dockerfile y adaptarlo a nuestra necesidades. Dejo un Dockerfile de ejemplo en esta carpeta.
* Crear (build) la imagen local y correrla. El -f es a propósito para poder tener varios Dockerfile en la misma carpeta.

```bash
docker build -t python-inventario-imagen:0.1 . -f Dockerfile.python-simple

docker run --rm --name python-inventario-instancia imagen-python-inventario:0.1
```

## 3. Portar a Docker tambien los servicios dependientes

En este momento el contenedor con el programa en Python "sale" a conectarse a una base de datos. Por razones pedagógicas y para ilustrar la portabilidad del conjunto, portaremos también a MySQL.
Sin embargo, hay que comentar el hecho que la alta carga de las bases de datos requiere a veces de que éstas no estén contenidas y ni siquiera virtualizadas. Tal tambien es la razón por la cual muchas veces se porta una capa intermedia de datos en el contenedor, del tipo que corren en RAM, como Redis, que no necesitan de bajar a disco todo el tiempo.

Tambien en este punto conviene habituarse a lanzar y a administrar el proyector con el comando docker-compose en lugar del comando docker. Esto es porque ambos servicios se encuentran enlazados.

## 4. Pushear a un Registry

La necesidad de este paso previo a Kubernetes consiste en que kompose no se dedica a hacer builds, como lo hace Swarm. La opción "build" en el docker-compose.yml
fallará cuando queramos hacer el transpile a los manifests de Kubernetes. En estos descriptores de Kubernetes debemos proveerle en su lugar las imagenes. Y para ello
debemos subirlas a un Registry. Implementaciones aquí, en Registry/registry.md - y resumen aquí:

* Crear un Registry en la infraestructura instalada. Se hace siguiendo cuidadosamente las instrucciones de
  https://docs.docker.com/registry/

* Usar un cloud
  * Caso Amazon ECR (Elastic Ccontainer Registry)
    Datos:

    * Nota: creado un repositorio de prueba en 599651702009.dkr.ecr.us-west-2.amazonaws.com/inventario-repo

  * Caso GCR (Google Container Registry):
    * Cargar una imagen siguiendo este enlace
      https://cloud.google.com/container-registry/docs/pushing-and-pulling?hl=es_419#pushing_an_image_to_a_registry
      Esencialmente, se trata de
      * Revisar entre nuestras imagenes ya generadas
      * Taggear aquella que nos interesa (también) como una imagen para GCE. Hay que tener a mano el nombre del proyecto.
        En este ejemplo: api-project-430007987702

```bash
docker images
docker tag python-inventario-imagen:0.1 gcr.io/api-project-430007987702/python-inventario-imagen:0.1
```

  * Generar credenciales mediante la utilidad gcloud para poder subir al Registry de GCE.
    * En el caso de Archlinux, la utilidad se obtiene con el comando yay google-cloud-sdk
    * En otros sistemas operativos se usa brew, snap o equivalente

```bash
gcloud auth configure-docker
gcloud auth login
gcloud config set project api-project-430007987702
docker push gcr.io/api-project-430007987702/python-inventario-imagen:0.1
```

    * Comprobar que se ha cargado correctamente la imagen, en https://console.cloud.google.com/gcr

### 5. Subir el código a GIT

Opciones durante el cursado:

* Git en cloud: Github, Gitlab
* Git en infraestructura propia: servidor git simple o servidor gitlab instalado local

Pasos de ejemplo con Github

* Crear cuenta en Github
* Generar llaves, tanto de la maquina de desarrollo, como de la consola de GCE

```bash
ssh-keygen -t rsa -f ~/.ssh/id_rsa -N '' (no poner contraseña: que se genere sola)
cat ~/.ssh/id_rsa.pub
```

Estas llaves, ambas subirlas a https://github.com/settings/keys

* Solo necesario en Github: hacerse un fork de este proyecto https//www.github.com/pancutan/1-Taller_Python_Conda_MySQL_Kubernetes
* En una carpeta vacía, clonar proyecto. Si se trata de Gitlab, el profesor solo debe invitar a los alumnos y éstos van por la url original. Es decir:
  * Con Github: git clone git@github.com:USUARIO_ALUMNO/1-Taller_Python_Conda_MySQL_Kubernetes.git
  * Con Gitlab (ejemplo): git clone git@gitlab.com:pancutan/1-Taller_Python_Conda_MySQL_Kubernetes.git

Poner allí adentro las modificaciones de código, comitear, pushear, realizar pull request si en los apuntes del profesor algo debiera corregirse.

## 6. Desplegar en Kubernetes

Consideraciones:

* La empresa que provee Docker, tiene en realidad su propio orquestador, llamado Swarm, que se gestiona sobre el mismo docker-compose.yml
* Kubernetes por su parte, requiere de hacer un transpiling del docker-compose.yml, mediante kompose.

TODO: revisar acotaciones de Pablo Fredikson - https://www.youtube.com/watch?v=q-ZicDSb3Cc&t=1s

Opciones de cursado. Despliegue sobre:

### 6.1. Equipo personal: Ej: Minikube / VIrtualBox

### 6.2. VPS / VM  en Vcenter / KVM en Proxmox, etc, con Kubeadm

### 6.3. PaaS: Heroku, EBS

### 6.4. IaaS: AWS, GCE, Azure, Digital Ocean, etc

#### 6.4.1. Ejemplo caso GCE

* Crear un proyecto Kubernetes en GCE, con tres instancias micro
* Enviar llaves, si no se ha hecho todavía, de la consola de GCE a Github
* Clonar proyecto como ya se ha aprendido
* Bajar kompose como se explica en kompose.io, mediante curl, wget, etc
* Dejar disponible kompose en /usr/bin

```bash
sudo mv kompose /usr/bin/
```

* Realizar en transpile del docker-compose.yml a varios archivos .yaml de Kubernetes
  Este paso requiere tener el docker-compose.yml aparte. La razón se encuentra en que las siguientes líneas refieren a ejecutar un build

```yml
    build:
      context: .
      dockerfile: Dockerfile.python-simple
```

En tanto que Kubernetes requiere de imagenes ya listas para desplegar. La líneas anteriores deben ser comentadas y en su lugar, poner la referencia al registry de imagenes

```bash
    image: gcr.io/api-project-430007987702/python-inventario-imagen:0.1
```

Ahora sí estamos en condiciones de hacer el transpiler con kompose create seguido de kompose create -f a cada uno de los archivos generados, o simplemente kompose up

```bash
escuelaint@cloudshell:~/1-Taller_Python_Conda_MySQL_Kubernetes/conversion-a-kubernetes (api-project-430007987702)$ kompose up

INFO We are going to create Kubernetes Deployments, Services and PersistentVolumeClaims for your Dockerized application. If you need different kind of resources, use the 'kompose convert' and 'kubectl create -f' commands instead.

INFO Deploying application in "default" namespace
INFO Successfully created Service: db
INFO Successfully created Deployment: db
INFO Successfully created PersistentVolumeClaim: db-data of size 100Mi. If your cluster has dynamic storage provisioning, you don't have to do anything. Otherwise you have to create PersistentVolume to make PVC work
INFO Successfully created Deployment: programa
INFO Successfully created PersistentVolumeClaim: programa-claim0 of size 100Mi. If your cluster has dynamic storage provisioning, you don't have to do anything. Otherwise you have to create PersistentVolume to make PVC work
```

Tal como dice, "su aplicación ha sido desplegada". Se puede monitorear ahora con comandos kubectl

```bash
escuelaint@cloudshell:~/1-Taller_Python_Conda_MySQL_Kubernetes/conversion-a-kubernetes (api-project-430007987702)$ kubectl get deployment,svc,pods,pvc
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/db          0/1     1            0           42s
deployment.extensions/hello-app   0/1     1            0           15d
deployment.extensions/programa    0/1     1            0           42s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/db           ClusterIP   10.56.3.30   <none>        3307/TCP   42s
service/kubernetes   ClusterIP   10.56.0.1    <none>        443/TCP    15d

NAME                            READY   STATUS              RESTARTS   AGE
pod/db-7d4cf4747b-f9xf8         0/1     ContainerCreating   0          42s
pod/hello-app-576fcf7d5-vmj7s   0/1     ImagePullBackOff    0          15d
pod/programa-55f878c7-lv5jv     0/1     ContainerCreating   0          42s

NAME                                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/db-data           Bound    pvc-d02524f6-b6dd-11e9-a798-42010a800016   1Gi        RWO            standard       43s
persistentvolumeclaim/programa-claim0   Bound    pvc-d0425381-b6dd-11e9-a798-42010a800016   1Gi        RWO            standard       43s
```

De acuerdo a la columna STATUS y a comandos tales como kubectl logs, es posible que debamos "afinar" nuestro docker-compose.yml (o los archivos generados con kompose convert)
y reiniciar nuestros pods mediante kompose down / kompose up

## 7. Automatización de despliegues

Configurar Integración Continua - propuesta: Jenkins

El propósito de esta sección es ilustrar la forma en que un programa de integración continua realiza los "Build". Algunos de estos pasos pueden ser:

* "Tirar" del repositorio todos los archivos del proyecto
* Configurarlo para produccion, para QA, para aceptación, etc, si hace falta
* Realizar el build -t, pushear la imagen nuevamente, con un nuevo tag
* Meterse a los nodos, desplegar con docker run
* Ir apartando nodos y desconectandolos del load balancer mientras trabaja
