# DevOps CI/CD Project with Git, Genkins, SonarQube, Nexus, Docker   

## Step 1. Create AWS Instances for Jenkins, SonarQube and Nexus   

Deploy Scripts :  

* Jenkins Instance 
    * [Jenkins.sh](userData/Jenkins.sh)     
    * OS: Ubuntu22 | ImageID: ami-07ffb2f4d65357b42 
    * Type: t2.small
    * Security Group Settings : Port 80,8080 needs to be accessible  
    * Install Plugins : Sonar Gerrit plugin, SonarQube Scanner for jenkins, SonarQube generic Coverage plugin, Sonar Quality Gates Plugin, Nexus Artifact Uploader, Git Plugin, Pipeline Maven Integration, Build TimeStamp   
* SonarQube Instance 
    * [SonarQube.sh](userData/SonarQube.sh)     
    * OS: Ubuntu22 | ImageID: ami-07ffb2f4d65357b42 
    * Type: t2.medium
    * Security Group Settings : Port 80,9000 needs to be accessible    
* Nexus Instance   
    * [Nexus.sh](userData/Nexus.sh)    
    * OS: CentOS7 | ImageID: ami-0763cf792771fe1bd
    * Type: t2.medium   
    * Security Group Settings : Port 8081 needs to be accessible    
 
## Step 2. Integrate Jenkins with SonarQube     

### Jenkins Configuration   

* Install java-jdk8 

```   
sudo apt install openjdk-8-jdk -y   
```  


__Global Tool Configuration :__      

* Goto `Manage Jenkins > Global Tool Configuration`   
* Configure Java JDK 
    * Set name `OpenJDK8`    
    * Set JAVA_HOME `/usr/lib/jvm/java-8-openjdk-amd64` 
* Configrue Maven
    * Set Name `MAVEN3`  
    * Select `Install automatically` and select version of MAVEN    
* SonarQube Scanner Settings  
    * Set name `Sonar4.7`   
    * Select latest version of sonarqube  


* Go to `Manage Jenkins > Configure System` on `SonarQube Servers` tab enable `Environment Vraiables` and set the name `Sonar` with server ip SonarQube server private ip in the format of `http://private_ip:9000/`.    
* Now Goto SonarQube console and click on upper right corner profile click on `My Account > Security (tab)` give a name, generate token and copy the token.    
* Now again go to `Manage Jenkins > Configure System` on `SonarQube Servers` tab click on `Add` then `Jenkins`, select `secret text` and Scope will be `global` paste the token and give it id and description `Add` and `Save` the settings.    


### SonarQube Configuration    
 
* Generate Secret key    
    * Goto `profile > My Account > Security` then generate  token, set token name `jenkinsToken` and type global.    
* Create webhook    
    * Goto `Administration` and in `Configuration` drop down menu click on `Webhooks`   
    * Click on `Create`, give webhook name, and in url put private ip of jenkins with url `http://private_jenkins_ip:8080/sonarqube-webhook/`  
* Create quality Gate 
    * Goto `Quality Gates` click on `Create Quality Gate`, assign a name 
    * Add condition and choose a matrix like `Bugs` and condition like greater then 60  
* Configure webhook api with secret 

## Step 3. Confiurating Nexus and Jenkins 

## Step 4. Writing Jenkinsfile 

[Jenkinsfile](Jenkinsfile)  

## Step 5. Implementing Pipeline utility for dynamic versioning 

* Read the version in pom.xml and push builds according to that in nexus repository management.  
* Check for snapshot version and put the build on snapshot repo in nexus repository management.  
* Setting nexus repo push code dynamic in Jenkinsfile 

> Note i have tried the Pipeline utilities, but there are some problem, so for Pom.xml read/write use the mvn commandline version.   


# Setp 6. Setup Slack Notification    

* Install Slake   
* Create a new workspace, example `DevOpsCICD`    
* Create a new channel under that workspace, you can also add users emails which you want to include in the channel.   
* Goto `https://api.slack.com/apps` and search `Jenkins CI` app, install it and on the settings page select the chennal name, copy the API_KEY and save the settings.   
* At Jenkins install slack notification plugin  
* Configure Slake plugin `Manage Jenkins > Configure System` look for slake settings  
    * On workspace put the workspace name. Also note that you need to put the name from the slake url example if url is devops-network.slake.com then put devops-network not just devops.  
    * Set credentials 
    * Set chennal neme for example `#jenkinscicd` test connection and apply and save settings.  
* Now we have to put the below code into the Jenkinsfile to send the notification to our slack channel  

```
// Put the below code on the top of the page, outside the pipelines block 
def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger'
]

// Now put the below code after the stages block inside pipelines itself
post {
    always {
        echo 'Slack Notification.'
        slackSend channel: '#jenkinscicd',
            color: COLOR_MAP[currentBuild.currentResult],
            message: "*${currentBuild.currentResult}* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"

    }
}
```

## Step 7. Creatiing Docker Image amd Push it into AWS ECR  

__Objective :__ 

* Build docker image
* Push it to the ECR registry.    
* Deply the docker image into the ECS service.      

__Things Needs to be setup :__     

* Install docker engine on Jenkins server     
    * Add jenkins user to docker group and reboot   
* Install aws cli  
* Create IAM user with ECR permission   
* Create ECR repos in aws   
* Store aws credentials in jenkins    
* Plugins to install :    
    * docker pipeline   
    * aws ecr plugin    
    * aws sdk for credentials    
* Run the pipeline    

__Code samples for the Jenkinsfile pipeline :__   

* Code for setting up global environment variables in Jenkinsfile :   

```    
environment {
    registryCredential = 'ecr:regioncode:CredentialIDinJenkins'
    appRegistry = "RegistryURL/RegistryNAME"
    vprofileRegistry = "RegistryURL"   
}
```    

The above code needs to be in the beginning of the jenkinsfile pipline block.   

* Code to build the images  

```
stage('Build App Image') {
    steps {
        script {
            dockerImage = docker.build(appRegistry + ":$BUILD_NUMBER", "Dockerfile_PATH")
        }
    }
}
```

Put the above code after all the build process.  

Code for the dockerfile which is used to compile the vprofile sample project used through the course :     

```
FROM openjdk:8 AS BUILD_IMAGE
RUN apt update && apt install maven -y
RUN git clone -b vp-docker https://github.com/imranvisualpath/vprofile-repo.git
RUN cd vprofile-repo && mvn install

FROM tomcat:8-jre11

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=BUILD_IMAGE vprofile-repo/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
```

* Code to upload the built docker images 

```
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
```   

__Steps :__   

1. Installing docker engine and aws cli in jenkins server  

```
# docker installation  
$ apt-get update -y  
$ apt-get install ca-certificates curl gnupg lsb-release -y  
$ mkdir -p /etc/apt/keyrings   
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg  
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ chmod a+r /etc/apt/keyrings/docker.gpg   
$ apt update -y
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y  
$ usermod -aG docker jenkins

# aws cli installation  
$ curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"   
$ sudo apt install unzip     
$ unzip awscliv2.zip    
$ ./aws/install 
```   

2. Create new IAM user with below policies :

* AmazonEC2ContainerRegistryFullAccess 
* AmazonECS_FullAccess  

3. Install plugins 

* docker pipeline
* amazon ecr 
* Amazon Web Services SDK :: All  
* CloudBees Docker Build and PublishVersion  

4. Create ECR registry

* Goto ecr console give a tag name like `vprofileimg`, click create and save and note down the url.   

5. Set aws credential

* Goto `Manage Jenkins > Credentials' and add new global credentials and select `aws credentials` kind, provide access key and secret key, give a name like awscreds and save.  


6. Add aws credentials to Jenkinsfile environment variable 

```    
environment {    
    registryCredential = 'ecr:ap-south-1:awscreds'    
    appRegistry = "897003471175.dkr.ecr.ap-south-1.amazonaws.com/vprofileappimg"   
    vprofileRegistry = "https://897003471175.dkr.ecr.ap-south-1.amazonaws.com"   
}   
```   

7. Put the dockerfile location in the Jenkins Image build process  

```   
stage('Build App Image') {
    steps {
        script {
            dockerImage = docker.build(appRegistry + ":$BUILD_NUMBER", ".")
        }
    }
}
```  

> Note: You only have to put the Dockerfile path in your gihub repo not the Dockerfile name itself. Otherwise it will not work. At above example the laset "." represnts that the Dockerfile is in the git repository.   

### Step 8. Deploy Docker Image tyo ECS system   

Some of the docker container hosting platforms are :

* Using docker engine (very much used for local testing and developmentt environment)  
* kubernetes 
    * Standalone kubernetes service, EKS (AWS), AKS (Azure), GKE(GCP), OpenShift (redhat) etc.   

__Steps to setting up ECS service :__   

1. Create an ECS cluster, choose `AWS Fargate (serverless)` as infrastructure, enable `Use Container Insights` in monitoring section and click on create button. For example `vprofile`   
2. Create Task definition: 
    * For example `vprofileTask` and fillup container details (container name and container url from ecr), set the container service port for example 8080 for tomcat.       
    * In next page you can change the App environment, hardware specification etc.  
    * In next page you can review the specification and click on `Create` button.   
    * Also note that this step only create the task definition, and does not create task itiself, To create the task we have to combine the cluster with task definition and create a service in the cluster
    * Now to combine task definition with cluster, we need to create service in cluster. For that goto services tab and click on `create`
    * At `Service Creation` in `Deployment Configuration` choose "Application type" as service, select the task definition name in "Family", set a service name for example "vprofileappsvc", set the number of desired task as (set 1 for testing)
    * On load balancer set application load balancer, select `create a new load balancer`, set the load balancer name, create a new listener and set port 80, create a new target group, set name, set health check url (in my case i use `/login`) 
    * In networking tab create a new `Security Group` for example name `vproapp-ecs-sg` and add rules for example protocol:http, source:anywhere and click on "Create" button and wait some time for creation. 
    * Now goto "EC2 > Target group" and check for the health of created  service, which shows unhealthy service, then goto "Health checks" tab and edit the configuration, expand "Advanced health check settings" and override the port according to the service running on your container and adjust the "health threshold" (set it 2) and "Save the changes".    
    * Now goto seucirty group and modify inbound rules to allow port 8080 from anywhere for both ipv4/ipv6. 
    * Now goto target group and check the health, if the service is healthy then you can access the service by "ECS > clusters > cluster_name > services tab" click on running service and click on networking tab, here in DNS section you will find the url of load balancer to access the site/service. Also remember the service is running on port 8080 but the load balancer is listening on port 80, so you can access the service on port 80.  
    * To get the direct ip of service goto "ECS > clusters > cluster_name > tasks tab", then click on the running tasks and on the cionfiguration section you will find the public ip of that container.  


__Steps to add ECS service automation in Jenkinsfile__     

1. Set environment variable on Jenkinsfile  

```   
environment {
    cluster = ""
    service = ""
}  
```   

For that we have to create ECS cluster and ECS service  

2. Add code on Jenkinsfile to deploy the image from ecr into ecs

```
stage('Deploy to ECS') {
    steps {
        withAWS(credentials: 'awscreds', region: 'us-east-2') {
            sh 'aws ecs update-service --cluster ${cluster} --service ${service} --force-new-deployment'
        }
    }
}
```

> Note: We also need to install a plugin "Pipeline: AWS Steps"    


