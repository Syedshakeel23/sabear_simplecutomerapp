node {
    def mvnHome = tool 'maven_3.9.9' // Replace with your Maven installation name
    def sonarScannerHome = tool 'SonarQube' // Replace with your SonarQube Scanner installation name

    stage('Git Clone') {
        checkout([$class: 'GitSCM',
                  branches: [[name: '*/feature-1.1']],
                  userRemoteConfigs: [[url: 'https://github.com/Syedshakeel23/sabear_simplecutomerapp.git']]])
    }

    stage('SonarQube Analysis') {
        withSonarQubeEnv('SonarQube') { // Replace with your SonarQube server name
            sh "${mvnHome}/bin/mvn clean verify sonar:sonar"
        }
    }

    stage('Maven Compilation') {
        sh "${mvnHome}/bin/mvn clean package"
    }

    stage('Nexus Artifactory') {
        // Upload the WAR file to Nexus
        nexusArtifactUploader(
            nexusVersion: 'nexus3',
            protocol: 'http',
            nexusUrl: '107.23.112.78:8081', // Replace with your Nexus URL
            groupId: 'com.javatpoint',
            version: '${BUILD_NUMBER}-SNAPSHOT',
            repository: 'Simplecustomerapp', // Replace with your repository name
            credentialsId: 'NEXUS', // Replace with your credentials ID
            artifacts: [
                [artifactId: 'SimpleCustomerApp',
                 classifier: '',
                 file: 'target/SimpleCustomerApp-${BUILD_NUMBER}-SNAPSHOT.war',
                 type: 'war']
            ]
        )
    }

    stage('Slack Notification') {
        slackSend(channel: 'devops', // Replace with your Slack channel
                  color: 'good',
                  message: "Build ${env.BUILD_NUMBER} completed successfully. <${env.BUILD_URL}|Open>")
    }
   
    stage('Rename WAR') {
    // no 'steps' block here in Scripted Pipeline
        sh 'cp target/SimpleCustomerApp-${BUILD_NUMBER}-SNAPSHOT.war target/sabear.war'
}
    stage('Deploy on Tomcat') {
        deploy adapters: [tomcat9(credentialsId: 'TOM', // Replace with your credentials ID
                                  path: '', 
                                  url: 'http://100.25.205.41:8082')], // Replace with your Tomcat URL
               contextPath: '/sabear',
               war: 'target/sabear.war'
    }
}
