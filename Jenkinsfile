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
          make build
        '''
      }
    }
    stage('Test') {
      steps {
        sh '''
          make test
        '''
      }
    }
    stage('Documentation') {
      steps {
        sh '''
          make media
        '''
        archiveArtifacts artifacts: '.build/sphinx-docs.tar'
      }
    }
  }
}
