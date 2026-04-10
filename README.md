# VLab

Is a personal experiment I created to learn more about virtualisation on masOS ARM64.

The vlab cli tool provides a utility that enables the serial start up and shutowm of VMs managed by Lima.

<p align="center">
  <img src="docs/demo/demo.gif" alt="VLab Orchestration Demo" width="800">
  <br>
</p>

## What Problem Is Being Solved

The core problem being solved is the ability to spin up and tear down a collection of VMs that are managed by Lima. I created this tool
as a light-weight convenience utility that allows me to bring up and down multiple VMs managed by Lima.

## Installer

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jcnnll/vlab/refs/heads/main/install.sh)"
```

**Note:** This script is used to install the dependencies as well as VLab to the machine. It will only run on macOS ARM64.

### 1. Environment Validation

Restricts the installation to macOS on ARM64 architecture.

### 2. Dependency Provisioning

The following dependencies are installed if missing:
- Xcode Command Line Tools
- Rosetta 2
- Lima
- socket_vmnet

### 3. System-Level Configuration

- Move socket_vmnet to a root protected path (/opt/socket_vmnet/)
- Enforce **root:wheel** ownership of socket_vmnet to satisfy Lima security requirements for privileged networking.
- Lima Rootless Execution (Sudoers)
  - Generate a dedicated sudoers config using `limactl sudoers`
  - Deploys to `/etc/sudoers.d/lima` with **440* permissions, allowing the VM network bridge to start without interactive password prompts.

### 4. VLab CLI Install

- Dynamically fetch the latest version of `vlab` package and checksums.
- Execute a shasum -a 256 check against the downloaded package before extraction to ensure file integrity.
- Extract and deploys the binary to `/usr/local/bin` 
- Set executable permissions.

## Usage

VLab acts as a sequential orchestrator to manage the lifecycle of your virtual infrastructure. 

To avoid resource exhaustion on the host, `vlab up` and `vlab down` processes nodes in a blocking loop based on a simple manifest.

## Lab Configuration (vlab.yaml)

Define your provisioning order in a flat list:

```bash
nodes:
  - dns
  - node-01
  - node-02
```

**Note:** the same naming convention used by Lima is applied to the vlab.yaml file. Only the file name is used to reference a VM instance.

### CLI Commands

`vlab up` processes the vlab.yaml sequence and executes limactl start for each node.
`vlab down` reverses the sequence to stop all nodes via limactl stop.
`vlab status` provides a unified view of the environment state via limactl list.

## Example Usage

As an example I created a single VM that is configured to run the DNS - this is an example of an experiment I ran to learn about DNS.
