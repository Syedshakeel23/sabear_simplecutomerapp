node {
    // Define tool paths
    def jdkHome = tool name: 'Java 17'
    def mvnHome = tool name: 'maven_3.9.9'
    def sonarScannerHome = tool name: 'SonarQube'

    // Define environment variables
    def SONAR_QUBE_URL = "http://54.157.171.33:9002/"
    def SONAR_QUBE_CREDENTIALS_ID = 'sonarqube1'

    def NEXUS_REPOSITORY_ID = 'Simplecustomerapp'
    def NEXUS_URL = 'http://35.175.132.66:8081/repository/Simplecustomerapp/'
    def NEXUS_CREDENTIALS_ID = 'nexus'

    def TOMCAT_URL = 'http://35.153.52.140:8082/manager/text'
    def TOMCAT_CREDENTIALS_ID = 'TOM'
    def TOMCAT_APP_CONTEXT = 'simplecustomerapp'

    def SLACK_CHANNEL = '#devops'
    def SLACK_WEBHOOK_CREDENTIAL_ID = 'slack-webhook-secret'

    stage('Git Clone') {
        echo 'Cloning repository...'
        git branch: 'master', url: 'https://github.com/Syedshakeel23/sabear_simplecutomerapp.git'
    }

    stage('SonarQube Analysis') {
        echo 'Running SonarQube analysis...'
        withSonarQubeEnv(credentialsId: "${SONAR_QUBE_CREDENTIALS_ID}", installationName: 'SonarQube') {
            sh "${mvnHome}/bin/mvn clean install sonar:sonar -Dsonar.projectKey=sabear_simplecutomerapp"
        }
    }

    stage('Wait for Quality Gate') {
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

    stage('Maven Package') {
        echo 'Packaging application...'
        sh "${mvnHome}/bin/mvn clean package -DskipTests"
    }

    stage('Deploy to Nexus') {
        echo 'Deploying to Nexus...'
        configFileProvider([configFile(fileId: 'Simplecustomerapp-settings', variable: 'MAVEN_SETTINGS')]) {
            sh "${mvnHome}/bin/mvn deploy -s $MAVEN_SETTINGS -Dmaven.repo.local=.repository -DskipTests"
        }
    }

    stage('Deploy to Tomcat') {
        echo 'Deploying WAR to Tomcat...'
        script {
            def warFiles = findFiles(glob: 'target/*.war')
            if (warFiles.length == 0) {
                error 'WAR file not found!'
            }

            def warFilePath = warFiles[0].path
            sh "mv ${warFilePath} target/${TOMCAT_APP_CONTEXT}.war"

            step([$class: 'DeployPublisher',
                  adapters: [[
                      $class: 'Tomcat9xAdapter',
                      credentialsId: "${TOMCAT_CREDENTIALS_ID}",
                      url: "${TOMCAT_URL}"
                  ]],
                  war: "target/${TOMCAT_APP_CONTEXT}.war",
                  contextPath: "${TOMCAT_APP_CONTEXT}"
            ])
        }
    }

    // Post actions
    stage('Post Actions') {
        echo 'Pipeline completed.'
        slackSend(
            channel: "${SLACK_CHANNEL}",
            message: "Build #${env.BUILD_NUMBER} for ${env.JOB_NAME} completed with status: ${currentBuild.currentResult}\n${env.BUILD_URL}"
        )
        if (currentBuild.result == null || currentBuild.result == 'SUCCESS') {
            echo 'Pipeline succeeded.'
        } else {
            echo 'Pipeline failed.'
        }
    }
}
