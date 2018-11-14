def notify(context, description, status, targetUrl){
    def (account, repo) = env.ghprbGhRepository.tokenize('/')
    githubNotify account: account, context: context, credentialsId: 'gputester-username-api-token', description: description, gitApiUrl: '', repo: repo, sha: env.ghprbActualCommit, status: status, targetUrl: targetUrl
}

node('master') {
    stage('Style Check') {
        node('cpu') {
            checkout scm
            def statusCode = sh script:'flake8', returnStatus:true
            if(statusCode == 0) {
                notify('gpuCI/style','Style Check Passed','SUCCESS','')
            } else {
                notify('gpuCI/style','Style Check Failed','FAILURE','')
            }
        }
    }
}
