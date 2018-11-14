def notify(context, description, status, targetUrl){
    def (account, repo) = env.ghprbGhRepository.tokenize('/')
    githubNotify account: account, context: context, credentialsId: 'gputester-username-api-token', description: description, gitApiUrl: '', repo: repo, sha: env.ghprbActualCommit, status: status, targetUrl: targetUrl
}

node('master') {
    stage('Style Check') {
        nvidiaDockerSlavesNode(image: 'gpuci/rapidsai-base:cuda9.2-ubuntu16.04-gcc5-py3.5', sideContainers: ['']) {
            checkout scm
            def statusCode = sh script:"""
            source activate gdf
            conda install flake8 -y
            flake8
            """, returnStatus:true
            if(statusCode == 0) {
                notify('gpuCI/style','Style Check Passed','SUCCESS','')
            } else {
                notify('gpuCI/style','Style Check Failed','FAILURE','')
            }
        }
    }
}
