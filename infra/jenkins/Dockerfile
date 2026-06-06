# Start from the official Jenkins LTS image
FROM jenkins/jenkins:lts

# Skip the initial setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Tell Jenkins where to find the JCasC configuration file
ENV CASC_JENKINS_CONFIG="/var/jenkins_home/casc.yaml"

# Copy the plugin list and install them using the new plugin manager
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Switch to root to install Ansible
USER root

RUN apt-get update && \
    apt-get install -y ansible sshpass python3-pymysql && \
    rm -rf /var/lib/apt/lists/*

# Copy the real jobs into the Jenkins reference directory so they get initialized with proper permissions
COPY --chown=jenkins:jenkins jobs/ /usr/share/jenkins/ref/jobs/

# Copy initialization scripts
COPY --chown=jenkins:jenkins init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/

# Revert to jenkins user
USER jenkins

# Copy the configuration file
COPY --chown=jenkins:jenkins casc.yaml /var/jenkins_home/casc.yaml

# Set default env variable for local testing (Override this in production!)
ENV JENKINS_ADMIN_PASSWORD="MySuperSecretPassword123!"
