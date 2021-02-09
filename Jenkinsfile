pipeline {
    agent {
        docker { image 'ghdl/vunit:gcc' }
    }

    stages {
        stage("tools") {
            steps {
                sh 'python3 --version'
                sh 'ghdl --version'
            }
        }
        stage("simulate") {
            steps {
                sh 'rm -rf ./vunit_out *.txt *.xml
                sh 'python3 ./run.py -p6 -x output.xml --xunit-xml-format jenkins --exit-0 --no-color --cover 1 --clean'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: '**/*.xml', fingerprint: true
            archiveArtifacts artifacts: '**/*.txt', fingerprint: true
            junit '**/output.xml'
            step([$class: 'CoberturaPublisher', autoUpdateHealth: false, autoUpdateStability: false, coberturaReportFile: '**/coverage.xml', failUnhealthy: false, failUnstable: false, maxNumberOfBuilds: 0, onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false])

        }
    }
}
