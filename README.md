# Firewall Funtions

## Overview

This folder contains the Azure Functions that are used to manage firewalls.  Each function searches the Subscription for all Azure Firewalls.

Functions reside in an Azure Function resource.  The resource is named "togglefw" for this document

### Allocation

This function toggles the allocation state of the the firewalls found.

```text
https://togglefw.azurewebsites.net/api/allocation?code=[default function key]
```

### Status

This function returns the status of the firewalls found.

```text
https://togglefw.azurewebsites.net/api/status?code=[default function key]
```

