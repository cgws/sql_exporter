#!/bin/bash
set -e -x
export DOCKER_TAG=${CIRCLE_TAG:-$CIRCLE_BRANCH-${CIRCLE_SHA1:0:12}}
export PR_BRANCH_NAME=${CIRCLE_PROJECT_REPONAME}-${DOCKER_TAG}}

function update_helm_charts() {
    apk add bash
    helm init --client-only && \
      helm plugin install https://github.com/hypnoglow/helm-s3.git && \
      helm repo add cgws-helm-stable s3://cgws-helm/stable && \
      helm repo add cgws-helm-testing s3://cgws-helm/testing

    git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/cgws/helm-charts
    cd helm-charts/charts

    helm repo update

    cd $ENV_TAG && helm fetch cgws-helm-$ENV_TAG/$CIRCLE_PROJECT_REPONAME --untar --devel

    if [ -n "$(git status --porcelain)" ]; then
       echo "Changes in chart detected proceeding"
    else
        echo "No chart changes, exiting!"
        exit 0
    fi

    git config --global user.email "circleci@catch.com.au"
    git config --global user.name "Circle"

    git add -A
    git commit -a -m "[${ENV_TAG}] UPDATE/ADD Chart: ${CIRCLE_PROJECT_REPONAME}-${DOCKER_TAG}"

    git push

}

[ -n "${CIRCLE_TAG}" ] && ENV_TAG=stable update_helm_charts

ENV_TAG=testing update_helm_charts