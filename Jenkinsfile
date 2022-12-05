pipeline {
    agent any

    tools {
        maven "MAVEN3"
        jdk "OpenJDK11"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Ajaytekam/devops_jenkins.git'
            }
        }

        stage('Unit Testing') {
            steps{
                sh 'mvn -X test'
            }
        }

        stage('Integration Testing') {
            steps{
                sh 'mvn verify -DskipUnitTests'  
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean install -DskipTests'
            }

            post {
                success {
                    echo 'Now archiving it...'
                    archiveArtifacts artifacts: '**/target/*.war'
                }
            }
        }

        stage('Checkstyle Analysis') {
            steps {
                sh 'mvn checkstyle:checkstyle'
            }
        }

        stage('SonarQube Code Analysis') {

            environment {
                scannerHome = tool 'Sonar4.7'
            }

            steps {
                script {
                    withSonarQubeEnv(credentialsId: 'sonar-api') {
                        //sh 'mvn clean package sonar:sonar'
                        sh '''${scannerHome}/bin/sonar-scanner -X \
                        -Dsonar.projectKey=vprofile \
                        -Dsonar.projectName=vprofile \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src/ \
                        -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                       -Dsonar.junit.reportsPath=target/surefire-reports/ \
                       -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                       -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
                       '''
                    }
                }
            }
        }
    }
}
