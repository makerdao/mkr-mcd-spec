pipeline {
  options {
    ansiColor('xterm')
  }
  agent {
    dockerfile {
      additionalBuildArgs '--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'
      args '-m 60g'
    }
  }
  stages {
    stage('Init title') {
      when { changeRequest() }
      steps {
        script {
          currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
        }
      }
    }
    stage('Dependencies') {
      steps {
        sh '''
          make deps
        '''
      }
    }
    stage('Build') {
      steps {
        sh '''
          make build -j4
        '''
      }
    }
    stage('Test') {
      parallel {
        stage('Build Configuration') {
          steps {
            sh '''
              make test-python-config
            '''
          }
        }
        // stage('Run Simple Tests') {
        //   steps {
        //     sh '''
        //       make test-python-run
        //     '''
        //   }
        // }
      }
    }
    stage('Documentation') {
      steps {
        sh '''
          make deps-media
          make .build/mkr-mcd-rtd.tar
          cp .build/mkr-mcd-rtd.tar ./
        '''
        archiveArtifacts artifacts: 'mkr-mcd-rtd.tar'
      }
    }
  }
}
