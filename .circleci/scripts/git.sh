#!/bin/bash
set -e -x
[[ -n "$CIRCLE_TAG" ]] && export ENV_TAG=production || export ENV_TAG=test
[[ ${ENV_TAG} == "production" ]] && export BRANCH=absinthe || export BRANCH=rbt
[[ ${ENV_TAG} == "production" ]] && export CHART=stable || export CHART=testing

export DOCKER_TAG=${CIRCLE_TAG:-$CIRCLE_BRANCH-${CIRCLE_SHA1:0:12}}
export PR_BRANCH_NAME=${BRANCH}-${CIRCLE_PROJECT_REPONAME}-${CIRCLE_TAG:-$CIRCLE_BRANCH-${CIRCLE_SHA1:0:12}}


git clone https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/cgws/veritas -b $BRANCH
cd veritas
git pull

git checkout -b $PR_BRANCH_NAME

###### Check for a project_namespace env
[ -n "${PROJECT_NAMESPACE}" ] || export PROJECT_NAMESPACE=$CIRCLE_PROJECT_REPONAME

########### MANIFEST
#cat releases/$CIRCLE_PROJECT_REPONAME.yaml | yq --arg projname "$CIRCLE_PROJECT_REPONAME" --arg newversion "v1.0.1" '.spec.template.spec.containers |= map(select(.name == $projname).image = "362995399210.dkr.ecr.ap-southeast-2.amazonaws.com/catch/$projname:$newversion" )'

if [ ! -f namespaces/$PROJECT_NAMESPACE.yaml ]; then
    echo "File not found!"
    envsubst < ~/code/.circleci/templates/namespace.yaml | sponge  namespaces/$PROJECT_NAMESPACE.yaml
fi


########## HELM Values
if [ ! -f releases/$CIRCLE_PROJECT_REPONAME.yaml ]; then
  echo "File not found!"
  envsubst < ~/code/.circleci/templates/release.yaml | sponge  releases/$CIRCLE_PROJECT_REPONAME.yaml
else
    cat releases/$CIRCLE_PROJECT_REPONAME.yaml | yq -y --arg projname "$CIRCLE_PROJECT_REPONAME" --arg newversion "${DOCKER_TAG}" '.spec.values.image.tag = $newversion' | sponge releases/$CIRCLE_PROJECT_REPONAME.yaml
fi

git config --global user.email "circleci@catch.com.au"
git config --global user.name "Circle"

git add releases/$CIRCLE_PROJECT_REPONAME.yaml
git add namespaces/$PROJECT_NAMESPACE.yaml

git commit -m "[$BRANCH] UPDATE $CIRCLE_PROJECT_REPONAME image to $DOCKER_TAG"

if [ "$ENV_TAG" == "production" ]; then
  git push origin $PR_BRANCH_NAME
  ls -lah /usr/local/bin
  mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
  /tmp/hub pull-request -b $BRANCH -m "$(git log -1 --pretty=%B)"
else
    git checkout $BRANCH
    git merge --ff-only $PR_BRANCH_NAME
    git push
fi
