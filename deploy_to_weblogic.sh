#!/bin/bash

# Set environment variables for WebLogic credentials
export WLS_USERNAME="weblogic"
export WLS_PASSWORD="Weblogic@123"
export WLS_URL="t3://localhost:7001"
export WLS_DOMAIN="/home/harshal/weblogic/weblogic/user_projects/domains/basicWLSDomain"
export WAR_FILE_PATH="target/demo-0.0.1-SNAPSHOT.war"  # Path to your built WAR file

# Set WebLogic environment
source $WLS_DOMAIN/bin/setDomainEnv.sh

# Deploy the WAR file using WLST
python << EOF
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
EOF
