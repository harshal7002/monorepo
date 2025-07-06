#!/bin/bash

# USAGE: ./deploy_to_weblogic.sh SOA/oracle-deployment

set -e

APP_DIR="$1"

# Set WebLogic environment variables
# export WL_HOME="/home/harshal/weblogic/weblogic"  # Adjust if needed
# export JAVA_HOME="/opt/oracle/jdk-11"
# export PATH="$JAVA_HOME/bin:$WL_HOME/bin:$PATH"

# WebLogic credentials
export WLS_USERNAME="weblogic"
export WLS_PASSWORD="Weblogic@123"
export WLS_URL="t3://34.47.182.189:7001"

# Find WAR file inside the provided path
WAR_FILE=$(find "$APP_DIR/target" -name "*.war" | head -n 1)

if [[ ! -f "$WAR_FILE" ]]; then
  echo "❌ ERROR: No WAR file found in $APP_DIR/target"
  exit 1
fi

# Use the folder name as the app name (e.g., oracle-deployment)
APP_NAME=$(basename "$APP_DIR")

echo "🚀 Deploying $APP_NAME from $WAR_FILE to WebLogic..."

# Run WLST
$ORACLE_HOME/oracle_common/common/bin/wlst.sh << EOF
from weblogic.management.configuration import *
try:
    # Connect to the WebLogic Server
    connect('$WLS_USERNAME', '$WLS_PASSWORD', '$WLS_URL')

    # Start a session and check for the server's availability
    edit()
    startEdit()

    # Deploy the WAR file
    deploy(appName='$APP_NAME', path='$WAR_FILE_PATH', targets='AdminServer', stageMode='stage')

    # Save and activate the changes
    save()
    activate()

    print("Deployment '$APP_NAME' successful!")

except Exception as e:
    print("Deployment failed:", e)
    undo()
    cancel()

# Exit WLST
exit()
EOF
