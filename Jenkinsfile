pipeline {
    agent {
        docker {
            image 'dri-jenkins-agent'
            label 'master'
            args '-u jenkins:jenkins --shm-size="4g" --network jenkins -v rvm:/home/jenkins/.rvm -v /var/lib/jenkins/.ssh:/home/jenkins/.ssh -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker --group-add docker'
        }
    }
    stages {
        stage('Test') {
            steps {
                sh './buildshim check '
            }
        }
    }
    post {
        always {
            junit 'spec/reports/*.xml'
            cucumber fileIncludePattern: 'features/reports/*.json'
        }
        success {
          publishHTML target: [
              allowMissing: false,
              alwaysLinkToLastBuild: false,
              keepAll: true,
              reportDir: 'coverage',
              reportFiles: 'index.html',
              reportName: 'RCov Report'
            ]
        }
    }
}
