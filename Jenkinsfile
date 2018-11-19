### Jarvis Helper Functions ###
def ghStatusStart(context, description, targetUrl){
    def (account, repo) = env.ghprbGhRepository.tokenize('/')
    githubNotify account: account, context: context, credentialsId: 'gputester-username-api-token', description: description, gitApiUrl: '', repo: repo, sha: env.ghprbActualCommit, status: 'PENDING', targetUrl: targetUrl
}
def ghStatusUpdate(context, description, status, targetUrl){
    if (status == 0) {
        status = 'SUCCESS'
        description += ' - Passed'
    } else {
        status = 'FAILURE'
        description += ' - Failed'
    }
    def (account, repo) = env.ghprbGhRepository.tokenize('/')
    githubNotify account: account, context: context, credentialsId: 'gputester-username-api-token', description: description, gitApiUrl: '', repo: repo, sha: env.ghprbActualCommit, status: status, targetUrl: targetUrl
}

### Pipeline definition ###
node {
    stage('Style Check') {
        nvidiaDockerSlavesNode(image: 'gpuci/rapidsai-base:cuda9.2-ubuntu16.04-gcc5-py3.5') {
            ghStatusStart('jarvis/style','Style Check','')
            checkout scm
            def styleCheck = """#!/bin/bash
            env
            ls -la /
            ls -la \$HOME
            ls -la
            source activate gdf
            conda install flake8 -y
            flake8
            """
            def statusCode = sh script:styleCheck, returnStatus:true
            ghStatusUpdate('jarvis/style','Style Check',statusCode,'')
        }
    }
}
