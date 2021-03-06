#!/bin/sh
set -e

echo "Starting the Jekyll Action"

echo "::debug ::Starting bundle install"
bundle config path vendor/bundle
bundle install
echo "::debug ::Completed bundle install"

if [[ ${INPUT_JEKYLL_SRC} ]]; then
  JEKYLL_SRC=${INPUT_JEKYLL_SRC}
  echo "::debug ::Using parameter value ${JEKYLL_SRC} as a source directory"
elif [[ ${SRC} ]]; then
  JEKYLL_SRC=${SRC}
  echo "::debug ::Using SRC environment var value ${JEKYLL_SRC} as a source directory"
else
  JEKYLL_SRC=$(find . -path ./vendor/bundle -prune -o -name '_config.yml' -exec dirname {} \;)
  echo "::debug ::Resolved ${JEKYLL_SRC} as a source directory"
fi

JEKYLL_ENV=production bundle exec jekyll build -s ${JEKYLL_SRC} -d build
echo "Jekyll build done"

cd build

# No need to have GitHub Pages to run Jekyll
touch .nojekyll

# Is this a regular repo or an org.github.io type of repo
if [[ "${INPUT_DEST_REPO}" == *".github.io"* ]]; then
  remote_branch="master"
else
  remote_branch="gh-pages"
fi

if [[ ${INPUT_DEST_BRANCH} ]]; then
	remote_branch=${INPUT_DEST_BRANCH}
fi

echo "Publishing to ${INPUT_DEST_REPO} on branch ${remote_branch}"

remote_repo="https://${JEKYLL_PAT}@github.com/${INPUT_DEST_REPO}.git" && \
git init && \
git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
git add . && \
git commit -m "Site build from action ${GITHUB_SHA}" && \
git push --force $remote_repo master:$remote_branch && \
rm -fr .git && \
cd ..
exit 0
