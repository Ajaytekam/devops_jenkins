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

## Step 6. Creatiing Multi Container Docker Setup

