#!/usr/bin/env groovy
@Library(['piper-lib', 'piper-lib-os']) _

node("master") {
	dockerExecuteOnKubernetes(script: this, dockerEnvVars: ['token':token,'pusername':pusername, 'puserpwd':puserpwd, 'sfQueueTopicName1':sfQueueTopicName1], dockerImage: 'docker.wdf.sap.corp:51010/sfext:v3' ) {
		try {	
			stage ('Build') { 
				deleteDir()
				sh "git config --global http.sslVerify false"
				checkout scm	 		 
				sh '''
				    npm config set strict-ssl false
					npm config set unsafe-perm true 
					npm install -g node-pre-gyp
					npm rm -g @sap/cds
					npm i -g @sap/cds-dk
					echo 'y' | apt-get install jq
					cds import ./build/FoundationPlatformPLT.edmx
					cds import ./build/PLTUserManagement.edmx
					cds import ./build/ECSkillsManagement.edmx
					jq '.+{"cds": {
					        "hana": {
            					     "deploy-format": "hdbtable"
        					},
						"requires": {
							"uaa": {
								"kind": "xsuaa"
							},
							"messaging": {
								"kind": "enterprise-messaging-shared",
								"queue": {
								"name": "$namespace/cloud-sf-extension-cap-sample-srv/1234"
								},
								"publishPrefix": "$namespace/",
								"subscribePrefix": "$namespace/"
							},
							"db": {
								"kind": "hana"
							},
							"ECSkillsManagement": {
								"kind": "odata-v2",
								"model": "srv/external/ECSkillsManagement",
								"credentials": {
								"destination": "sfextension-service",
								"path": "/odata/v2",
								"requestTimeout": 18000000
								}
							},
							"FoundationPlatformPLT": {
								"kind": "odata-v2",
								"model": "srv/external/FoundationPlatformPLT",
								"credentials": {
								"destination": "sfextension-service",
								"path": "/odata/v2",
								"requestTimeout": 18000000
								}
							},
							"PLTUserManagement": {
								"kind": "odata-v2",
								"model": "srv/external/PLTUserManagement",
								"credentials": {
								"destination": "sfextension-service",
								"path": "/odata/v2",
								"requestTimeout": 18000000
								}
							}
						},
					"odata": {
							"version": "v4"
						}
				}
				}' package.json > package1.json
					mv package1.json package.json
					mv ./build/enterprisemessage.json enterprisemessage.json
					mv ./build/mta.yaml mta.yaml
					mbt build -p=cf
					'''
			}
			stage('Deploy'){
				setupCommonPipelineEnvironment script:this
				withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'pusercf', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
					sh "cf login -a ${commonPipelineEnvironment.configuration.steps.cloudFoundryDeploy.cloudFoundry.apiEndpoint} -u $USERNAME -p $PASSWORD -o ${commonPipelineEnvironment.configuration.steps.cloudFoundryDeploy.cloudFoundry.org} -s ${commonPipelineEnvironment.configuration.steps.cloudFoundryDeploy.cloudFoundry.space}"
				}
				// sh'''
				// 	cf ds sfextension-service -f
				// '''
				cloudFoundryDeleteService script:this
				cloudFoundryDeploy script:this, deployTool:'mtaDeployPlugin'
			}
			stage('Integration Test'){
				sh'''
					cd test
					npm i
					srv_guid=`cf app cloud-sf-extension-cap-sample-srv --guid`
					cf curl /v2/apps/$srv_guid/env > sample.json
					jest ./test			   
					'''
			}
			stage('UI Test'){
			
				build job: 'SFDemoscript'
			}
			stage('Undeploy'){
				sh'''
					echo 'y' | cf undeploy cloud-sf-extension-cap-sample
				'''
				cloudFoundryDeleteService script:this
			}
		}
		catch(e){
			echo 'This will run only if failed'
			currentBuild.result = "FAILURE"
		}
		finally {
			emailext body: '$DEFAULT_CONTENT', subject: '$DEFAULT_SUBJECT', to: 'DL_5731D8E45F99B75FC100004A@global.corp.sap,DL_58CB9B1A5F99B78BCC00001A@global.corp.sap'
		}

}
} 
