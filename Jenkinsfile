pipeline {
    master any

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'vp-rem', url: 'https://github.com/devopshydclub/vprofile-project.git'
            }
        }
    }
}
