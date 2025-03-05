# ov_deploy

Welcome to the `ov_deploy` module. This module automates the deployment of OpenVox primary servers, compilers and agents using Bolt plans. It sets up necessary repositories, installs required packages, and configures the environment for OpenVox-based infrastructure management.

## Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with ov_deploy](#setup)
    * [What ov_deploy affects](#what-ov_deploy-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with ov_deploy](#beginning-with-ov_deploy)
    * [Using Vagrant to get started](#using-vagrant-to-get-started)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The `ov_deploy` module provides an automated way to deploy and configure OpenVox servers. It installs required software, sets up OpenVox environments, and ensures proper configuration of OpenVox agents and servers. 

This module is useful for managing infrastructure at scale using OpenVox, ensuring consistency across multiple target machines.

## Setup

### What ov_deploy affects

The `ov_deploy` module modifies the following system components:

- Installs the OpenVox repository and GPG key.
- Installs the OpenVox server package (`openvox-server`).
- Installs and configures OpenVox and R10K for code deployment.
- Sets up Git, OpenVox agents, and compilers.
- Configures OpenVox server and agent settings.
- Manages OpenVox CA certificates and compiler configurations.

### Setup Requirements

- OpenVox Bolt must be installed on the system running this plan.
- Targets should be accessible over SSH with appropriate permissions.
- The system should support YUM-based package installation (RHEL-based distributions).
- OpenVox and R10K should be available for deployment.

### Beginning with ov_deploy

To use this module, execute the OpenVox Bolt plan with the required parameters:

```sh
bolt plan run ov_deploy::server --targets primary,compilers
```

This will deploy the OpenVox server and configure OpenVox infrastructure.

### Using Vagrant to get started

You can use Vagrant to quickly set up an OpenVox development environment. 

1. Install [Vagrant](https://www.vagrantup.com/downloads) and [VirtualBox](https://www.virtualbox.org/).
2. Place the provided `Vagrantfile` in your working directory.
3. Run the following command to start the virtual machine:

```sh
vagrant up
```

4. Deploy using Bolt:

```sh
bolt plan run ov_deploy::server --targets primary,compilers
```

This will setup a primary with compilers.

## Usage

The `ov_deploy` module can be used in different configurations based on your needs.

### Example Usage

```sh
bolt plan run ov_deploy::server \
  --targets primary,compilers \
  --gpg_key_url 'https://s3.osuosl.org/openvox-yum/GPG-KEY-openvox.pub' \
  --repo_url 'https://s3.osuosl.org/openvox-yum/openvox8-release-el-9.noarch.rpm' \
  --pkg_name 'openvox-server'
```

This will:
- Install the OpenVox repository.
- Install the `openvox-server` package.
- Configure OpenVox and R10K.
- Deploy OpenVox environments and set up OpenVox agents.

## Limitations

- Currently supports only RHEL-based distributions (EL 9 recommended).
- Requires an accessible Git repository for R10K configuration.
- Assumes network connectivity to fetch repositories and install dependencies.

## Development

Contributions to this module are welcome. Please follow these guidelines:

- Fork the repository and create a new feature branch.
- Follow OpenVox best practices for module development.
- Submit a pull request with a detailed explanation of changes.

For reporting issues or requesting new features, open an issue in the repository.

## Release Notes

- Initial release with Bolt-based deployment of OpenVox server.
- Implements R10K configuration and OpenVox server setup.
- Supports multi-target deployment including compilers.

---


