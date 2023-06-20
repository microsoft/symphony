# Getting Started with Symphony and self hosted build agents on a Virtual Machine

## Agent Configuration

A virtual machine can be either Linux or Windows (with WSL enabled.) It is recommended to run the self-hosted agent as a service, and to run as root.  The agent can be configured as root using the following commands.

```bash
./config.sh
sudo ./svc.sh install root
sudo ./svc.sh start
```

## Windows (WSL)

If running a self hosted agent on a windows server with WSL. Please complete the following steps.

```powershell
# Open a PowerShell window.

# Fetch the DNS Server IP Address. Note the IP address in the result of this command.
Get-DnsClientServerAddress -InterfaceAlias "Ethernet" -AddressFamily "IPv4"

# Launch WSL
wsl.exe
```

```bash
# Edit or create /etc/wsl.conf
sudo nano /etc/wsl.conf

# Add the following lines to /etc/wsl.conf
[network]
generateResolvConf = false

# Save the file and exit
# Edit /etc/resolv.conf
sudo nano /etc/resolv.conf

#Add the following line
nameserver <ip address of dns obtained from above>

# Save the file and exit
```
