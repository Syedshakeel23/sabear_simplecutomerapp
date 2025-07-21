FROM tomcat:9.0-jdk17

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Download the WAR file from Nexus into the Tomcat webapps directory
ADD http://34.203.202.65:8081/repository/Simplecustomerapp/com/javatpoint/SimpleCustomerApp/1.0.0-SNAPSHOT/SimpleCustomerApp-1.0.0-20250721.185847-1.war /usr/local/tomcat/webapps/SimpleCustomerApp.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
