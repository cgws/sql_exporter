#!/bin/bash
set -e -x
export DOCKER_TAG=${CIRCLE_TAG:-$CIRCLE_BRANCH-${CIRCLE_SHA1:0:12}}
export PR_BRANCH_NAME=${CIRCLE_PROJECT_REPONAME}-${DOCKER_TAG}}

[ -n "${CIRCLE_TAG}" ] && export ENV_TAG=stable || export ENV_TAG=testing

apk add bash
helm init --client-only && \
  helm plugin install https://github.com/hypnoglow/helm-s3.git && \
  helm repo add cgws-helm-stable s3://cgws-helm/stable && \
  helm repo add cgws-helm-testing s3://cgws-helm/testing

git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/cgws/helm-charts
cd helm-charts/charts
git checkout -b $PR_BRANCH_NAME

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

git push origin $PR_BRANCH_NAME
ls -lah /usr/local/bin


mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2


/tmp/hub pull-request -b master -m "$(git log -1 --pretty=%B)"
