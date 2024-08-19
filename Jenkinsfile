pipeline {
    agent { label 'Dev' }
     tools {
       maven 'maven3'                
       }
    environment {
        SCANNER_HOME = tool name: 'sonar-scanner'
    }
    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/s7testar/Dev.git'
            }
        }
        stage('Compile') {
            steps {
                dir('PROJECT1') {
                    sh 'mvn compile'
                }
            }
        }
        stage('Unit Test') {
            steps {
                dir('PROJECT1') {
                    sh 'mvn test'
                }
            }
        }
        stage('Trivy FS Scan') {
            steps {
                dir('PROJECT1') {
                    sh 'trivy fs --format table -o fs.html .'
                }
            }
        }
        stage('Sonar Analysis') {
            steps {
                dir('PROJECT1') {
                    withSonarQubeEnv('sonar') {
                        sh '''$SCANNER_HOME/bin/sonar-scanner -Dsonar.projectKey=taskmaster -Dsonar.projectName=taskmaster -Dsonar.java.binaries=target -Dsonar.host.url=http://192.168.56.11:9000'''
                    }
                }
            }
        }
        stage('Build Application') {
            agent {
                label "docker"
            }
            steps {
                dir('PROJECT1') {
                    withMaven(globalMavenSettingsConfig: 'settings-maven', maven: 'maven3') {
                        sh 'mvn deploy'
                //      sh 'mvn clean package'
                    }
                }
            }
        }
        stage('Docker Build & Tag') {
            agent {
                label 'docker'
            }
            steps {
                script {
                    dir('PROJECT1') {
                        withDockerRegistry(credentialsId: 'docker_login', toolName: 'docker') {
                            sh 'docker build -t attamegnon/dev:${JOB_NAME}_v${BUILD_NUMBER} -f Dockerfile .'
                        }
                    }
                }
            }
        }
        stage('Trivy image Scan') {
            agent {
                label 'docker'
            }
            steps {
           //     dir('PROJECT1') {
                sh 'trivy image --format table -o image.html attamegnon/dev:${JOB_NAME}_v${BUILD_NUMBER}'
                }
            }
   //     }
        stage('Docker Push') {
            agent {
                label 'docker'
            }
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker_login', toolName: 'docker') {
                        sh 'docker push attamegnon/dev:${JOB_NAME}_v${BUILD_NUMBER}'
                    }
                }
            }
        }
        stage('k8 deply') {
            agent {
                label 'docker'
            }
            steps {
                dir('PROJECT1') {
                withKubeConfig(caCertificate: '', clusterName: 'master-node ', contextName: '', credentialsId: 'k8token', namespace: 'taskmaster', restrictKubeConfigAccess: false, serverUrl: 'https://192.168.56.11:6443') {
                    sh "kubectl apply -f deployment-service.yml"
                    sleep 30
                }
              }
           }
        }
         stage('Verify deployment') {
            agent {
                label 'docker'
            }
            steps {
                
                withKubeConfig(caCertificate: '', clusterName: 'master-node ', contextName: '', credentialsId: 'k8token', namespace: 'taskmaster', restrictKubeConfigAccess: false, serverUrl: 'https://192.168.56.11:6443') {
                    sh "kubectl get pods -n taskmaster"
                    sh "kubectl get svc -n taskmaster"
                }
            }
         }
    }
                
}




