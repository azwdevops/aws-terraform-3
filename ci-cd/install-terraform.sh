#!/bin/bash

# fail on any error

set -eu

# install yum-config-manager to manage your repositories
sudo yum install -y yum-utils

# use yum-config-manager to add the official Hashicopr linux repository

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# install terraform

sudo yum -y install terraform

# verify terraform in installed

terraform --version

