#!/bin/sh

# Should be run from the top of the react-native-tvos monorepo


export REACT_NATIVE_PATH=$PWD/packages/react-native
export HERMES_TV_ARCHIVE_DIR=$REACT_NATIVE_PATH/ReactAndroid/external-artifacts/artifacts

export MAC_DEPLOYMENT_TARGET="10.13"
export IOS_DEPLOYMENT_TARGET="12.4"

export REACT_NATIVE_CI=true
export CI=true

# Prepare Hermes
rm -rf $HERMES_TV_ARCHIVE_DIR
mkdir $HERMES_TV_ARCHIVE_DIR

build_tv_artifact() {
  # Build step 1: clean and prepare Hermes directory
  (cd $REACT_NATIVE_PATH; rm -rf ./sdks/hermes ./sdks/download)
  (cd $REACT_NATIVE_PATH; node scripts/hermes/prepare-hermes-for-build.js)
  (cd $REACT_NATIVE_PATH; cp -r ./sdks/hermes-engine/utils/* ./sdks/hermes/utils)
  
  # Build step 2: build Mac binaries
  (cd $REACT_NATIVE_PATH/sdks/hermes; BUILD_TYPE=$HERMES_BUILD_TYPE ./utils/build-mac-framework.sh)

  # Build step 3: build iOS/tvOS binaries
  (cd $REACT_NATIVE_PATH/sdks/hermes; BUILD_TYPE=$HERMES_BUILD_TYPE ./utils/build-ios-framework.sh)
 
  # Build step 4: create tarballs
  (cd $REACT_NATIVE_PATH; TARBALL_OUTPUT_PATH=`node ./scripts/hermes/create-tarball.js --inputDir ./sdks/hermes --buildType "$HERMES_BUILD_TYPE" --outputDir $HERMES_TV_ARCHIVE_DIR`; echo "Build artifact for type $HERMES_BUILD_TYPE saved to $TARBALL_OUTPUT_PATH.")
}

HERMES_BUILD_TYPE=Debug
build_tv_artifact

HERMES_BUILD_TYPE=Release
build_tv_artifact

# Final step: publish to local repository
echo "Artifacts are now in $HERMES_TV_ARCHIVE_DIR"
echo "You can publish them to the local (/tmp/maven-local) repository, from the top level directory:"
echo "  ./gradlew :packages:react-native:ReactAndroid:external-artifacts:publishAllPublicationsToMavenTempLocalRepository"

gpg --sign README.md
./gradlew :packages:react-native:ReactAndroid:external-artifacts:publishAllPublicationsToMavenTempLocalRepository
