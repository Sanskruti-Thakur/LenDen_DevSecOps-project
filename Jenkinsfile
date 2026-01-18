pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out source code"
                checkout([$class: 'GitSCM',
                          branches: [[name: '*/main']],
                          userRemoteConfigs: [[url: 'https://github.com/Sanskruti-Thakur/LenDen_DevSecOps-project.git', credentialsId: 'github-creds']]])
            }
        }

        stage('Terraform Security Scan') {
            steps {
                echo "Running Trivy scan on Terraform code"
                sh """
                trivy config terraform/ --severity HIGH,CRITICAL
                """
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Show Application URL') {
            steps {
                dir('terraform') {
                    script {
                        def appUrl = sh(script: "terraform output -raw application_url", returnStdout: true).trim()
                        echo "Your application is live at: ${appUrl}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! Your app is running on a public IP."
        }
        failure {
            echo "Pipeline failed. Check the console for errors."
        }
    }
}
