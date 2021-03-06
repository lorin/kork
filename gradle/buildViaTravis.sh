#!/bin/bash
# This script will build the project.

set -e

GRADLE="./gradlew -PenablePublishing=true --no-daemon --max-workers=1"
export GRADLE_OPTS="-Xmx1g -Xms1g"

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo -e "Build Pull Request #$TRAVIS_PULL_REQUEST => Branch [$TRAVIS_BRANCH]"
  $GRADLE build
elif [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_TAG" == "" ]; then
  echo -e 'Build Branch with Snapshot => Branch ['$TRAVIS_BRANCH']'
  $GRADLE -Prelease.travisci=true -PbintrayUser="${bintrayUser}" -PbintrayKey="${bintrayKey}" build snapshot --stacktrace
elif [ "$TRAVIS_PULL_REQUEST" == "false" ] && [ "$TRAVIS_TAG" != "" ]; then
  echo -e 'Build Branch for Release => Branch ['$TRAVIS_BRANCH']  Tag ['$TRAVIS_TAG']'
  case "$TRAVIS_TAG" in
  *-rc\.*)
    $GRADLE -Prelease.travisci=true -Prelease.useLastTag=true -PbintrayUser="${bintrayUser}" -PbintrayKey="${bintrayKey}" candidate --info
    ;;
  *)
    $GRADLE --info -Prelease.travisci=true -Prelease.useLastTag=true -PbintrayUser="${bintrayUser}" -PbintrayKey="${bintrayKey}" final
    # delay a bit to let published artifacts get all mirrored etc before autobumping
    sleep 60
    $GRADLE --info -Prelease.travisci=true -Prelease.useLastTag=true -PbintrayUser="${bintrayUser}" -PbintrayKey="${bintrayKey}" -Pgithub.token="${githubToken}" bumpDependencies
    ;;
  esac
else
  echo -e 'WARN: Should not be here => Branch ['$TRAVIS_BRANCH']  Tag ['$TRAVIS_TAG']  Pull Request ['$TRAVIS_PULL_REQUEST']'
  $GRADLE build
fi

