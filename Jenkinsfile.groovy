ef BUILD_TYPE
pipeline {
    agent any

    stages {
    stage('build type'){
    steps{
        script{
            if(env.BRANCH_NAME == 'main'){
                  BUILD_TYPE = 'release'
            } else{
                 BUILD_TYPE = 'integrate'
            }
        }
        }
    }
        stage('terraform format check') {
            steps{
                    script {
                    if(BUILD_TYPE == 'integrate'){
                        sh 'terraform fmt'
                    } else {
                    echo "Different build"
                    }
                    }
            }
        }
        stage('terraform Init') {
            steps{
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws_cred_njomza",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                    if(BUILD_TYPE == 'integrate'){
                        sh 'terraform init'
                    } else {
                    echo "Different build"
                    }
                    }
                }
            }
        }
    stage('terraform Plan') {
            steps{
        withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws_cred_njomza",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                    if(BUILD_TYPE == 'integrate'){
                        sh 'terraform plan'
                    } else {
                    echo "Different build"
                    }
                    }
        }
            }
        }
        stage('terraform apply') {
            steps{
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws_cred_njomza",
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    script {
                    if(BUILD_TYPE == 'release'){
                        sh '''
                        terraform fmt
                        terraform init
                        terraform plan
                        terraform apply --auto-approve
                        '''
                    } else {
                    echo "Different build"
                    }
                    }
                }
            }
        }
    }
}
