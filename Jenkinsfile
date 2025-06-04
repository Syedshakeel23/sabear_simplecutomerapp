pipeline {
    agent any

    environment {
        // --- SonarQube Configuration ---
        SONAR_SCANNER_HOME = tool 'SonarQube'
        SONAR_QUBE_URL = "http://54.157.171.33:9002/"
        SONAR_QUBE_CREDENTIALS_ID = 'sonarqube1'

        // --- Nexus Configuration ---
        NEXUS_REPOSITORY_ID = 'Simplecustomerapp'
        NEXUS_URL = 'http://35.175.132.66:8081/repository/Simplecustomerapp/'
        NEXUS_CREDENTIALS_ID = 'nexus'

        // --- Tomcat Deployment Configuration ---
        TOMCAT_URL = 'http://35.153.52.140:8082/manager/text'
        TOMCAT_CREDENTIALS_ID = 'TOM'
        TOMCAT_APP_CONTEXT = 'simplecustomerapp'

        // --- Slack Configuration ---
        SLACK_CHANNEL = '#devops'
        SLACK_WEBHOOK_CREDENTIAL_ID = 'slack-webhook-secret'
    }

    tools {
        jdk 'Java 17'
        maven 'maven_3.9.9'
    }

    stages {
        stage('Git Clone') {
            steps {
                echo 'Cloning repository...'
                git branch: 'master', url: 'https://github.com/Syedshakeel23/sabear_simplecutomerapp.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv(credentialsId: "${env.SONAR_QUBE_CREDENTIALS_ID}", installationName: 'SonarQube') {
                    sh "${tool 'maven_3.9.9'}/bin/mvn clean install sonar:sonar -Dsonar.projectKey=sabear_simplecutomerapp"
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                echo 'Waiting for SonarQube Quality Gate result...'
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Maven Package') {
            steps {
                echo 'Compiling and packaging the application...'
                sh "${tool 'maven_3.9.9'}/bin/mvn clean package -DskipTests"
            }
        }

        stage('Deploy to Nexus') {
            steps {
                echo 'Deploying artifact to Nexus...'
                withCredentials([usernamePassword(credentialsId: "${env.NEXUS_CREDENTIALS_ID}", usernameVariable: 'NEXUS_USERNAME', passwordVariable: 'NEXUS_PASSWORD')]) {
                    sh "${tool 'maven_3.9.9'}/bin/mvn deploy -DaltDeploymentRepository=${env.NEXUS_REPOSITORY_ID}::default::${env.NEXUS_URL} -Dmaven.repo.local=.repository -DskipTests"
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo 'Deploying WAR to Tomcat...'
                script {
                    def warFiles = findFiles(glob: 'target/*.war')
                    if (warFiles.length == 0) {
                        error 'WAR file not found in target/ directory!'
                    }
                    deploy adapters: [[
                        credentialsId: "${env.TOMCAT_CREDENTIALS_ID}",
                        contextPath: "${env.TOMCAT_APP_CONTEXT}",
                        war: warFiles[0].path
                    ]], publishers: [[url: "${env.TOMCAT_URL}"]]
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
            slackSend(
                channel: "${env.SLACK_CHANNEL}",
                message: "Project: ${env.JOB_NAME}\nBuild Number: ${env.BUILD_NUMBER}\nStatus: ${currentBuild.result ?: 'SUCCESS'}\nURL: ${env.BUILD_URL}"
            )
        }
        success {
            echo 'Pipeline succeeded!'
            slackSend(
                channel: "${env.SLACK_CHANNEL}",
                message: "SUCCESS: ${env.JOB_NAME} Build: ${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}",
                color: 'good'
            )
        }
        failure {
            echo 'Pipeline failed!'
            slackSend(
                channel: "${env.SLACK_CHANNEL}",
                message: "FAILURE: ${env.JOB_NAME} Build: ${env.BUILD_NUMBER}\nURL: ${env.BUILD_URL}",
                color: 'danger'
            )
        }
    }
}
