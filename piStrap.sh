#!/bin/bash
# @Author: harmoN
# @Date:   2015-04-03 10:11:23
# @Last Modified by:   harmoN
# @Last Modified time: 2015-04-04 03:08:08

# RASPBERRY Pi Bootstrap Script

RUN_FILE=/root/.pibstd/strapped

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)

UND=$(tput smul)
BOLD=$(tput bold)

RST=$(tput sgr0)

if [ ! -f $RUN_FILE ]; then
  echo -e "${UND}Welome to the PiBoostrap Script!${RST} -- ${GREEN}First Run Setup${RST} \n"
  read -p "${BOLD}Resize root partition and attempt to create Swap?${RST} [Yy,Nn] " resize
  while true
  do
    case $resize in
      [yY]* ) mkdir /root/.pibstd && touch $RUN_FILE
          ROOT_SIZE_SECTORS=$(fdisk -l | awk '/Disk \/dev\/mmcblk0:/{getline; print $8}')
          SWAP_SIZE_SECTORS=1048576
          FDISK_CMDS=/tmp/fdiskcmds
          OLD_SWAP=$(fdisk -l | grep -ic "mmcblk0p3")
          if [ $ROOT_SIZE_SECTORS -lt 7782400 ]; then
            echo "${RED}SD too small for Swap - use 8GB or Larger SD Card to default 512MB SWAP ${RST}"
            echo -e "${GREEN}Increasing ROOT...${RST}"
            if [ $OLD_SWAP -eq 1 ]; then
              echo -e "d\n3" >> $FDISK_CMDS
              sed -i '/mmcblk0p3/d' /etc/fstab
            fi
            echo -e "d\n2\nn\np\n2\n\nw\nx" >> $FDISK_CMDS
            fdisk /dev/mmcblk0 < $FDISK_CMDS > /dev/null 2>&1
            rm -f $FDISK_CMDS
          else
            echo -e "${GREEN}Increasing ROOT and creating SWAP Partition...${RST}"
            if [ $OLD_SWAP -eq 1 ]; then
              echo -e "d\n3" >> $FDISK_CMDS
              sed -i '/mmcblk0p3/d' /etc/fstab
            fi
            echo -e "d\n2\nn\np\n\n" >> $FDISK_CMDS
            echo $(( ${ROOT_SIZE_SECTORS}-${SWAP_SIZE_SECTORS}  )) >>  $FDISK_CMDS
            echo -e "n\np\n\n\n\nt\n3\n82\nw\nx" >> $FDISK_CMDS
            fdisk /dev/mmcblk0 < $FDISK_CMDS > /dev/null 2>&1
            rm -f $FDISK_CMDS
            echo "/dev/mmcblk0p3 none swap sw 0 0 " >> /etc/fstab
            echo "SwapOn" >> $RUN_FILE
          fi
          echo "/root/piStrap.sh" >> ~/.bashrc
          echo -e "${BOLD}${RED}You need to Reboot to Continue${RST}"
          break;;
       [nN]* ) break;;
      
          *) echo "Enter Y or N" 
             break;;
      esac
  done

else
    sed -i '/piStrap.sh/d' ~/.bashrc
    RESIZED=$(grep -ic 'ReSized' $RUN_FILE)
    SWAP_ON=$(grep -ic 'SwapOn' $RUN_FILE)
    BASE=$(grep -ic 'Base' $RUN_FILE)
    PY=$(grep -ic 'Py' $RUN_FILE)
    W1=$(grep -ic 'w1' $RUN_FILE)
    OLED=$(grep -ic 'OLED' $RUN_FILE)
    GPIO=$(grep -ic 'GPIO' $RUN_FILE)
    NAME=$(grep -ic 'NAME' $RUN_FILE)
    ROOT_CHANGED=$(grep -ic 'ROOT' $RUN_FILE)

    echo -e "${UND}Welome to the PiBoostrap Script!${RST} -- ${GREEN}Package install and system config stage${RST}\n"
    
    if [ $RESIZED -lt 1 ]; then
      if [ $SWAP_ON -eq 1 ]; then
          echo -e "${GREEN}Resizing Partition and Enabling Swap${RST}"
          resize2fs /dev/mmcblk0p2 > /dev/null 2>&1
          mkswap /dev/mmcblk0p3 > /dev/null 2>&1
          swapon -a > /dev/null 2>&1
          echo "ReSized" >> $RUN_FILE
          echo -e "${GREEN}Root Partition Resized and SWAP Partition Enabled${RST}\n"
        else
          echo -e "Resizing Partition\n"
          resize2fs /dev/mmcblk0p2 > /dev/null 2>&1
          echo "ReSized" >> $RUN_FILE
          echo -e "${GREEN}Root Partition Resized${RST}\n"
      fi
    fi
      
    echo "${GREEN}Base Package Install ${RST}"
    #Base Package Install
    if [ $BASE -lt 1 ]; then
      apt-get update && apt-get upgrade -y
      apt-get dist-upgrade -y
      apt-get install -y rpi-update raspi-config
      rpi-update
      apt-get install -y build-essential unzip nano sudo git
      echo -e "${GREEN}Done base Package Install!${RST}"
      echo "Base" >> $RUN_FILE
    fi

    #Custom Package Install
    echo "${GREEN}Custom Package Install ${RST}"
    #Python Version
    if [ $PY -lt 1 ]; then
      read -p "${BOLD}Configure Python?${RST} [Yy/Nn] " pyth
      while true
      do
        case $pyth in
        [yY]* ) read -p "${BOLD}Default Python2 or Python3?${RST} [2,3] " pythonv
                while true
                do
                  case $pythonv in
                    [3]* ) apt-get install -y python3 python3-dev python3-pip
                           rm -f /usr/bin/python
                           ln -s /usr/bin/python3 /usr/bin/python
                           break;;
                    [2]* ) apt-get install -y python python-dev python-pip
                           break;;

                        *) echo "${RED}Choose 2, or 3 ${RST}"
                           break;;
                  esac
                done
                echo "Py" >> $RUN_FILE
                break;;
        [nN]* ) break;;

             *) echo "${RED}Choose Y, or N ${RST}"
                break;;
        esac
      done
    fi

    #w1-gpio Temp Sensor
    if [ $W1 -lt 1 ]; then
      read -p "${BOLD}Configure w1-gpio Temp Sensor on GPIO 4?${RST} [Yy/Nn] " temp
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
            echo "w1" >> $RUN_FILE
            echo -e "${GREEN}w1-gpio and w1-therm modules enabled and configured${RST}\n"
            break;;
        [nN]* ) break;;
           
           *) echo "${RED}Choose Y, or N ${RST}"
              break;;
          esac
      done
    fi

    #pigpio Library
    if [ $GPIO -lt 1 ]; then
      read -p "${BOLD}Install pigpio Library?${RST} [Yy,Nn] " gpio
      while true
      do
        case $gpio in
          [yY]* ) cd /tmp/
                  wget abyz.co.uk/rpi/pigpio/pigpio.zip
                  unzip pigpio.zip
                  cd PIGPIO
                  make
                  make install
                  pigpiod
                  sed -i '$ i\\/usr\/local\/bin\/pigpiod' /etc/rc.local
                  echo "GPIO" >> $RUN_FILE
                  echo -e "${GREEN}pigpio Library Installed and pigpiod started${RST}\n"
                  break;;
          [nN]* ) break;;

             *) echo "${RED}Choose Y, or N ${RST}"
              break;;
          esac
      done
    fi

    #Adafruit_Python_SSD1306
    if [ $OLED -lt 1 ]; then
      read -p "${BOLD}Install Adafruit Python SSD1306 (OLED) Library?${RST} [Yy,Nn] " oled
      while true
      do
        case $oled in
          [yY]* ) cd /tmp/
              git clone https://github.com/adafruit/Adafruit_Python_SSD1306
              cd Adafruit_Python_SSD1306
              python setup.py install
              echo "OLED" >> $RUN_FILE
              echo -e "${GREEN}Adafruit Python SSD1306 Library Installed${RST}\n"
              break;;
          [nN]* ) break;;

             *) echo "${RED}Choose Y, or N{RST}"
                break;;
          esac
      done
    fi
    echo -e "${GREEN}Custom Package Install Complete!${RST} \n"

    echo "${GREEN}User Modifications${RST}"

    #Create New User
    read -p "${BOLD}Create new sudo User?${RST} [Yy/Nn] " newuser
    while true
    do
      case $newuser in
      [yY]* ) read -p "${BOLD}Username: ${RST}" usern
          adduser $usern
          usermod -a -G sudo $usern
          break;;
      [nN]* ) break;;
         
         *) echo "${RED}Choose Y, or N ${RST}"
            break;;
        esac
    done

    #Change Hostname
    if [ $NAME -lt 1 ]; then
      read -p "${BOLD}Change System HostName?${RST} [Yy/Nn] " hostn
      while true
      do
        case $hostn in
      [yY]* ) read -p "${BOLD}Enter New Hostname: ${RST}" newname
              sed -i '/'$(hostname)'/d' /etc/hosts
              echo $newname > /etc/hostname
              echo "127.0.0.1 $newname" >> /etc/hosts
              /etc/init.d/hostname.sh
              echo "${GREEN}Hostname Changed too ${RST} $newname"
              echo "NAME" >> $RUN_FILE
              break;;
      [nN]* ) break;;
         
         *) echo "${RED}Choose Y, or N ${RST}"
              break;;
        esac
    done
    fi

    #Change Root PW
    if [ $ROOT_CHANGED -lt 1 ]; then
      read -p "${BOLD}Change Root User PW?${RST} [Yy/Nn] " rootuser
      while true
      do
        case $rootuser in
      [yY]* ) passwd root
              echo "ROOT" >> $RUN_FILE
              break;;

      [nN]* ) break;;
         
         *) echo "${RED}Choose Y, or N ${RST}"
            break;;
        esac
    done
    fi

    echo -e "\n${BOLD}${GREEN}Pi BootStrap Succesful! ${RST} "
fi
