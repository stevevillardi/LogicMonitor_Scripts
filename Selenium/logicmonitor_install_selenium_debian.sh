#!/usr/bin/env bash

# Versions
CHROME_DRIVER_VERSION=`curl -sS https://chromedriver.storage.googleapis.com/LATEST_RELEASE`

# Remove existing downloads and binaries so we can start from scratch.
sudo apt-get remove google-chrome-stable
rm ~/selenium-server-standalone-*.jar
rm ~/chromedriver_linux64.zip
rm ~/usr/logic/bin/chromedriver
sudo rm /usr/local/bin/chromedriver
sudo rm /usr/local/bin/selenium-server-standalone.jar

#Download latest package of Chrome
sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb

# Get unzip
sudo apt-get install unzip -y

# Install ChromeDriver.
wget -N https://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/
unzip ~/chromedriver_linux64.zip -d ~/
rm ~/chromedriver_linux64.zip
sudo mv -f ~/chromedriver /usr/local/bin/chromedriver
sudo chown root:root /usr/local/bin/chromedriver
sudo chmod 0755 /usr/local/bin/chromedriver

#Instal Selenium
wget -N https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar -P ~/

#Make custom directory in LogicMonitor Collector directory
if [ -d "/usr/local/logicmonitor/agent/custom" ] 
then
    echo "Directory /usr/local/logicmonitor/agent/custom exists" 
else
    sudo mkdir /usr/local/logicmonitor/agent/custom
fi

#Move Selenium to LogicMonitor Collector's custom directory
mv -f ~/selenium-server-standalone-3.141.59.jar /usr/local/logicmonitor/agent/custom/selenium-server-standalone.jar

#Get number of jars on Collector in order to properly increment
TOTAL_JARS=`egrep "wrapper.java.classpath.[0-9]+=../" /usr/local/logicmonitor/agent/conf/wrapper.conf -o | sort | wc -l`
echo "Total jars=${TOTAL_JARS}"
NEW_JAR=$((TOTAL_JARS+1))

#Get line number for last jar in wrapper.config
JAR_INDEX=`grep -n "wrapper.java.classpath.${TOTAL_JARS}=." /usr/local/logicmonitor/agent/conf/wrapper.conf | cut -d: -f 1`
#echo "Original jar=${JAR_INDEX}"

JAR_INDEX=$((JAR_INDEX+1))
#echo "incremented index=${JAR_INDEX}"

if grep -q "selenium" /usr/local/logicmonitor/agent/conf/wrapper.conf
then
   echo "Selenium already in wrapper config - exiting."
else
   sudo sed -i "${JAR_INDEX}iwrapper.java.classpath.${NEW_JAR}=../custom/selenium-server-standalone.jar" /usr/local/logicmonitor/agent/conf/wrapper.conf
   #Now let's restart the collector
   echo "Restarting Collector"
   sudo systemctl restart logicmonitor-agent.service
   echo "Collector has restarted"
fi