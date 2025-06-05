node {
    def mvnHome = tool 'maven_3.9.9' // Replace with your Maven installation name
    def sonarScannerHome = tool 'SonarQube Scanner' // Replace with your SonarQube Scanner installation name

    stage('Git Clone') {
        checkout([$class: 'GitSCM',
                  branches: [[name: '*/feature-1.1']],
                  userRemoteConfigs: [[url: 'https://github.com/betawins/sabear_simplecutomerapp.git']]])
    }

    stage('SonarQube Analysis') {
        withSonarQubeEnv('My SonarQube Server') { // Replace with your SonarQube server name
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
            nexusUrl: 'http://107.23.112.78:8081', // Replace with your Nexus URL
            groupId: 'com.betawins',
            version: '1.1',
            repository: 'maven-releases', // Replace with your repository name
            credentialsId: 'nexus-credentials', // Replace with your credentials ID
            artifacts: [
                [artifactId: 'sabear_simplecutomerapp',
                 classifier: '',
                 file: 'target/sabear_simplecutomerapp.war',
                 type: 'war']
            ]
        )
    }

    stage('Slack Notification') {
        slackSend(channel: '#build-status', // Replace with your Slack channel
                  color: 'good',
                  message: "Build ${env.BUILD_NUMBER} completed successfully. <${env.BUILD_URL}|Open>")
    }

    stage('Deploy on Tomcat') {
        deploy adapters: [tomcat8(credentialsId: 'tomcat-credentials', // Replace with your credentials ID
                                  path: '', 
                                  url: 'http://tomcat.example.com:8080')], // Replace with your Tomcat URL
               contextPath: '/sabear',
               war: 'target/sabear_simplecutomerapp.war'
    }
}
