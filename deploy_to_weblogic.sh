#!/bin/bash

# Set WebLogic environment variables
export WL_HOME="/home/harshal/weblogic/weblogic"  # Path to WebLogic installation
#export JAVA_HOME="/opt/oracle/jdk-11"  # Path to Oracle JDK
#export PATH="$JAVA_HOME/bin:$WL_HOME/bin:$PATH"

# Set WebLogic credentials and other variables
export WLS_USERNAME="weblogic"
export WLS_PASSWORD="Weblogic@123"
export WLS_URL="t3://localhost:7001"
export WAR_FILE_PATH="target/demo-0.0.1-SNAPSHOT.war"

# Use Jython for WebLogic Scripting Tool (WLST)
$WL_HOME/oracle_common/common/bin/wlst.sh << EOF
from weblogic.management.scripting import WLSTException
from weblogic.management.configuration import *
try:
    # Connect to the WebLogic Server
    connect('$WLS_USERNAME', '$WLS_PASSWORD', '$WLS_URL')

    # Start a session and check for the server's availability
    edit()
    startEdit()

    # Deploy the WAR file
    deploy(appName='SpringBootApp', path='$WAR_FILE_PATH', targets='AdminServer', stageMode='stage')

    # Save and activate the changes
    save()
    activate()

    print("Deployment successful!")

except WLSTException as e:
    print("Deployment failed:", e)
    undo()
    cancel()

# Exit WLST
exit()
EOF