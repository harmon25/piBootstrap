#!/bin/bash
# @Author: harmoN
# @Date:   2015-04-03 10:11:23
# @Last Modified by:   harmoN
# @Last Modified time: 2015-04-03 21:39:33

# RASPBERRY Pi Bootstrap Script

if [ ! -f /root/.bootstraped/firstrun ]; then
	echo "Welome to the PiBoostrap Script! -- First Run Setup"
	read -p "Resize root partition and attempt to create Swap? [Yy,Nn] " resize
	while true
	do
		case $resize in
			[yY]* ) mkdir /root/.bstd && touch /root/.bstd/firstrun
					ROOT_SIZE_SECTORS=$(fdisk -l | awk '/Disk \/dev\/mmcblk0:/{getline; print $8}')
					SWAP_SIZE_SECTORS=1000000
					OLD_SWAP=$(fdisk -l | grep -ic "mmcblk0p3")
					if [ $ROOT_SIZE_SECTORS -lt 7782400 ]; then
						echo "SD too small for Swap - use 8GB or Larger SD Card to default 512MB SWAP"
						echo -e "\nIncreasing ROOT..."
						if [ $OLD_SWAP -eq 1 ]; then
							echo -e "d\n3" >> /tmp/fdiskcmds
							sed -i '/mmcblk0p3/d' /etc/fstab
						fi
						echo -e "d\n2\nn\np\n2\n\nw\nx" >> /tmp/fdiskcmds
						fdisk /dev/mmcblk0 < /tmp/fdiskcmds > /dev/null 2>&1
						rm -f /tmp/fdiskcmds
						echo -e "\nDONE!"
					else
						echo -e "\nIncreasing ROOT and creating SWAP Partition..."
						if [ $OLD_SWAP -eq 1 ]; then
							echo -e "d\n3" >> /tmp/fdiskcmds
							sed -i '/mmcblk0p3/d' /etc/fstab
						fi
						echo -e "d\n2\nn\np\n\n" >> /tmp/fdiskcmds
						echo $(( ${ROOT_SIZE_SECTORS}-${SWAP_SIZE_SECTORS}  )) >>  /tmp/fdiskcmds
						echo -e "n\np\n\n\n\nt\n3\n82\nw\nx" >> /tmp/fdiskcmds
						fdisk /dev/mmcblk0 < /tmp/fdiskcmds > /dev/null 2>&1
						rm -f /tmp/fdiskcmds
						echo "/dev/mmcblk0p3 none swap sw 0 0 " >> /etc/fstab
						echo "SwapOn" >> /root/.bstd/firstrun
					fi
					echo "/root/piStrap.sh" >> ~/.bashrc
					echo -e "\nYou need to Reboot to Continue\n"
					break;;
			 [nN]* ) break;;
			
	 			  *) echo "Enter Y or N" ;;
  		esac
	done

else
	BOOTSTRAPPED=$(grep -ic 'BootStrapped' /root/.bstd/firstrun)
	if [ $BOOTSTRAPPED -lt 1 ]; then
		sed -i '/piStrap.sh/d' ~/.bashrc
		SWAP_ON=$(grep -ic 'SwapOn' /root/.bstd/firstrun)
		BASE=$(grep -ic 'BaseInstall' /root/.bstd/firstrun)
		echo "Welome to the PiBoostrap Script! -- Package Install and Config"
		if [ $SWAP_ON -eq 1 ]; then
				echo -e "Resizing Partition and Enabling Swap\n"
				resize2fs /dev/mmcblk0p2 > /dev/null 2>&1
				mkswap /dev/mmcblk0p3 && swapon -a > /dev/null 2>&1
				echo -e "Root Partition Resized and SWAP Partition Enabled\n"
			else
				echo -e "Resizing Partition\n"
				resize2fs /dev/mmcblk0p2
				echo -e "\nRoot Partition Resized\n"
		fi
			
		echo "Base Package Install"
		#Base Package Install
		if [ $BASE -lt 1 ]; then
			apt-get update && apt-get upgrade -y
			apt-get dist-upgrade -y
			apt-get install -y rpi-update raspi-config
			rpi-update
			apt-get install -y build-essential unzip nano sudo git
			echo -e "Done base Package Install!\n"
			echo "BaseInstall" >> /root/.bootstraped/firstrun
		fi
		
		#Create New User
		read -p "Create new sudo User? [Yy/Nn] " newuser
		while true
		do
			case $newuser in
			[yY]* ) read -p "Username: " usern
					adduser $usern
					usermod -a -G sudo $usern
					break;;

			[nN]* ) break;;
			 	 
			 	 *) echo "Choose Y, or N";;
	  		esac
		done

		#Custom Package Install
		echo "Custom Package Install"
		#Python Version
		read -p "Default Python2 or Python3 [2,3]? " pythonv
		while true
		do
			case $pythonv in
				[3]* ) apt-get install -y python3 python3-dev python3-pip; break;;
					   rm -f /usr/bin/python
					   ln -s /usr/bin/python3 /usr/bin/python
					
				[2]* ) apt-get install -y python python-dev python-pip; break;;
				
				    *) echo "Choose 2, or 3 ";;
	  		esac
		done

		#w1-gpio Temp Sensor
		read -p "Configure w1-gpio Temp Sensor on GPIO 4? [Yy/Nn] " temp
		while true
		do
			case $temp in
			[yY]* ) echo "dtoverlay=w1-gpio" >> /boot/config.txt
					echo -e "w1-gpio\nw1-therm" >> /etc/modules
					modprobe w1-gpio
					modprobe w1-therm
					cd /tmp/
					git clone https://github.com/timofurrer/w1thermsensor
					cd w1thermsensor
					python ./setup.py install
					break;;

			[nN]* ) break;;
			 	 
			 	 *) echo "Choose Y, or N";;
	  		esac
		done

		#pigpio Library
		read -p "Install pigpio Library? [Yy,Nn] " gpio
		while true
		do
			case $gpio in
				[yY]* ) cd /tmp/
						wget abyz.co.uk/rpi/pigpio/pigpio.zip
						unzip pigpio.zip
						cd PIGPIO
						make
						make install
						break;;

				[nN]* ) break;;

				 	 *) echo "Choose Y, or N";;
	  		esac
		done

		#Adafruit_Python_SSD1306
		read -p "Install SSD1306 (OLED) Library? [Yy,Nn] " oled
		while true
		do
			case $oled in
				[yY]* ) cd /tmp/
						git clone https://github.com/adafruit/Adafruit_Python_SSD1306
						cd Adafruit_Python_SSD1306
						python setup.py install
						break;;

				[nN]* ) break;;

				 	 *) echo "Choose Y, or N";;
	  		esac
		done

		echo "Custom Package Install Complete!"
		echo "Pi BootStrap Succesful"
		echo "BootStrapped" >> /root/.bootstraped/firstrun
else
	echo "This Pi is already BootStrapped!"
fi
fi
