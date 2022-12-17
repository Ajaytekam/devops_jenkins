def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger'
]

pipeline {
    agent any

    environment {
        registryCredential = 'ecr:ap-south-1:awscreds'
        appRegistry = "897003471175.dkr.ecr.ap-south-1.amazonaws.com/vprofileappimg"
        vprofileRegistry = "https://897003471175.dkr.ecr.ap-south-1.amazonaws.com"   
    }

    tools {
        maven "MAVEN3"
        jdk "OpenJDK8"
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'Dev', url: 'https://github.com/Ajaytekam/devops_jenkins.git'
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
                        sh '''export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64;
                        ${scannerHome}/bin/sonar-scanner -X \
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

        stage('SonarQube Quality Gate Status') {
            steps{
                timeout(time: 1, unit: 'HOURS') {
                    // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
                    // true = set pipeline to UNSTABLE, false = don't
                    //waitForQualityGate abortPipeline: true
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonar-api'  
                }
            }
        }


        stage('Upload war file to nexus') {
            steps{
                script{

                    def version = sh script: 'mvn help:evaluate -Dexpression=project.version -q -DforceStdout', returnStdout: true
                    def artifactId = sh script: 'mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout', returnStdout: true
                    def packaging = sh script: 'mvn help:evaluate -Dexpression=project.packaging -q -DforceStdout', returnStdout: true

                    nexusArtifactUploader artifacts: [
                        [
                            artifactId: "${artifactId}", 
                            classifier: '', 
                            file: "target/${artifactId}-${version}.war",
                            type: "${packaging}"
                        ]
                    ], 
                    credentialsId: 'nexus-auth2', 
                    groupId: 'com.visualpathit', 
                    nexusUrl: '172.31.9.55:8081', 
                    nexusVersion: 'nexus3', 
                    protocol: 'http', 
                    repository: 'new-repo-release', 
                    version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}-${version}"

                }
            }
        }


        stage('Build App Image') {
            steps {
                script {
                    dockerImage = docker.build(appRegistry + ":$BUILD_NUMBER", ".")
                }
            }
        }

        stage('Upload app image') {
            steps {
                script {
                    docker.withRegistry( vprofileRegistry, registryCredential ) {
                        dockerImage.push("$BUILD_NUMBER")    
                        dockerImage.push("latest")   
                    }
                }
            }
        }
        

    }

    post {
        always {
            echo 'Slack Notification.'
            slackSend channel: '#jenkinscicd',
                color: COLOR_MAP[currentBuild.currentResult],
                message: "*${currentBuild.currentResult}* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"

        }
    }
}
