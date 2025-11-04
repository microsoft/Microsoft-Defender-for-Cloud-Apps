## [Purpose/Objective]
This script is intended to help in automating the collection of diagnostic data needed for troubleshooting Docker\Podman LC Container issues. Once this script is transferred to the host machine and run, it will collect a large number of logs\diagnostic data and compress all of that data into one file.

## Collected Data - Host
The script will collect the below data\details\tests from the host side (The Red Hat\Ubuntu\Linux machine hosting the Docker\Podman LC Container). Those files will be placed directly under the output folder (**LogCollecterDiag**_DateTime)


- **LogCollecterDiag**_<DateTime>

        - Host_NetChecks.txt - Output of nc\curl tests against MDA\OCSP URLs executed from within the Host Linux machine.
        - Host_NetStat.txt - Output of Netstat executed from within the Host Linux machine.
        - Host_<podman||docker>Info.txt - Podman\Docker Version Info.
        - Host_<podman||docker>Networks.txt - Podman\Docker Networks Info (Bridge Networks).
        - Host_RunningProc.txt- Processes on the Host at script run time.
        - Host_SELinuxAuditMessages.txt - SELinux audit messages. (For Red Hat Hosts)
        - Host_SELinuxContexts.txt - SELinux contexts. (For Red Hat Hosts)
        - Host_SELinuxStatus.txt - SELinux status. (For Red Hat Hosts)
        - Host_AppArmorStatus.txt - App Armor Details. (For Ubuntu Hosts)
        - Host_SysInfo.txt - Operating system information
        - Host_ConfiguredContainers.txt - LC Docker\Podman Running Containers on this host machine.
        - Host_DNSConfig.txt - Contents of DNS configuration of host machine.
        - Host_FirewallConfigs.txt - Output of OS firewall rules
        - Host_IfConfig.txt - Output of IFConfig on the host machine to show all configured interfaces.
        - Host_InstalledPackages.txt - List of installed applications on a linux server.
        - Host_KernelBuffer.txt - Kernel Buffer messages, to show any permission denies issues.
        - Host_Disk_df-h.txt - Host (df -h) output.
        - Host_ContainersDiskInfo.txt - Container disk on space info.
        - Host_Lib_Versions - Library versions of the below processes\tools on Host:
                - wget.txt
                - rsyslogd.txt
                - openssl.txt
                - java.txt
                - pure-ftpd.txt


## Collected Data - Container

The script will collect the below data\details\tests from the container side (The Docker\Podman LC container). Those files will be placed under the respective container folder within the script output folder (**LogCollecterDiag**_DateTime\Container<ContainerID>)

- **LogCollecterDiag**_<DateTime>


        - <podman||docker>-Container<ContainerID>
                - AdallomLogs
                        - columbus
                                - log-archive: Various rotated logs
                                - dbwrites.log
                                - events.log
                                - info.log
                                - trace.log
                                - error.log
                                - headers.log
                        - columbusInstaller
                                - dbwrites.log
                                - events.log
                                - info.log
                                - trace.log
                                - error.log
                                - headers.log
                - ColumbusConfig
                        - columbus.cfg
                        - columbus.logback.xml
                        - columbusInstaller.cfg
                        - columbusUser.cfg
                        - rsyslog_tls.conf
                - OtherConfigs
                        - logrotate.d (rsyslog, syslog_601, unattended-upgrades, wtmp, alternatives, apt, btmp, dpkg)
                        - ca-certificates.conf
                        - logrotate.conf
                        - rsyslog.conf
                        - rsyslog_with_tls.conf
                - SupervisorLogs
                        - columbus-stderr---supervisor-khfwqoci.log
                        - columbus-stdout---supervisor-e14h8xmf.log
                        - cron-stderr---supervisor-3nh6xdn8.log
                        - cron-stdout---supervisor-2ojex2t8.log
                        - ftpd-stderr---supervisor-lx3on883.log
                        - ftpd-stdout---supervisor-zn4kgw1t.log
                        - rsyslog-debug-stderr---supervisor-0nwss005.log
                        - rsyslog-debug-stdout---supervisor-168meu3u.log
                        - rsyslog-stderr---supervisor-ml50yq55.log
                        - rsyslog-stdout---supervisor-2fa06fwi.log
                        - supervisord.log
                - <podman||docker>-LibVersions - Library versions of the below processes\tools on Container:
                        - wget.txt
                        - rsyslogd.txt
                        - openssl.txt
                        - java.txt
                        - pure-ftpd.txt
                        - Logrotate.txt
                        - Container.txt
                - <ContainerID>_Diag.txt - output of collector_status command
                - <ContainerID>_RSyslog.txt - RSyslog debug log
                - <ContainerID>_LogRotateStatus.txt
                - <ContainerID>_<podman||docker>-Containter<ContainerID>-Logs.txt - Docker\Podman logs for this container
                - <ContainerID>_URLsCheck.txt - Output of wget tests against MDA\OCSP URLs executed from within the LC Container.
                - <ContainerID>_AdallomDirectories.txt - Listing the directories shown under the Adallom Parent directory (Useful to show created Messages\Ports files\directories)
                - <ContainerID>_CronJobs.txt - Cron jobs configured under the current user.
                - <ContainerID>_RootCronJobs.txt - Cron jobs configured under root.


## [Procedure]

Below Linux commands will be used:
- chmod - Modify permissions on a file.
- sudo  - Execute a command as the system administrator, or root in the Linux world.
- tar - Creating and manipulating archive files

**Steps:**
1. Download the compressed bash script (LogCollectorDiag.tar.gz) to the Host Machine where the Docker\Podman LC is installed.
2. Untar the compressed script using the below command:
```
sudo tar -xzf LogCollectorDiag.tar.gz
```
3. Change file permissions to allow for execution
```
sudo chmod -R a+x LogCollectorDiag.sh
```
4. Execute the script
```
sudo ./LogCollectorDiag.sh
```
5. Allow the script to run. It should take ~1 minute to complete (Due to the network tests and the RSyslog Debug data collection).
6. You will now have a tar.gz file located in the **/tmp/** directory of the Linux Host machine.
