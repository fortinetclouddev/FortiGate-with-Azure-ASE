# FortiGate-with-Azure-ASE
How to provide inspection and filtering (and compliance) for Azure App Service Environments (ASE)

The broad steps involved to build an ASE environment with FortiGate inspection are as follows:

#### 1.	Deploy FortiGate Single VM or HA (via marketplace or more specialized template).
### 2.	Deploy ASE to a unique subnet in the same VNET or a peered VNET.
### 3.	Optionally, deploy a ‘jumpbox’ VM for ASE management
### 4.	Deploy/configure Web App in ASE
### 5.	Create a dedicated UDR for the ASE Subnet.  This UDR can have local routes to other subnets and VNETs, a default route, custom routes for ExpressRoute or Azure VPN connected networks.  Each of these routes can optionally be configured with the FortiGate(s) as the next hop.  A default route with the FortiGate(s) as next hop is recommended.  However, there are certain Azure management IPs which must not be redirected.  Hosts from these IPs will communicate directly for ASE management purposes.  It is possible to retrieve the specific list used by your ASE via Azure API calls.  The included powershell file (ASE-UDR-Update.ps1) is designed to automatically modify an existing route table with the current list of management IPs.  Alternatively, a list of these IPs and another powershell script for automating an Azure route table are available here: https://docs.microsoft.com/en-us/azure/app-service/environment/management-addresses#get-your-management-addresses-from-api
### 6.	Configure the FortiGate to allow additional outbound access for dataplane communication from the ASE.  FortiGate has an ISDB which is dynamically updated.  You can allow outbound communication using the Microsoft-Azure category.  Here’s an example policy:

    edit 4
        set name "Allow ASE Out"
        set srcintf "port2"
        set dstintf "port1"
        set srcaddr "ASE Subnet"
        set internet-service enable
        set internet-service-id 327786
        set action accept
        set schedule "always"
        set utm-status enable
        set ssl-ssh-profile "certificate-inspection"
        set ips-sensor "default"
        set application-list "default"
        set fsso disable
        set nat enable
    next


### 7.	  Configure FortiGate DNAT/Virtual IP to forward inbound traffic (if public access to Web app is required) to the load balancer IP of the ASE.  Optionally, you can use both FortiWeb and FortiGate.  If using both, at this step you would instead forward to FortiWeb and then configure FortiWeb to send the load balancer IP.

### 8.    Optionally, create an Azure Automation Account and Runbook with the ASE-UDR-Update.ps1 script to maintain the ASE route table.
