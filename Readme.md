Here is the translation of the Markdown file to English:

# Docker image for IaC tool management

## Requirements

To build this image, it is necessary to have installed the following on your workstation:

1. packer =~ 1.9.2
2. python =~ 3.10.12
3. pipenv =~ 2023.6.18
4. taskfile =~ 3.28.0
5. docker =~ 24.0.5

## Installation of requirements

### Packer on Mac OS

It can be installed using [Mac Ports](https://www.macports.org/install.php) or [Brew](https://docs.brew.sh/Installation), or by directly downloading the binary from the [packer page](https://developer.hashicorp.com/packer/downloads) and copying it to the path `${HOME}/.local/bin` or any other application path within the user's ${PATH} environment variable.

**Mac Ports**

```shell
sudo port selfupdate && sudo port install packer
```

**Brew**

```shell
# First we add the Hashicorp repository in brew
brew tap hashicorp/tap

# Install packer
brew install hashicorp/tap/packer
```

### Packer on Linux

These instructions are for Debian or derivatives:

```shell
# Download the cryptographic key from the repository
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# We add the official Hshicorp repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# We update the package DB and install packer
sudo apt-get update && sudo apt-get install packer
```

> NOTE: It must be taken into consideration that these instructions are for the configuration of the repository in the 64 Bit x86 architecture.

### Pipev on Mac OS

**Mac Ports**

```shell
sudo port selfupdate && sudo port install pipenv
```

**Python on any platform**

```shell
pip3 install --user pipenv
```

### Taskfile on any platform

Follow the installation instructions for your platform on the [Taskfile page](https://taskfile.dev/installation/).

## Environment preparation

To build the image we must follow these steps:

1. Clone this repository to your workstation.
2. Go to the root of the repository and run the command `pipenv install`
3. Enter the Python virtual environment with `pipenv shell`

## Image building

Build the image with `task build`

## Development/Maintenance

To maintain or provision software in the image, the tools provided by Packer are used. If you want to test a role or playbook you must use the command `task build:debug`, this way if ansible fails, Packer will ask you what you want to do, you can [a]bort or [r]etry after making the corresponding corrections in the ansible role that fails.
