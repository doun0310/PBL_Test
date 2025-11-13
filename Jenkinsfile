pipeline {
    agent any

    environment {
        FLUTTER_HOME = "${env.FLUTTER_HOME}"
        ANDROID_HOME = "${env.ANDROID_HOME}"
        APP_NAME = 'meal_management_app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo 'Checking out code from repository...'
                    checkout scm
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    echo 'Installing Flutter dependencies...'
                    sh 'flutter pub get'
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    echo 'Running Flutter tests...'
                    sh 'flutter test || true'
                }
            }
        }

        stage('Analyze Code') {
            steps {
                script {
                    echo 'Running Flutter analyze...'
                    sh 'flutter analyze || true'
                }
            }
        }

        stage('Build Android APK') {
            steps {
                script {
                    echo 'Building Android APK...'
                    sh 'flutter build apk --release'
                }
            }
        }

        stage('Build Android App Bundle') {
            steps {
                script {
                    echo 'Building Android App Bundle...'
                    sh 'flutter build appbundle --release'
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                script {
                    echo 'Archiving build artifacts...'
                    archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk', fingerprint: true
                    archiveArtifacts artifacts: 'build/app/outputs/bundle/release/*.aab', fingerprint: true
                }
            }
        }

        // Uncomment if you have Docker setup for backend
        // stage('Build Backend Docker Image') {
        //     steps {
        //         script {
        //             echo 'Building Backend Docker Image...'
        //             dir('backend') {
        //                 withDockerRegistry(credentialsId: 'docker', url: 'https://registry.hub.docker.com') {
        //                     def backendImage = docker.build("${APP_NAME}-backend:${env.BUILD_NUMBER}")
        //                     docker.withRegistry('https://registry.hub.docker.com', 'docker') {
        //                         backendImage.push()
        //                     }
        //                 }
        //             }
        //         }
        //     }
        // }

        // stage('Deploy') {
        //     steps {
        //         script {
        //             echo 'Deploying application...'
        //             // Add your deployment steps here
        //         }
        //     }
        // }
    }

    post {
        always {
            echo 'Pipeline execution completed.'
            cleanWs()
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline execution failed!'
        }
    }
}
