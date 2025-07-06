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

USER root
ENV FMW_JAR1=fmw_12.2.1.4.0_soa_quickstart.jar \
    FMW_JAR2=fmw_12.2.1.4.0_soa_quickstart2.jar \
    JAVA_HOME=/u01/jdk/jdk1.8.0_291 \
    ORACLE_HOME=/u01/oracle \
    PATH=$PATH:/u01/jdk/jdk1.8.0_291/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin

# Copy packages
# -------------
COPY --chown=oracle:root $FMW_JAR1 $FMW_JAR2 soasuite.response oraInst.loc /u01/

USER oracle
RUN cd /u01/ && \
    java -jar $FMW_JAR1 -silent -responseFile /u01/soasuite.response -invPtrLoc /u01/oraInst.loc -jreLoc $JAVA_HOME -ignoreSysPrereqs -force -novalidation ORACLE_HOME=$ORACLE_HOME


CMD ["/bin/bash"]