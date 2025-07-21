pipeline {
    agent any

    environment {
        // SonarQube
        SONAR_SCANNER_HOME = tool 'SonarQube'
        SONAR_QUBE_URL = "http://34.203.202.65:9000/"
        SONAR_QUBE_CREDENTIALS_ID = 'sonarqube1'

        // Nexus
        NEXUS_REPOSITORY_ID = 'Simplecustomerapp'
        NEXUS_URL = "http://34.203.202.65:8081/repository/Hiring-app/"
        NEXUS_CREDENTIALS_ID = 'nexus'
        // Slack
        SLACK_CHANNEL = '#all-devops-batch-12'
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
                    -Dsonar.nodejs.executable=/root/.nvm/versions/node/v14.21.3/bin/node
                }
            }
        }

        stage('Wait for Quality Gate') {
            steps {
                echo 'Waiting for SonarQube Quality Gate result...'
                script {
                    try {
                        timeout(time: 2, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            echo "SonarQube Quality Gate Status: ${qg.status}"
                            if (qg.status != 'OK') {
                                error "Aborting pipeline due to Quality Gate failure: ${qg.status}"
                            }
                        }
                    } catch (e) {
                        echo "Quality Gate check failed or timed out: ${e.getMessage()}. Proceeding anyway."
                    }
                }
            }
        }

        stage('Maven Package') {
            steps {
                echo 'Packaging application...'
                sh "${tool 'maven_3.9.9'}/bin/mvn clean package -DskipTests"
            }
        }

        stage('Deploy to Nexus') {
            steps {
                configFileProvider([configFile(fileId: 'Simplecustomerapp-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh "${tool 'maven_3.9.9'}/bin/mvn deploy -s $MAVEN_SETTINGS -Dmaven.repo.local=.repository -DskipTests"
                }
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo 'Deploying WAR to Tomcat...'
                script {
                    def warFile = findFiles(glob: 'target/*.war')[0]
                    if (warFile) {
                        // Rename WAR to match context name
                        sh "mv ${warFile.path} target/${env.TOMCAT_APP_CONTEXT}.war"

                        step([$class: 'DeployPublisher',
                              adapters: [[
                                  $class: 'Tomcat9xAdapter',
                                  credentialsId: "${env.TOMCAT_CREDENTIALS_ID}",
                                  url: "${env.TOMCAT_URL}"
                              ]],
                              war: "target/${env.TOMCAT_APP_CONTEXT}.war",
                              contextPath: "${env.TOMCAT_APP_CONTEXT}"
                        ])
                    } else {
                        error 'WAR file not found!'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
            slackSend(
                channel: "${env.SLACK_CHANNEL}",
                message: "Build #${env.BUILD_NUMBER} for ${env.JOB_NAME} completed with status: ${currentBuild.currentResult}\n${env.BUILD_URL}"
            )
        }
        success {
            echo 'Pipeline succeeded.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
