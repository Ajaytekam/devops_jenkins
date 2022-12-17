FROM openjdk:8 AS BUILD_IMAGE
RUN apt update && apt install maven -y
RUN git clone https://github.com/Ajaytekam/docker-containerization-project.git
RUN cd docker-containerization-project && mvn install 

FROM tomcat:8-jre11
LABEL "Project"="Vprofile"
LABEL "Author"="Ajay Tekam"
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=BUILD_IMAGE docker-containerization-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]  
WORKDIR /usr/local/tomcat/
VOLUME /usr/local/tomcat/webapps
