# VLab

Provides an unopionated platform to build virtual infrastructure labs on macOS ARM64 machines.

## What Problem Is Being Solved

The core problem being solved is the unnecessary complexity involved in building a native, high-performance virtual lab on Apple Silicon. Identifying the appropriate toolchain that will support a fully functional `virtual infrastructure lab` presents one of the main challenges and involves a significant amount of 'doc diving'.

A real lab requires native networking capability that enables transparent bi-directional connectivity between the host and guest machines. This is not supported out of the box with Lima and requires selecting the appropriate toolchain for provisioning the required network stack. Without a functional L2 bridge that allows nodes to talk to each other and the host as if they were on a physical switch, the environment is just a collection of isolated VMs rather than a true infrastructure lab.


## Required Dependencies

The installer requires [Homebrew](https://brew.sh/) to install Lima.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Installer

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jcnnll/vlab/refs/heads/main/install.sh)"
```

**Note:** This is what the script will execute on your machine.

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

As an example the foundational part of a fully functional virtual lab is included in the `example` lab in this repo. The lab includes a valid `vlab.yaml` file, the `dns.yaml` file that provisions a Lima VM instance as a DNS server and the `config-nameserver.sh` script that sets up macOS native conditional forwarding and establish the bi-directional network bridge between the host and guests.
