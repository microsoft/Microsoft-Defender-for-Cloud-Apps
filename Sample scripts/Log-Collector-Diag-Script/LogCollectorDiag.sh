#! /bin/bash
# Quick diag script to collect and package MDA log collector information for analysis
# This script is not supported by Microsoft so use at your own risk


######################Host Checks and Info#####################################

OS=`cat /etc/os-release | grep PRETTY_NAME | sed -n 's/.*\(SUSE\|Ubuntu\|Red Hat\|CentOS\).*/\1/p'`

folderPath=/tmp/
fileName=LogCollectorDiag_$(date -u +%Y%m%d_%H%M)
sudo mkdir $folderPath$fileName



echo "Grabbing some host information..."

sudo uname -a | sudo tee "$folderPath$fileName/Host_SysInfo.txt" > /dev/null
cat /etc/os-release | grep PRETTY_NAME | sudo tee -a "$folderPath$fileName/Host_SysInfo.txt" > /dev/null

#host process info
sudo ps -e -u root --forest | sudo tee "$folderPath$fileName/Host_RunningProc.txt" > /dev/null 

#host network interfaces info and NetStat
sudo ifconfig | sudo tee "$folderPath$fileName/Host_IfConfig.txt" > /dev/null
sudo netstat -tuln | sudo tee "$folderPath$fileName/Host_NetStat.txt" > /dev/null

sudo dmesg | sudo tee "$folderPath$fileName/Host_KernelBuffer.txt" > /dev/null

#disk info
sudo df -h | sudo tee "$folderPath$fileName/Host_Disk_df-h.txt" > /dev/null


#Lib versions
sudo mkdir $folderPath$fileName/Host_Lib_Versions
sudo wget --version | sudo tee "$folderPath$fileName/Host_Lib_Versions/wget.txt" > /dev/null
sudo openssl version -a | sudo tee "$folderPath$fileName/Host_Lib_Versions/openssl.txt" > /dev/null
sudo java -version &> "$folderPath$fileName/Host_Lib_Versions/java.txt"
sudo pure-ftpd --version &> tee "$folderPath$fileName/Host_Lib_Versions/pure-ftpd.txt" > /dev/null
sudo rsyslogd -v | sudo tee "$folderPath$fileName/Host_Lib_Versions/rsyslogd.txt" > /dev/null


#host installed packages
if [ "${OS,,}" == "ubuntu" ]; then
    sudo apt list --installed | sudo tee "$folderPath$fileName/Host_InstalledPackages.txt" > /dev/null
    sudo aa-status | sudo tee "$folderPath$fileName/Host_AppArmorStatus.txt" > /dev/null
elif [ "${OS,,}" == "red hat" ]; then
    (sudo yum list installed || sudo dnf list installed) | sudo tee "$folderPath$fileName/Host_InstalledPackages.txt" > /dev/null
    sudo sestatus | sudo tee "$folderPath$fileName/Host_SELinuxStatus.txt" > /dev/null
    sudo semanage fcontext -l | sudo tee "$folderPath$fileName/Host_SELinuxContexts.txt" > /dev/null
    sudo grep "SELinux" /var/log/audit/audit.log | sudo tee "$folderPath$fileName/Host_SELinuxAuditMessages.txt" > /dev/null
elif [ "${OS,,}" == "centos" ]; then
    sudo dnf list installed | sudo tee "$folderPath$fileName/Host_InstalledPackages.txt" > /dev/null
elif [ "${OS,,}" == "suse" ]; then
    sudo zypper se --installed-only | sudo tee "$folderPath$fileName/Host_InstalledPackages.txt" > /dev/null
fi

#host DNS config
sudo cp /etc/resolv.conf $folderPath$fileName/Host_DNSConfig.txt

#host FIREWALL inspection
if [ "${OS,,}" == "ubuntu" ]; then
    sudo ufw status verbose | sudo tee "$folderPath$fileName/Host_FirewallConfigs.txt" > /dev/null
elif [ "${OS,,}" == "red hat" ]; then
    sudo firewall-cmd --list-all | sudo tee "$folderPath$fileName/Host_FirewallConfigs.txt" > /dev/null
elif [ "${OS,,}" == "centos" ]; then
    sudo firewall-cmd --list-all | sudo tee "$folderPath$fileName/Host_FirewallConfigs.txt" > /dev/null
elif [ "${OS,,}" == "suse" ]; then
    sudo iptables -L INPUT | sudo tee "$folderPath$fileName/Host_FirewallConfigs.txt" > /dev/null
fi

#host network checks

sudo touch $folderPath$fileName/Host_NetChecks.txt

urlsToCheck=(
"portal.cloudappsecurity.com"
"cdn.cloudappsecurity.com"
"adaproddiscovery.azureedge.net"
"dev.virtualearth.net"
"cloudappsecurity.com"
"flow.microsoft.com"
"static2.sharepointonline.com"
"dc.services.visualstudio.com"
"adaprodconsole.blob.core.windows.net"
"prod03use2console1.blob.core.windows.net"
"prod5usw2console1.blob.core.windows.net"
"prod02euwconsole1.blob.core.windows.net"
"prod4uksconsole1.blob.core.windows.net"
)
for i in "${urlsToCheck[@]}"; do 
  if sudo nc -vzw1 $i 443 2>/dev/null; 
    then sudo echo "Connection to $i succeeded" | sudo tee -a "$folderPath$fileName/Host_NetChecks.txt" > /dev/null
    else 
      #echo "Unable to connect. Netcat may not be present. Check your firewall settings to ensure that a connection to $i is permitted."
      sudo echo "Connection to $i failed" | sudo tee -a "$folderPath$fileName/Host_NetChecks.txt" > /dev/null
  fi
done

#Cert validation check
ocspUrls=(
"crl3.digicert.com"
"crl4.digicert.com"
"ocsp.digicert.com"
"www.d-trust.net"
"root-c3-ca2-2009.ocsp.d-trust.net"
"crl.microsoft.com"
"oneocsp.microsoft.com"
"ocsp.msocsp.com"
"www.microsoft.com/pkiops"
)
for i in "${ocspUrls[@]}"; do
  if (sudo curl -v $i 2>&1 | grep 'Connected' ); then #Just checking for connectivity to the endpoint!
        sudo echo "Connection to $i succeeded" | sudo tee -a "$folderPath$fileName/Host_NetChecks.txt" > /dev/null
    else sudo echo "Error connecting to ocsp provider ${i}" | sudo tee -a "$folderPath$fileName/Host_NetChecks.txt" > /dev/null

  fi
done


######################End Host Checks and Info#####################################
######################Container Checks and Info#####################################

echo "Grabbing some container information..."

if (sudo command -v podman &> /dev/null); then
    echo "Podman is installed."
    containerTool=podman
    is_installed=true
    bridgeName=podman
elif (command -v podman &> /dev/null); then
    echo "Podman is installed."
    containerTool=podman
    is_installed=true
    bridgeName=podman
elif (sudo command -v docker &> /dev/null); then
    echo "Docker is installed."
    containerTool=docker
    is_installed=true
    bridgeName=bridge
elif (command -v docker &> /dev/null); then
    echo "Docker is installed."
    containerTool=docker
    is_installed=true
    bridgeName=bridge
else
    echo "Neither Podman nor Docker is installed."
    is_installed=false
fi

if [ "$is_installed" = true ]; then
	$containerTool version | sudo tee "$folderPath$fileName/Host_$containerTool-Info.txt" > /dev/null

	containerIDs=()
	for i in $($containerTool ps -a --filter "ancestor=mcr.microsoft.com/mcas/logcollector" --filter status=running --format "{{.ID}}")  
	  do containerIDs+=($i)
	done

	$containerTool ps -s | sudo tee -a "$folderPath$fileName/Host_ContainersDiskInfo.txt" > /dev/null
	$containerTool ps -a --filter "ancestor=mcr.microsoft.com/mcas/logcollector" --filter status=running --format "table {{.Names}}\t{{.Ports}}\t{{.Mounts}}\t{{.Networks}}" | sudo tee -a "$folderPath$fileName/Host_ConfiguredContainers.txt" > /dev/null

	sudo $containerTool network ls --filter "driver=bridge" | sudo tee -a "$folderPath$fileName/Host_$containerTool-Networks.txt" > /dev/null
	sudo $containerTool network inspect $bridgeName | sudo tee -a "$folderPath$fileName/Host_$containerTool-Networks.txt" > /dev/null

	for i in "${containerIDs[@]}" 
	do
	    containerPath=Container${i}
	    sudo mkdir $folderPath$fileName/$containerTool-$containerPath
	    sudo chmod 777 $folderPath$fileName/$containerTool-$containerPath
	    $containerTool exec -it  $i collector_status -p | sudo tee -a "$folderPath$fileName/$containerTool-$containerPath/${i}_Diag.txt" > /dev/null
	    
	   URLS="http://crl3.digicert.com
	   http://crl4.digicert.com
	   http://ocsp.digicert.com
	   http://www.d-trust.net
	   http://root-c3-ca2-2009.ocsp.d-trust.net
	   http://crl.microsoft.com
	   http://oneocsp.microsoft.com
	   http://ocsp.msocsp.com
	   http://www.microsoft.com/pkiops
	   https://portal.cloudappsecurity.com
	   https://cdn.cloudappsecurity.com
	   https://adaproddiscovery.azureedge.net
	   https://dev.virtualearth.net
	   https://cloudappsecurity.com
	   https://flow.microsoft.com
	   https://static2.sharepointonline.com
	   https://dc.services.visualstudio.com
	   https://adaprodconsole.blob.core.windows.net
	   https://prod03use2console1.blob.core.windows.net
	   https://prod5usw2console1.blob.core.windows.net
	   https://prod02euwconsole1.blob.core.windows.net
	   https://prod4uksconsole1.blob.core.windows.net"
   
	   # Check each URL from the list
   	for URL in $URLS; do
	   	if ($containerTool exec -it  $i wget --spider --timeout=2 --tries=1 "$URL" 2>&1 | grep "connected"); then
	   		echo "$URL is reachable from within the container" >> $folderPath$fileName/$containerTool-$containerPath/${i}_URLsCheck.txt
	   	else
	   		echo "$URL is not reachable from within the container" >> $folderPath$fileName/$containerTool-$containerPath/${i}_URLsCheck.txt
	   	fi
	   done
	
	
	    $containerTool cp $i:/var/log/adallom/ $folderPath$fileName/$containerTool-$containerPath/AdallomLogs
	    $containerTool cp $i:/etc/adallom/config/ $folderPath$fileName/$containerTool-$containerPath/ColumbusConfigs
	    sudo mkdir $folderPath$fileName/$containerTool-$containerPath/OtherConfigs
	    $containerTool cp $i:/etc/rsyslog.conf $folderPath$fileName/$containerTool-$containerPath/OtherConfigs/
	    $containerTool cp $i:/etc/rsyslog_with_tls.conf $folderPath$fileName/$containerTool-$containerPath/OtherConfigs/
	    $containerTool cp $i:/etc/ca-certificates.conf $folderPath$fileName/$containerTool-$containerPath/OtherConfigs/
	    $containerTool cp $i:/etc/logrotate.conf $folderPath$fileName/$containerTool-$containerPath/OtherConfigs/
	    $containerTool cp $i:/etc/logrotate.d/ $folderPath$fileName/$containerTool-$containerPath/OtherConfigs/logrotate.d
	    $containerTool cp $i:/var/log/supervisor/ $folderPath$fileName/$containerTool-$containerPath/SupervisorLogs
#	    $containerTool cp $i:/var/adallom/discoverylogsbackup/ $folderPath$fileName/$containerTool-$containerPath/LogsBackup
#	    $containerTool cp $i:/var/adallom/syslog/ $folderPath$fileName/$containerTool-$containerPath/Syslog
#	    $containerTool cp $i:/var/adallom/ftp/discovery/ $folderPath$fileName/$containerTool-$containerPath/FTP
	    $containerTool cp $i:/var/lib/logrotate/status "$folderPath$fileName/$containerTool-$containerPath/${i}_LogRotateStatus.txt"
	    
	    sudo chmod -R 777 $folderPath$fileName/$containerTool-$containerPath
	    sudo chmod -R 777 $folderPath$fileName/$containerTool-$containerPath/SupervisorLogs
	    

	    $containerTool exec $i ls -laR /var/adallom/ | sudo tee -a "$folderPath$fileName/$containerTool-$containerPath/${i}_AdallomDirectories.txt" > /dev/null
	    
	    $containerTool exec $i crontab -l | sudo tee -a "$folderPath$fileName/$containerTool-$containerPath/${i}_CronJobs.txt" > /dev/null
	    $containerTool exec $i cat -v /var/spool/cron/crontabs/root | sudo tee -a "$folderPath$fileName/$containerTool-$containerPath/${i}_RootCronJobs.txt" > /dev/null
	    
	    sudo mkdir $folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions	    
	    $containerTool exec $i logrotate --version | sudo tee "$folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions/Logrotate.txt" > /dev/null
	    $containerTool exec $i cat /var/adallom/versions | grep columbus- | sudo tee "$folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions/Container.txt" > /dev/null
	    $containerTool exec $i wget --version | sudo tee "$folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions/wget.txt" > /dev/null
	    $containerTool exec $i openssl version -a | sudo tee "$folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions/openssl.txt" > /dev/null
	    $containerTool exec $i java -version &> "$folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions/Java.txt"
	    $containerTool exec $i pure-ftpd --version &> "$folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions/pure-ftpd.txt"
	    $containerTool exec $i rsyslogd -v | sudo tee "$folderPath$fileName/$containerTool-$containerPath/$containerTool-LibVersions/rsyslogd.txt" > /dev/null



	    $containerTool logs $i > "$folderPath$fileName/$containerTool-$containerPath/${i}_$containerTool-$containerPath-Logs.txt" 2>&1


	    echo "Bringing down the syslog daemon for debugging"
    	$containerTool exec $i bash -c "service 'stop rsyslog'; service 'start rsyslog-debug'"
	    echo "Pausing script to collect some syslog debug info"
	    sleep 1m
	
	    echo "Reverting back to normal syslog operations"
	    $containerTool exec  $i bash -c "service 'stop rsyslog-debug'; service 'start rsyslog'"
	    $containerTool cp $i:/var/log/syslog.debug $folderPath$fileName/$containerTool-$containerPath/${i}_RSyslog.txt
	done
fi

######################End Container Checks and Info#####################################
############################Wrapping up#################################################

sudo tar -czf /tmp/$fileName.tar.gz $folderPath$fileName
echo "Archive created for engineer."
echo "File path: $folderPath$fileName.tar.gz"
