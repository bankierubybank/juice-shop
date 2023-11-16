// Declarative //
pipeline {
    // Use Linux Docker host as default agent for this pipeline
    agent {
        label 'slave-linux'
    }
    environment {
        // SCM: Git URL
        APP_REPOSITORY = 'https://github.com/bankierubybank/juice-shop.git'
        BRANCH_NAME = 'master'

        // Sonatype Nexus RM Docker Registry Configuration
        DOCKER_REPOSITORY_HOST = credentials('DOCKER_HOSTED_NEXUS_HOST')
        DEV_DOCKER_REPOSITORY_HOST = credentials('DOCKER_DEV_NEXUS_HOST')
        DOCKER_USER = credentials('NEXUS_JENKINS_USER')
        DOCKER_PASS = credentials('NEXUS_JENKINS_PASS')
        IMAGE_NAME = 'nsth-juice-shop'
        NEXUS_AUTH = credentials('NEXUS_AUTH')

        // Trend Micro CloudOne AppSec ENV
        // TREND_AP_KEY = credentials('TREND_AP_KEY')
        // TREND_AP_SECRET = credentials('TREND_AP_SECRET')
        // TREND_AP_HELLO_URL = credentials('TREND_AP_HELLO_URL')

        // Fortify ScanCentral SAST Environment Variables
        SCANCENT_APP = 'scancentral.bat'
        SCANCONT_URL = 'https://172.16.67.160:8443/scancentral-ctrl'
        VERSION_ID = '10001'
        TOKEN = '5eab02ba-353f-49b0-a5b0-57c91c066b3b'
        UNI_TOKEN = 'NDAyZGQ0NjktODZlZS00MjYzLWJkOWItNzFjMzJhMTRmMzA3'
        PY_ENV = 'C:\\Users\\User\\AppData\\Local\\Programs\\Python\\Python310'
        PY_REQ = 'requirements.txt'
        BUILD_ID = 'juice-shop'
        CI_TOKEN = 'YmE5MjA2MDEtNDBjYi00MzllLThhOTMtY2MyZGQyOTNiMjYx'
        JOB_DIR = "C:\\Jenkins\\workspace\\DevSecOps-Pipeline-Demo\\" + "${JOB_BASE_NAME}"
        trigger = "1"
        indicate = "$JOB_BASE_NAME-"+ "%BUILD_ID%" + ".fpr"

        // Set as true if want SAST to wait for result (Requried to fail pipeline from SAST)
        SAST_WAIT_FOR_RESULT = false

        // Environment variables for CD
        RHOCP_CREDENTIALS = credentials('aqua-demo-sa-token')
        RHOCP_CLUSTER = credentials('RHOCP_PROD-01_API')
        RHOCP_REGISTRY = credentials('RHOCP_PROD-01_REGISTRY')
        RHOCP_PROJECT = 'aqua-policy-demo'
        APP_NAME = 'nsth-juice-shop'

        // Sonatype Nexus IQ Configuration
        IQ_APP_NAME = 'nsth-juice-shop'
        IQ_USERNAME = credentials('IQ_USERNAME')
        IQ_PASS = credentials('IQ_PASS')

        SPECTRAL_DSN = credentials('spectral-dsn')

        // Environment variables for deployment information
        DEPLOYMENT_DIR = 'deployment/ocp'
    }
    tools {
        //Configured OpenShift Client Tools on Jenkins Global Tool Configuration
        oc 'oc-latest' //Configured OpenShift Client Tools name
    }
    stages {
        stage('CI') {
            parallel {
                stage('BUILD') {
                    stages {
                        stage('SPECTRAL: IAC SCAN') {
                            steps {
                                sh "curl -L 'https://spectral-eu.checkpoint.com/latest/x/sh?dsn=$SPECTRAL_DSN' | sh"
                                sh "$HOME/.spectral/spectral scan --ok --engines secrets,iac,oss --include-tags base,audit3,iac"
                            }
                        }
                        stage('SONATYPE: SCA') {
                            steps {
                                // Git clone
                                sh 'git clone --branch ${BRANCH_NAME} ${APP_REPOSITORY} ${IMAGE_NAME}'

                                dir(env.IMAGE_NAME) {
                                    // Use npm install with --package-lock-only to update the package-lock.json, instead of checking node_modules and downloading dependencies.
                                    // Ref: https://docs.npmjs.com/cli/v9/commands/npm-install
                                    // sh 'npm cache clean --force'
                                    // sh 'npm config set registry https://nexus.nsth.net/repository/npm-proxy/'
                                    // sh 'npm config set always-auth=true'
                                    // sh 'npm config set _auth ${NEXUS_AUTH}'
                                    // sh 'ls -l; npm config ls'

                                    sh 'npm install --package-lock-only'
                                    sh 'ls -lath'
                                    sh 'cat package-lock.json'
                                    
                                    // Scan dependencies using NexusIQ, required Nexus Platform plugin on Jenkins
                                    nexusPolicyEvaluation advancedProperties: '',
                                        enableDebugLogging: false,
                                        failBuildOnNetworkError: false,
                                        iqApplication: selectedApplication('nsth-juice-shop'),
                                        iqInstanceId: 'nexusiq.nsth.net',
                                        iqScanPatterns: [[scanPattern: "**/package-lock.json"]],
                                        iqStage: 'build',
                                        jobCredentialsId: ''
                                }
                            }
                        }
                        stage('JENKINS: BUILD IMAGE') {
                            steps {
                                // sh 'echo "\nENV TREND_AP_KEY=\'${TREND_AP_KEY}\'\nENV TREND_AP_SECRET=\'${TREND_AP_SECRET}\'\nENV TREND_AP_HELLO_URL=\'${TREND_AP_HELLO_URL}\'" >> ${IMAGE_NAME}/Dockerfile'
                                // Build image from source code with secrets injection for custom PyPI host, required Buildkit to be enabled on built host
                                sh "docker image build --progress=plain --tag ${IMAGE_NAME}:$BUILD_NUMBER ${IMAGE_NAME}"
                            }
                        }
                        stage('AQUA: IMAGE SCAN') {
                            steps {
                                sh 'docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} aqua.nexus.nsth.net'
                                // Scan image using Aqua, required Aqua Security Scanner plugin on Jenkins
                                aqua containerRuntime: 'docker',
                                    customFlags: '',
                                    hideBase: false,
                                    hostedImage: '',
                                    localImage: "nsth-juice-shop:$BUILD_NUMBER",
                                    locationType: 'local',
                                    notCompliesCmd: '',
                                    onDisallowed: 'fail',
                                    policies: '',
                                    register: false,
                                    registry: '',
                                    scannerPath: '',
                                    showNegligible: true,
                                    tarFilePath: ''
                            }
                        }
                    }
                }
                // stage('SAST') {
                //     agent {label 'SAST'}
                //     stages {
                //         stage('FORTIFY: SAST') {
                //             steps {
                //                 git branch: env.BRANCH_NAME, url: 'https://github.com/bankierubybank/juice-shop.git'
                //                 script {
                //                     if ("${trigger}" == "1"){
                //                         // add days +1
                //                         EXPIRED = powershell(script: '((get-date).AddDays(+1).toString("yyy-MM-dd"))', returnStdout: true).trim() + "T00:00:00.000+00:00";

                //                         // generate unified login token 
                //                         UNI_TOKEN = powershell(script: """(curl.exe -X POST "http://172.16.67.160:8080/ssc/api/v1/tokens" -H "accept: application/json" -H "authorization: Basic YWRtaW46TmV0cG9sZW9uIzE" -H "Content-Type: application/json" -d "{ \\"\"description\\"\": \\"\"string\\"\", \\"\"terminalDate\\"\": \\"\"$EXPIRED\\"\", \\"\"type\\"\": \\"\"UnifiedLoginToken\\"\"}"| ConvertFrom-Json).data.token""", returnStdout: true).trim()
                                        
                //                         echo "=== UNIFIED LOGIN TOKEN: ${UNI_TOKEN} WILL EXPIRED ON ${EXPIRED} ==="
                                        
                //                         // Clean previous scan
                //                         fortifyClean addJVMOptions: '', 
                //                             buildID: 'nsth-juice-shop', 
                //                             logFile: 'clean-jenkins.log'
                                        
                //                         // Offload both translate and scan throght ScanCentral
                //                         bat '%SCANCENT_APP% -url %SCANCONT_URL% start -bt none -b nsth-juice-shop'
                //                     }
                //                 }
                //             }
                //         }
                //         stage('FORTIFY: CHECK RESULT') {
                //             when {
                //                 environment name: 'SAST_WAIT_FOR_RESULT', value: 'true'
                //             }
                //             steps {
                //                 script {
                //                     // sleep; waiting scan request refresh
                //                     sleep 120

                //                     env.jobToken = powershell(script: """(curl.exe -s -X GET "http://172.16.67.160:8080/ssc/api/v1/cloudjobs?start=0&limit=1" -H "Accept: application/json" -H "Authorization: FortifyToken $UNI_TOKEN" | ConvertFrom-Json).data.jobToken""", returnStdout: true)

                //                     // Retrieve fpr from ScanCentral 
                //                     bat '%SCANCENT_APP% -url %SCANCONT_URL% retrieve -block -o -f nsth-juice-shop.fpr -token %jobToken%'

                //                     // Upload the scan results to SSC
                //                     fortifyUpload appName: 'nsth-juice-shop',
                //                         appVersion: 'v14.4.1-beta',
                //                         failureCriteria: '[fortify priority order]:critical',
                //                         filterSet: 'a243b195-0a59-3f8b-1403-d55b7a7d78e6',
                //                         resultsFile: 'nsth-juice-shop.fpr'
                                            
                //                     // Check condition if have critical issue will failed
                //                     /*
                //                     script {
                //                         if (currentBuild.result == "UNSTABLE") {
                //                             emailext body: 'APP - build - failed due to SAST', subject: 'APP - Build - Failed', to: 'dhanyarak.k@nsth.demo, chatchai.w@nsth.demo, pattaranan.j@nsth.demo'
                //                             error('This build is error because Fail Condition met vulnerabilities')
                //                         }
                //                     }
                //                     */
                                    
                //                     // Check condition if have critical severity and have more than 3 issues will failed
                                    
                //                     env.highestSeverity = powershell(script: """(curl.exe -X GET "http://172.16.67.160:8080/ssc/api/v1/projectVersions/10012/issueSummaries?seriestype=ISSUE_FOLDER&groupaxistype=ISSUE_FRIORITY" -H "accept: application/json" -H "Authorization: FortifyToken YzczM2VmYjQtMDA0Yi00NmU1LWJmZDQtMzZkYjE2MWIyYmFm"| ConvertFrom-Json).data.series.seriesName[0]""", returnStdout: true).trim()
                //                     env.severityValue = powershell(script: """(curl.exe -X GET "http://172.16.67.160:8080/ssc/api/v1/projectVersions/10012/issueSummaries?seriestype=ISSUE_FOLDER&groupaxistype=ISSUE_FRIORITY" -H "accept: application/json" -H "Authorization: FortifyToken YzczM2VmYjQtMDA0Yi00NmU1LWJmZDQtMzZkYjE2MWIyYmFm"| ConvertFrom-Json).data.series.points[0].y""", returnStdout: true).trim()
                //                     env.failedValue = 10
                    
                //                     if (env.highestSeverity == "Critical" & env.severityValue >= env.failedValue) {
                //                             bat 'BIRTReportGenerator -template "Developer Workbook" -source nsth-juice-shop.fpr -format pdf -filterSet "Security Auditor View" -output %JOB_BASE_NAME%-%BUILD_NUMBER%.pdf'
                //                             emailext attachmentsPattern: '$JOB_BASE_NAME-$BUILD_NUMBER.pdf', body: 'APP - build - failed due to SAST', subject: 'APP - Build - Failed', to: 'dhanyarak.k@nsth.demo, chatchai.w@nsth.demo, pattaranan.j@nsth.demo'
                                        
                //                             error('This build has ' + env.severityValue + ' critical vulnerabilities')
                //                     }
                                

                //                     bat 'BIRTReportGenerator -template "Developer Workbook" -source nsth-juice-shop.fpr -format pdf -filterSet "Security Auditor View" -output %JOB_BASE_NAME%-%BUILD_NUMBER%.pdf'
                //                 }
                //             }
                //         }
                //     }
                // }
            }
        }
        stage('JENKINS: PUSH IMAGE') {
            //agent {label 'slave-linux'}
            steps {
                // Tag built image for pushing
                sh "docker image tag ${IMAGE_NAME}:$BUILD_NUMBER ${DEV_DOCKER_REPOSITORY_HOST}/${IMAGE_NAME}:$BUILD_NUMBER"
                // Login to Sonatype Nexus
                sh 'docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DEV_DOCKER_REPOSITORY_HOST}'
                // Push image to Sonatype Nexus
                sh "docker image push ${DEV_DOCKER_REPOSITORY_HOST}/${IMAGE_NAME}:$BUILD_NUMBER"
            }
        }
        stage('CD') {
            stages {
                // stage('CD PREPARATION') {
                //     steps {
                //         // Git clone
                //         sh 'rm -rf ${IMAGE_NAME}'
                //         sh 'git clone --branch ${BRANCH_NAME} ${APP_REPOSITORY} ${IMAGE_NAME}'

                //         // Login to RedHat OpenShift and access project
                //         sh 'oc login --server=${RHOCP_CLUSTER} --insecure-skip-tls-verify --token=${RHOCP_CREDENTIALS}'
                //         sh 'oc project ${RHOCP_PROJECT}'
                //     }
                // }
                stage('SONATYPE: SBOM CD') {
                    steps {
                        script {
                            // Generate Internal Application ID
                            env.IQ_APP_ID = sh(script: "(curl -u ${IQ_USERNAME}:${IQ_PASS} -X GET 'https://nexusiq.nsth.net/api/v2/applications?publicId=${IQ_APP_NAME}' -H 'Accept: application/json' | jq -r '.applications[].id')", returnStdout: true).trim()
                            
                            // Generate SBOM file of latest scan
                            env.SBOM = sh (script: "(curl -u ${IQ_USERNAME}:${IQ_PASS} -X GET 'https://nexusiq.nsth.net/api/v2/cycloneDx/1.4/${IQ_APP_ID}/stages/build' -H 'Accept: application/xml' -o ${JOB_BASE_NAME}-${BUILD_NUMBER}-bom.xml)", returnStdout: true).trim()
                        }
                        nexusPolicyEvaluation advancedProperties: '',
                            enableDebugLogging: false,
                            failBuildOnNetworkError: false,
                            iqApplication: selectedApplication('nsth-juice-shop'),
                            iqInstanceId: 'nexusiq.nsth.net',
                            iqScanPatterns: [[scanPattern: "**/${JOB_BASE_NAME}-${BUILD_NUMBER}-bom.xml"]],
                            iqStage: 'release',
                            jobCredentialsId: ''
                    }
                }
                // stage('IMAGE PREP') {
                //     steps {
                //         // Tag built image for pushing
                //         sh "docker image tag ${IMAGE_NAME}:$BUILD_NUMBER ${RHOCP_REGISTRY}/${RHOCP_PROJECT}/${APP_NAME}:$BUILD_NUMBER"
                //         // Login to Sonatype Nexus
                //         sh 'docker login -u jenkins -p ${RHOCP_CREDENTIALS} ${RHOCP_REGISTRY}'
                //         // Push image to Sonatype Nexus
                //         sh "docker image push ${RHOCP_REGISTRY}/${RHOCP_PROJECT}/${APP_NAME}:$BUILD_NUMBER"
                //     }
                // }
                // stage('DEPLOY') {
                //     steps {
                //         script {
                //             sh "sed -i \"s/:tag/:$BUILD_NUMBER/\" ${DEPLOYMENT_DIR}/01-deployment.yaml"
                //             sh 'oc apply -f ${DEPLOYMENT_DIR}'
                //         }
                //         sleep(10)
                //         sh "oc get deployment/\$(cat ${DEPLOYMENT_DIR}/01-deployment.yaml | grep '  name:' | awk '{print \$2}')"
                //     }
                // }
            }
        }
    }
    post { 
        // Always do below tasks when pipeline ends
        always {
            // Remove workspace
            cleanWs()
            // Remove built application images with any tags
            // for i in $(docker image ls | grep ${IMAGE_NAME}:$BUILD_NUMBER | awk '{print $1":"$2}'); do docker rmi $i; done
            sh "for i in \$(docker image ls | grep ${IMAGE_NAME} | gerp $BUILD_NUMBER | awk '{print \$1\":\"\$2}'); do docker rmi \$i; done"
            // Remove usused data
            sh 'docker system prune --force'
        }
    }
}
