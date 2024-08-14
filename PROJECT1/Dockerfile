#FROM amazoncorretto:17.0.8-alpine3.18
    
#EXPOSE 8080
 
#ENV APP_HOME /usr/src/app

#COPY target/*.jar $APP_HOME/app.jar

#WORKDIR $APP_HOME

#CMD ["java", "-jar", "app.jar"]




# Use an appropriate base image
FROM amazoncorretto:17.0.8-alpine3.18

# Expose the port the app runs on
EXPOSE 8080

# Set environment variable for app home
ENV APP_HOME /usr/src/app

# Create the directory in the container
RUN mkdir -p $APP_HOME

# Copy the JAR file from the target directory of the build context to the APP_HOME
COPY target/todo-app-1.0-SNAPSHOT.jar $APP_HOME/app.jar

# Set the working directory
WORKDIR $APP_HOME

# Run the application
CMD ["java", "-jar", "app.jar"]

