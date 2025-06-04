// Jenkinsfile for sabear_simplecutomerapp CI/CD Pipeline

pipeline {
    agent any // Or specify a specific agent label if you have dedicated build agents

    environment {
        // --- SonarQube Configuration ---
        SONAR_SCANNER_HOME = tool 'SonarQubeScanner' // Name of the SonarQube Scanner tool configured in Jenkins
        SONAR_QUBE_URL = "http://54.157.171.33:9002/" // Replace with your SonarQube URL
        // Use a credential for the SonarQube token
        SONAR_QUBE_CREDENTIALS_ID = 'Sonaqube' // ID of the secret text credential in Jenkins

        // --- Nexus Configuration ---
        NEXUS_REPOSITORY_ID = 'Simplecustomerapp' // Or 'your-nexus-snapshots' depending on your artifact type
        NEXUS_URL = 'http://35.175.132.66:8081/repository/Simplecustomerapp/' // Replace with your Nexus URL
        NEXUS_CREDENTIALS_ID = 'nexus' // ID of the username/password credential in Jenkins

        // --- Tomcat Deployment Configuration ---
        TOMCAT_URL = 'http://35.153.52.140:8082/manager' // Tomcat Manager URL
        TOMCAT_CREDENTIALS_ID = 'TOM' // ID of the username/password credential for Tomcat manager
        TOMCAT_APP_CONTEXT = 'simplecustomerapp' // Context path for your application on Tomcat

        // --- Slack Notification Configuration ---
        SLACK_CHANNEL = '#devops' // Replace with your Slack channel
        SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/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' // Replace with your Slack webhook URL
        // It's better to store this as a secret text credential in Jenkins and reference it.
        // For example:
        // SLACK_WEBHOOK_URL_CREDENTIAL_ID = 'slack-webhook-secret'
    }

    tools {
        // These refer to the names configured in Manage Jenkins -> Global Tool Configuration
        jdk 'Java 17' // e.g., 'Java 11'
        maven 'MVN_HOME' // e.g., 'Maven 3.8.6'
    }

    stages {
        stage('Git Clone') {
            steps {
                echo 'Cloning repository...'
                git branch: 'master', url: 'https://github.com/Syedshakeel23/sabear_simplecutomerapp.git'
                // If your repository is private, add credentialsId: 'your-git-credentials-id'
            }
        }

        stage('SonarQube Integration') {
            steps {
                echo 'Performing SonarQube analysis...'
                withSonarQubeEnv(credentialsId: "${env.SONAR_QUBE_CREDENTIALS_ID}", installationName: 'SonarQubeScanner') { // Use the SonarQubeScanner tool name
                    sh "${tool 'Maven'}/bin/mvn clean install sonar:sonar " +
                       "-Dsonar.projectKey=sabear_simplecutomerapp " +
                       "-Dsonar.host.url=${env.SONAR_QUBE_URL} " +
                       "-Dsonar.login=${env.SONAR_QUBE_CREDENTIALS_ID}" // SonarQube Scanner for Jenkins handles the token directly
                }
            }
            post {
                always {
                    script {
                        def qualityGateStatus = waitForQualityGate() // Requires SonarQube Plugin >= 2.6
                        if (qualityGateStatus.status != 'OK') {
                            error "SonarQube Quality Gate failed: ${qualityGateStatus.status}"
                        }
                    }
                }
            }
        }

        stage('Maven Compilation') {
            steps {
                echo 'Compiling and packaging the application...'
                sh "${tool 'Maven'}/bin/mvn clean package -DskipTests"
            }
        }

        stage('Nexus Artifactory') {
            steps {
                echo 'Deploying artifact to Nexus...'
                withCredentials([usernamePassword(credentialsId: "${env.NEXUS_CREDENTIALS_ID}", passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                    sh "${tool 'Maven'}/bin/mvn deploy -DaltDeploymentRepository=${env.NEXUS_REPOSITORY_ID}::default::${env.NEXUS_URL} -Dmaven.repo.local=.repository -DskipTests"
                }
            }
        }

        stage('Deploy On Tomcat') {
            steps {
                echo 'Deploying to Tomcat...'
                // Assuming the war file is generated in target/
                script {
                    def warFile = findFiles(glob: 'target/*.war')[0]
                    if (warFile) {
                        deploy adapters: [
                            [
                                credentialsId: "${env.TOMCAT_CREDENTIALS_ID}",
                                contextPath: "${env.TOMCAT_APP_CONTEXT}",
                                war: warFile.path
                            ]
                        ], publishers: [[url: "${env.TOMCAT_URL}"]]
                    } else {
                        error 'WAR file not found in target/ directory!'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
            // Send Slack notification on pipeline completion (success or failure)
            slackSend(channel: "${env.SLACK_CHANNEL}", message: "Project: ${env.JOB_NAME}\nBuild Number: ${env.BUILD_NUMBER}\nStatus: ${currentBuild.result}\nURL: ${env.BUILD_URL}")
        }
        success {
            echo 'Pipeline succeeded!'
            // You can add more specific success notifications here if needed
        }
        failure {
            echo 'Pipeline failed!'
            // You can add more specific failure notifications here if needed
            slackSend(channel: "${env.SLACK_CHANNEL}", message: "FAILURE: Project: ${env.JOB_NAME}, Build: ${env.BUILD_NUMBER}, URL: ${env.BUILD_URL}", color: 'danger')
        }
    }
}
