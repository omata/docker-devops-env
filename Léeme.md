# Imagen de Docker para la gestión de herramientas de IaC

## Requerimientos

Para poder construir esta imagen, es necesario tener instalado los siguiente en nuestra estación de trabajo:

1. packer =~ 1.9.2
2. python =~ 3.10.12
3. pipenv =~ 2023.6.18
4. taskfile =~ 3.28.0
5. docker =~ 24.0.5

## Instalación de requerimientos

### Packer en Mac OS

Se puede instalar usando [Mac Ports](https://www.macports.org/install.php) o [Brew](https://docs.brew.sh/Installation), o bien descargando el binario directamente de la [página de packer](https://developer.hashicorp.com/packer/downloads) y copiándolo a la ruta `${HOME}/.local/bin` o cualquier otra ruta de aplicaciones dentro del ${PATH} del usuario.

**Mac Ports**

```shell
sudo port selfupdate && sudo port install packer
```

**Brew**

```shell
# Primero agregamos el repositorio de Hashicorp en brew
brew tap hashicorp/tap

# Procedemos a instalar packer
brew install hashicorp/tap/packer
```

### Packer en Linux

Estas instrucciones son para Debian o derivados:

```shell
# Descargamos la llave criptográfica del repositorio
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Agregamos el repositorio oficial del Hshicorp
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Actualizamos la BD de paquetes e instalamos packer
sudo apt-get update && sudo apt-get install packer
```

> NOTA: Hay que tener en consideración que estas instrucciones son para la configuración del repositorio en la arquitectura x86 de 64 Bits.

### Pipev en Mac OS

**Mac Ports**

```shell
sudo port selfupdate && sudo port install pipenv
```

**Python en cualquier plataforma**

```shell
pip3 install --user pipenv
```

### Taskfile en cualquier plataforma

Seguir las instrucciones de instalación para su plataforma en la [página de Taskfile](https://taskfile.dev/installation/).

## Preparación del entorno

Para construir la imagen debemos seguir los siguientes pasos:

1. Clonar este repositorio en su estación de trabajo.
2. Entrar en la raíz del repositorio y ejecutar el comando `pipenv install`
3. Entrar al entorno virtual de Python con `pipenv shell`

## Construcción de la imagen

Construir la imagen con `task build`

## Desarrollo/Mantenimiento

Para mantener o aprovisionar software en la imagen, se usan las herramientas provistas por Packer. Si se quiere probar un role o playbook debemos utilizar el comando `task build:debug`, de esta manera si ansible falla, Packer nos preguntará qué queremos hacer, podemos [a]bortar o [r]eintentar luego de hacer las correcciones correspondientes en el rol de ansible que falla.
