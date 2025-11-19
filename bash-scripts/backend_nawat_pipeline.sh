def APPLICATION_NAME = "${params.APPLICATION_NAME}"
def K8S_NAME_SPACE = "${params.K8S_NAME_SPACE}"
def SKIP_TEST_CASES = "${params.SKIP_TEST_CASES}"
def SKIP_DEPENDENCY_CHECK = "${params.SKIP_DEPENDENCY_CHECK}"
def SKIP_JAVADOCK = "${params.SKIP_JAVADOCK}"
def SKIP_OBFUSCATION = "${params.SKIP_OBFUSCATION}"
def MAVEN_ARG = ''
def GIT_REPO_URL = "${params.GIT_REPO_URL}"
def GIT_TAG = "${params.GIT_TAG}"
def GIT_BRANCH = "${params.GIT_BRANCH}"
def DOCKER_REGISTRY = "${params.DOCKER_REGISTRY}"
def $DOCKER_USER = "${params.DOCKER_REGISTRY}"
def IMAGE_TAG = "${GIT_BRANCH}_${GIT_TAG}"
def UPGRADE_DATABASE = "${params.UPGRADE_DATABASE}"
def MYSQL_CLUSTER = "${params.MYSQL_CLUSTER}"
def DATABSE_NAME = "${params.DATABSE_NAME}"
def MYSQL_PORT = "6446"
def MYSQL_PASS = ''
def SQL_FILE_NAME = "${params.SQL_FILE_NAME}"
def MYSQL_NAMESPACE = ''
def GIT_CRED = 'JENKINS_GIT_CRED'
def DEPLOYMENT_GIT_URL = 'https://github.com/your-org/platform-deployment.git'
def RECIPIENT_MAIL = "${params.RECIPIENT_MAIL}"
def FAILED_STAGE = ''


def deployApp(APPLICATION_NAME, IMAGE_TAG, DOCKER_REGISTRY, K8S_NAME_SPACE) {

    // Check if the deployment exists
    
     def deploymentExists = sh(script: "helm -n ${K8S_NAME_SPACE} status ${APPLICATION_NAME}-service", returnStatus: true) == 0

        if (deploymentExists) {
                sh "helm upgrade --set image.repository=${DOCKER_REGISTRY}/${APPLICATION_NAME}-service,image.tag=${IMAGE_TAG} ${APPLICATION_NAME}-service . -n ${K8S_NAME_SPACE}"

        } else {
                sh "helm install --set image.repository=${DOCKER_REGISTRY}/${APPLICATION_NAME}-service,image.tag=${IMAGE_TAG} ${APPLICATION_NAME}-service . -n ${K8S_NAME_SPACE}"

        }

}

def verifyDeployment(APPLICATION_NAME, K8S_NAME_SPACE){

//    def pod_name = sh(script: "kubectl get pods -n ${K8S_NAME_SPACE} -l app.kubernetes.io/instance=${APPLICATION_NAME}-service --output=jsonpath='{range .items[*]}{.metadata.name}' --kubeconfig=${KUBECONFIG_FILE}", returnStdout: true).trim()
 //   kubectl -n ${K8S_NAME_SPACE} wait --for=condition=ready --timeout=180s pod/${pod_name} --kubeconfig=${KUBECONFIG_FILE}
   def deploymentSucced = sh(script: "kubectl -n ${K8S_NAME_SPACE} rollout status deploy/${APPLICATION_NAME}-service --timeout=300s ", returnStatus: true) == 0

    if (deploymentSucced) {
        return deploymentSucced
    } else {
       // echo "No matching pods found for deployment ${APPLICATION_NAME}"
        return false
    }
}



// Uses Declarative syntax to run commands inside a container.
pipeline {
agent {
  kubernetes {
    defaultContainer 'maven'
    yaml '''
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
    - name: maven
      image: maven:3.9.9-eclipse-temurin-21-alpine
      command:
        - /bin/cat
      tty: true
    - name: tools
      image: gcr.io/YOUR_PROJECT/jenkins-agent-tools:latest
      imagePullPolicy: IfNotPresent
      command:
        - /bin/cat
      tty: true
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command:
        - /busybox/cat
      tty: true
      volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker/kaniko-secret.json
          subPath: kaniko-secret.json
  volumes:
    - name: kaniko-secret
      secret:
        secretName: kaniko-secret
'''
  }
}



  environment {
   // DOCKER_CRED=credentials('FAIZAN_DOCKER_HUB_ACCESS')
    CONTAINER_IMAGE = "${DOCKER_REGISTRY}/${APPLICATION_NAME}-service:${GIT_BRANCH}_${GIT_TAG}"

  }
    stages {
        
        
        stage('Checkout') {
          steps {
              container(name: 'tools') {
                    script {
                    // checkout([$class: 'GitSCM',
                    //           branches: [[name: 'refs/tags/' + "${GIT_TAG}",]],
                    //           doGenerateSubmoduleConfigurations: false,
                    //           extensions: [[$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: true]],
                    //           submoduleCfg: [],
                    //           userRemoteConfigs: [[url: "${GIT_REPO_URL}", credentialsId: "${GIT_CRED}"]]])
                      
                     
                      
                        def gitconfigContent = """
                                                [user]
                                                    email = devops@example.com
                                                    name = cicd-automation-bot
                                                [safe]
                                                    directory = *
                                                [http]
                                                        postBuffer = 157286400
                                                        version = HTTP/1.1                                                            
                                                    """
                            writeFile file: ".gitconfig", text: gitconfigContent   
                            withCredentials([gitUsernamePassword(credentialsId: "${GIT_CRED}", gitToolName: 'Default')]) {
                                sh """
                                  cp .gitconfig /root/  
                                  git clone --filter=blob:none ${GIT_REPO_URL} -b ${GIT_TAG} --depth 1 --single-branch ${APPLICATION_NAME}
                                  chown -R 1000:1000 ${APPLICATION_NAME}
                                """ 
                            } 
                          FAILED_STAGE=env.STAGE_NAME  
                        }
                        
                        
                
              }


               

            }
        }


     stage("Build & SonarQube analysis") {
    steps {
        container(name: 'maven') {
            script {
                if (APPLICATION_NAME == 'cmp') {
                    // Logic for cmp application
                    dir("${APPLICATION_NAME}/Backend/management-service") {
                        withSonarQubeEnv('SonarQube') {
                            if (SKIP_TEST_CASES == 'true') { MAVEN_ARG += " -DskipTests=true" }
                            if (SKIP_OBFUSCATION == 'true') { MAVEN_ARG += " -Dproguard.skip=true" }
                            if (SKIP_JAVADOCK == 'true') { MAVEN_ARG += " -Dmaven.javadoc.skip=true" }
                            if (SKIP_DEPENDENCY_CHECK == 'true') { MAVEN_ARG += " -Ddependency-check.skip=true" }

                            echo "MAVEN ARGS: ${MAVEN_ARG}"

                            configFileProvider([configFile(fileId: 'maven_settings_xml', targetLocation: '/home/jenkins/agent/workspace/', variable: 'MAVEN_SETTINGS')]) {
                                sh "mvn -gs ${MAVEN_SETTINGS} clean install -N ${MAVEN_ARG}"
                                sh "mvn -gs ${MAVEN_SETTINGS} clean install ${MAVEN_ARG}"
                            }

                            sh """
                                cd target/docker/
                                chmod -R 755 *  
                                if [[ -f 'run.sh' ]]; then
                                  sed -i -e "s/\\r//g" run.sh
                                fi
                                tar -czf ${APPLICATION_NAME}.tar * 
                                mv ../docker /home/jenkins/agent/workspace/backend_pipeline/
                            """
                        }
                        FAILED_STAGE = env.STAGE_NAME
                    }
                } else {
                    // Logic for other applications
                    dir("${APPLICATION_NAME}/Backend/") {
                        if (SKIP_TEST_CASES == 'true') { MAVEN_ARG += " -DskipTests=true" }
                        if (SKIP_OBFUSCATION == 'true') { MAVEN_ARG += " -Dproguard.skip=true" }
                        if (SKIP_JAVADOCK == 'true') { MAVEN_ARG += " -Dmaven.javadoc.skip=true" }
                        if (SKIP_DEPENDENCY_CHECK == 'true') { MAVEN_ARG += " -Ddependency-check.skip=true" }

                        echo "MAVEN ARGS: ${MAVEN_ARG}"

                        configFileProvider([configFile(fileId: 'maven_settings_xml', targetLocation: '/home/jenkins/agent/workspace/', variable: 'MAVEN_SETTINGS')]) {
                            sh "mvn -gs ${MAVEN_SETTINGS} clean install -N ${MAVEN_ARG}"
                            withSonarQubeEnv('SonarQube') {
                                sh "mvn -gs ${MAVEN_SETTINGS} clean install sonar:sonar ${MAVEN_ARG}"
                            }
                        }

                        sh """
                            cd target/docker/
                            chmod -R 755 *  
                            if [[ -f 'run.sh' ]]; then
                              sed -i -e "s/\\r//g" run.sh
                            fi
                            tar -czf ${APPLICATION_NAME}.tar * 
                            mv ../docker /home/jenkins/agent/workspace/Backend_Microservice_Demo/
                        """
                        FAILED_STAGE = env.STAGE_NAME
                    }
                }
            }
        }
    }
}

        // stage("Quality Gate") {
        //     steps {
        //         container(name: 'maven') {
        //             dir("${APPLICATION_NAME}") {
        //                 script {
        //                     timeout(time: 1, unit: 'HOURS') {
        //                         waitForQualityGate abortPipeline: true
        //                     }
        //                 }
        //             }
        //         }

        //     }
        // }

  stage('Build and Scan Docker image') {
            steps{
                dir('docker'){
                    container('kaniko') {
                        sh '''
                        export GOOGLE_APPLICATION_CREDENTIALS=/kaniko/.docker/kaniko-secret.json
                            /kaniko/executor --dockerfile `pwd`/Dockerfile \
                                             --context `pwd` \
                                             --skip-tls-verify \
                                             --build-arg APP_NAME=${APPLICATION_NAME} \
                                             --destination=${CONTAINER_IMAGE}
                            '''
                    }

                    // container('tools') {
                    //      script{
                            
                    //             withCredentials([string(credentialsId: 'snyk-credential-cli', variable: 'AUTH')]) {
                    //             sh "snyk auth ${AUTH}"
                    //             }
                    //             def variable = sh (
                    //                     script:"snyk container test ${CONTAINER_IMAGE} --severity-threshold=critical --json | snyk-to-html > ${APPLICATION_NAME}-service:${GIT_BRANCH}_${GIT_TAG}.html",
                    //                     returnStatus: true)
                    //                 archiveArtifacts artifacts: '*.html', followSymlinks: false , fingerprint: true
    
                    //         if (variable != 0){
                    //             error("error code = ${variable} Vulnerability found. Aborting pipeline.")
                    //             }
                    //      }
                    // }

                }
                
                
            script {
                FAILED_STAGE=env.STAGE_NAME
                }     
                
            }

        }
      

        
      stage('Chekout Helm and Config'){
         steps{
           dir('helm-chart'){
             container('tools'){
                    checkout scmGit(
                            branches: [[name: '*/dev']],
                            extensions: [[$class: 'SparseCheckoutPaths', sparseCheckoutPaths: [[path: '${APPLICATION_NAME}/*']]]],
                            userRemoteConfigs: [[credentialsId: "${GIT_CRED}", url: "${DEPLOYMENT_GIT_URL}"]])                     
                 
               
           } 

             }
             
             
             script {
                FAILED_STAGE=env.STAGE_NAME
                }
             
             
         } 
          
          
      }  
     
    //   stage('Import Application Database'){
    //       when {
    //         expression { UPGRADE_DATABASE == 'Yes' }
    //     }
    //       steps{
    //         container("tools"){
    //             dir("helm-chart/${APPLICATION_NAME}/sql/"){
    //                 script{
    //                     importDump(SQL_FILE_NAME)
    //                     FAILED_STAGE=env.STAGE_NAME
    //                 }
    //             }                
    //         }  
 
            

    //     }
    //   }        

      stage('Deploy on NAWAT'){
            steps{
             container('tools') {
                  script{
                       dir("helm-chart/${APPLICATION_NAME}/Backend/"){
                           sh 'pwd && ls -l'
                            echo "Deploying app in NAWAT environment"
                            withCredentials([file(credentialsId: 'KUBECONFIG', variable: 'KUBECONFIG_FILE')]) {
                                 
                                  // Deploying APP
                                deployApp(APPLICATION_NAME, IMAGE_TAG, DOCKER_REGISTRY, K8S_NAME_SPACE)

                                  // Call the verifyDeployment function
                                if (!verifyDeployment(APPLICATION_NAME, K8S_NAME_SPACE)) {
                                    error "Deployment Unsuccessfull. Aborting the pipeline."
                                }else {
                                    echo "Deployment Succesfull on DEMO."
                                }
                            }
                        
                       }
                       FAILED_STAGE=env.STAGE_NAME

                  }
               
             }

             
   
          }
       }
       
        stage('Update Helm & Realese Audit') {
         steps {
          container('tools'){     
            dir("helm-chart/${APPLICATION_NAME}/"){
                    script {
                        
                            withCredentials([gitUsernamePassword(credentialsId: "${GIT_CRED}", gitToolName: 'Default')]) {
                                sh """
                                  git checkout dev
                                  git pull
                                  """
                            }
                            
                        def yamlFile = readFile 'Backend/values.yaml'
                        def yamlData = readYaml text: yamlFile
                        yamlData.image.tag = "${IMAGE_TAG}"
                        writeYaml file: 'Backend/values.yaml', data: yamlData, overwrite: true
                        
                        def currentDate = java.time.LocalDateTime.now()
                        def formattedDate = currentDate.format(java.time.format.DateTimeFormatter.ofPattern('dd-MMM-yyyy'))
                        echo "Current Date: ${formattedDate}"
                        
                        def csvFile = 'RELEASE_README_BACKEND.csv'
                        def newCsvRow = ["${APPLICATION_NAME}", "${GIT_REPO_URL}", "${GIT_TAG}", "${formattedDate}"]
    
                        if (fileExists(csvFile)) {
                            def existingData = readCSV file: csvFile
                            existingData.add(newCsvRow)
                            writeCSV file: csvFile, records: existingData
                        } else {
                            def csvData = [
                                ['SERVICE', 'GIT_URL', 'GITTAG', 'DEPLOYMENT_DATE'],
                                newCsvRow
                            ]
                            writeCSV file: csvFile, records: csvData
                        } 
                        
                            withCredentials([gitUsernamePassword(credentialsId: "${GIT_CRED}", gitToolName: 'Default')]) {
                                sh """
                                  git pull
                                  git add .
                                  git commit -m "updated to ${GIT_TAG} version."
                                  git push origin demo
                                  """
                            } 
                            FAILED_STAGE=env.STAGE_NAME
                        
    
                    }
                               
                   
                
              }
             
           } 
           
           
          
           
         }    

                
    } 
        
 }

// post {
//   always {
//   sh 'sleep 30m'
//   }
// }
//   post {
//         always {
//             script {
//                 def emailSubject
//                 def emailBody

//                 if (currentBuild.result == 'SUCCESS') {
//                     emailSubject = "Pipeline Success: Application_Name - ${params.APPLICATION_NAME}-service"
//                     emailBody = "Dear Team,\n\nThe pipeline run for ${env.JOB_NAME}\n\n Application_Name = ${params.APPLICATION_NAME}-service\n Image_Tag => ${CONTAINER_IMAGE}\n Build_No => #${env.BUILD_NUMBER}\n\n was successful deploy in dev environment.\n\nRegards,\nDevOps Team"
//                 } else {
//                     emailSubject = "Pipeline Failure: Application_Name - ${params.APPLICATION_NAME}-service"
//                     emailBody = "Dear Team,\n\nThe pipeline run for ${env.JOB_NAME}\n\n Application_Name = ${params.APPLICATION_NAME}-service\n Build_No => #${env.BUILD_NUMBER}\n\n Was unsuccessful in the development environment because the pipeline failed in the ${env.STAGE_NAME} stage.\n\nRegards,\nDevOps Team"
//                 }

//                 mail bcc: '',
//                      body: emailBody,
//                      cc: 'devops@bootnext.biz',
//                      from: 'careers@bootnext.biz',
//                      subject: emailSubject,
//                      to: "${params.RECIPIENT_MAIL}"
//             }
//         }
//     }
 post {
   always {
   sh 'sleep 3h'
   }
 }
    
}

