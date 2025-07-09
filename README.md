# Code Structure

## Conceptual

The infra code is organized into several conceptual layers:

- Level 1: **Base** - Contains the foundational components that are used across the infrastructure such as PKI and IAM resources.

- Level 2: **Core** - Contains the core infrastructure components that are essential for the operation of the system, such as VPCs, subnets, Firewall and security groups.

- Level 3: **Services** - Contains the services that are built on top of the core infrastructure, such as Server, Database, and Message Queue.

- Level 4: **Applications** - Contains the applications that are built on top of the services, such as Web Application, API, and Mobile Application.
