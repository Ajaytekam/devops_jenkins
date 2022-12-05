pipeline {
    agent any

    tools {
        maven "MAVEN3"
        jdk "OracleJDK8"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Ajaytekam/devops_jenkins.git'
            }
        }

        stage('Unit Testing') {
            steps{
                sh 'mvn test'
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
                    archiveArtifacts artifacts: '**/target/*.war'i
                }
            }
        }
    }
}
