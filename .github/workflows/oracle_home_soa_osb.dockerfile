# Use RHEL 8.10 base image
FROM registry.access.redhat.com/ubi8/ubi:8.10 as builder


# Setup filesystem and oracle user  
# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# ------------------------------------------------------------
RUN mkdir /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    chown oracle:root -R /u01 && \
    chmod -R 775 /u01


# Setup jdk 8_291
COPY jdk-8u291-linux-x64.tar.gz /tmp/jdk-8u291-linux-x64.tar.gz
RUN mkdir -p /u01/jdk && \
    tar -xvzf /tmp/jdk-8u291-linux-x64.tar.gz -C /u01/jdk && \
    rm -f /tmp/jdk-8u291-linux-x64.tar.gz

#
# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
USER root
ENV FMW_PKG=fmw_12.2.1.4.0_wls_lite_Disk1_1of1.zip \
    FMW_JAR=fmw_12.2.1.4.0_wls_lite_generic.jar \
    FMW_JAR1=fmw_12.2.1.4.0_soa.jar \
    FMW_JAR2=fmw_12.2.1.4.0_osb.jar \
    FMW_JAR3=fmw_12.2.1.4.0_b2bhealthcare.jar \
    OPATCH_PATCH_DIR="${OPATCH_PATCH_DIR:-/u01/opatch_patch}"  \
    JAVA_HOME=/u01/jdk/jdk1.8.0_291 \
    ORACLE_HOME=/u01/oracle \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    PATH=$PATH:/u01/jdk/jdk1.8.0_291/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin

# Copy packages
# -------------
COPY --chown=oracle:root $FMW_PKG install.file oraInst.loc /u01/

#
# Copy installers and patches for install
# -------------------------------------------
ADD  $FMW_JAR1 $FMW_JAR2 $FMW_JAR3 /u01/
RUN mkdir /u01/patches  ${OPATCH_PATCH_DIR} && \
    chown oracle:root -R /u01
COPY patches/* /u01/patches/ 
COPY opatch_patch/* ${OPATCH_PATCH_DIR}/ 
COPY container-scripts/* /u01/oracle/container-scripts/
RUN  cd /u01 && chmod 755 *.jar && \
     chmod +xr /u01/oracle/container-scripts/*.*

#
# Copy files and packages for install
# -----------------------------------
USER oracle
RUN cd /u01 && ${JAVA_HOME}/bin/jar xf /u01/$FMW_PKG && cd - && \
    ${JAVA_HOME}/bin/java -jar /u01/$FMW_JAR -silent -responseFile /u01/install.file -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="WebLogic Server" && \
    rm /u01/$FMW_JAR /u01/$FMW_PKG /u01/install.file && \
    rm -rf /u01/oracle/cfgtoollogs

COPY install/* /u01/
RUN cd /u01 && \
  $JAVA_HOME/bin/java -jar $FMW_JAR1 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME && \
  $JAVA_HOME/bin/java -jar $FMW_JAR2 -silent -responseFile /u01/osb.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="Service Bus" && \
  $JAVA_HOME/bin/java -jar $FMW_JAR3 -silent -responseFile /u01/b2b.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME INSTALL_TYPE="B2B" && \
  rm -fr /u01/*.jar /u01/*.response


FROM registry.access.redhat.com/ubi8/ubi:8.10 

USER root
ENV ORACLE_HOME=/u01/oracle \
    JAVA_HOME=/u01/jdk/jdk1.8.0_291 \
    USER_MEM_ARGS="-Djava.security.egd=file:/dev/./urandom" \
    SCRIPT_FILE=/u01/oracle/createAndStartEmptyDomain.sh \
    HEALTH_SCRIPT_FILE=/u01/oracle/get_healthcheck_url.sh \
    PATH=$PATH:/u01/jdk/jdk1.8.0_291/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin

# Setup filesystem and oracle user
# Adjust file permissions, go to /u01 as user 'oracle' to proceed with WLS installation
# ------------------------------------------------------------
RUN mkdir -p /u01 && \
    chmod 775 /u01 && \
    useradd -b /u01 -d /u01/oracle -m -s /bin/bash oracle && \
    chown oracle:root /u01

ENV PATH=$PATH:/u01/oracle/container-scripts:/u01/oracle/oracle_common/modules/thirdparty/org.apache.ant/1.10.5.0.0/apache-ant-1.10.5/bin
RUN yum install -y hostname && \
    rm -rf /var/cache/yum

COPY --from=builder --chown=oracle:root /u01 /u01
# Copy scripts
#-------------
COPY container-scripts/createAndStartEmptyDomain.sh container-scripts/create-wls-domain.py container-scripts/get_healthcheck_url.sh /u01/oracle/

RUN chmod +xr $SCRIPT_FILE $HEALTH_SCRIPT_FILE && \
    chown oracle:root $SCRIPT_FILE /u01/oracle/create-wls-domain.py $HEALTH_SCRIPT_FILE


USER oracle
HEALTHCHECK --start-period=5m --interval=1m CMD curl -k -s --fail `$HEALTH_SCRIPT_FILE` || exit 1
WORKDIR $ORACLE_HOME
CMD ["/u01/oracle/container-scripts/createDomainAndStart.sh"]
