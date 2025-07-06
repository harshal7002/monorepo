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
WLST_SCRIPT="/tmp/deploy_${APP_NAME}.py"
cat > "$WLST_SCRIPT" <<EOF
try:
    connect('weblogic', 'Weblogic@123', 't3://34.47.182.189:7001')
    edit()
    startEdit()
    deploy(appName='${APP_NAME}', path='${WAR_FILE}', targets='AdminServer', stageMode='stage', upload='true', block='true')
    save()
    activate()
    print("✅ Deployment of '${APP_NAME}' successful.")
except Exception, e:
    print("❌ Deployment failed:", e)
    undo('true', 'y')
    cancelEdit('y')
exit()
EOF

# Run WLST script
$ORACLE_HOME/oracle_common/common/bin/wlst.sh "$WLST_SCRIPT"


connect('weblogic', 'Weblogic@123', 't3://34.47.182.189:7001')
edit()
startEdit()
redeploy('oracle-deployment', '/u01/runner/actions-runner/_work/monorepo/monorepo/SOA/oracle-deployment/target/demo-0.0.1-SNAPSHOT.war', targets='AdminServer', stageMode='stage', upload='true', block='true')
save()
activate()
print("✅ Deployment of 'oracle-deployment' successful.") 