#!/bin/bash
# 0. first  defind version
targetVersion="v2.2.2"
## some libs version, code will get newest, igone
androidSupportVersion="0.0.2"
goMitmproxyVersion="1.3.3"
iosBridgeVersion="1.3.5"

## Note: this platform is -, not _
dash_platforms=("windows-x86" "windows-x86_64" "macosx-arm64" "macosx-x86_64" "linux-arm64" "linux-x86" "linux-x86_64")
## Note: this platform is _, not -
underline_platforms=("windows_x86" "windows_x86_64" "macosx_arm64" "macosx_x86_64" "linux_arm64" "linux_x86" "linux_x86_64")
# mapping
platformsMap=(["windows_x86"]="windows-x86" ["windows_x86_64"]="windows-x86_64" ["macosx_arm64"]="macosx-arm64" ["macosx_x86_64"]="macosx-x86_64" ["linux_arm64"]="linux-arm64" ["linux_x86"]="linux-x86" ["linux_x86_64"]="linux-x86_64")

# make sure use java 15
makesureJavaVersion15() {
    # my path
    JAVA_HOME=/Library/Java/JavaVirtualMachines/corretto-15.0.2/Contents/Home
    PATH=$PATH:$JAVA_HOME/bin
    CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
    export JAVA_HOME PATH CLASSPATH
}
replaceVersionToTargetVerion() {
    if [ "$(uname -s)" = "Darwin" ]; then
        sed -i '' "s/SONIC_VERSION/${targetVersion}/" ./pom.xml
    else
        sed -i "s/SONIC_VERSION/${targetVersion}/" ./pom.xml
    fi
}
resetVersion() {
    if [ "$(uname -s)" = "Darwin" ]; then
        sed -i '' "s/${targetVersion}/SONIC_VERSION/" ./pom.xml
    else
        sed -i "s/${targetVersion}/SONIC_VERSION/" ./pom.xml
    fi
}
# build custom platform. use base command:
# mvn clean package -Dmaven.test.skip=true
# build custom platform. use this command:
## mvn clean package -Dplatform=windows-x86 -DreleaseMode=true -Dmaven.test.skip=true
#
# build all platform
# "windows-x86", "windows-x86_64", "macosx-arm64", "macosx-x86_64", "linux-arm64", "linux-x86", "linux-x86_64"
cleanAndBuildAllPlatform() {
    mvn clean
    #    mvn package -Dplatform=windows-x86 -Dmaven.test.skip=true
    #    mvn package -Dplatform=windows-x86 -DreleaseMode=true -Dmaven.test.skip=true
    #    mvn package -Dplatform=windows-x86_64 -DreleaseMode=true -Dmaven.test.skip=true
    #    mvn package -Dplatform=macosx-arm64 -DreleaseMode=true -Dmaven.test.skip=true
    #    mvn package -Dplatform=macosx-x86_64 -DreleaseMode=true -Dmaven.test.skip=true
    #    mvn package -Dplatform=linux-arm64 -DreleaseMode=true -Dmaven.test.skip=true
    #    mvn package -Dplatform=linux-x86 -DreleaseMode=true -Dmaven.test.skip=true
    #    mvn package -Dplatform=linux-x86_64 -DreleaseMode=true -Dmaven.test.skip=true
    #
    for platform in "${dash_platforms[@]}"; do
        mvn package -Dplatform=${platform} -DreleaseMode=true -Dmaven.test.skip=true
    done
}
clearCaches() {
    find ./ -name ".DS_Store" -depth -exec rm -rf {} \;
    find ./ -name "__MACOSX" -depth -exec rm -rf {} \;
}

# process one platform
# $1: $platform
zipItem() {

    echo "platform : $1"
    if [[ $1 = windows* ]]; then
        #        echo "windows platform"
        # prepare sonic-android-supply
        cp $(pwd)/pkgs/sonic-android-supply/${androidSupportVersion}_$1/sas.exe $(pwd)/plugins/sonic-android-supply.exe
        # prepare sonic-go-mitmproxy
        cp $(pwd)/pkgs/sonic-go-mitmproxy/${goMitmproxyVersion}_$1/sonic-go-mitmproxy.exe $(pwd)/plugins/sonic-go-mitmproxy.exe
        # prepare sonic-ios-bridge
        cp $(pwd)/pkgs/sonic-ios-bridge/${iosBridgeVersion}_$1/sib.exe $(pwd)/plugins/sonic-ios-bridge.exe
        clearCaches
        # real package zip
        zip -q -r sonic-agent-${targetVersion}-$1.zip sonic-agent-${platformsMap["$1"]}.jar config/ mini/ plugins/
        # clear tempfils
        rm -rf $(pwd)/plugins/sonic-android-supply.exe
        rm -rf $(pwd)/plugins/sonic-go-mitmproxy.exe
        rm -rf $(pwd)/plugins/sonic-ios-bridge.exe
    else
        #        echo "not windows platform"
        # prepare sonic-android-supply
        cp $(pwd)/pkgs/sonic-android-supply/${androidSupportVersion}_$1/sas $(pwd)/plugins/sonic-android-supply.
        # prepare sonic-go-mitmproxy
        cp $(pwd)/pkgs/sonic-go-mitmproxy/${goMitmproxyVersion}_$1/sonic-go-mitmproxy $(pwd)/plugins/sonic-go-mitmproxy
        # prepare sonic-ios-bridge
        cp $(pwd)/pkgs/sonic-ios-bridge/${iosBridgeVersion}_$1/sib $(pwd)/plugins/sonic-ios-bridge
        clearCaches
        # real package zip
        zip -q -r sonic-agent-${targetVersion}-$1.zip sonic-agent-${platformsMap["$1"]}.jar config/ mini/ plugins/
        # clear tempfils
        rm -rf $(pwd)/plugins/sonic-android-supply
        rm -rf $(pwd)/plugins/sonic-go-mitmproxy
        rm -rf $(pwd)/plugins/sonic-ios-bridge
    fi
    ##  delete some temp file in zip. if not has will happen error
    #zip -dv sonic-agent-$1-$2.zip ".DS_Store" "__MACOSX"
}

zipPkgs() {
    clearCaches
    cp target/*.jar .
    for platform in "${underline_platforms[@]}"; do
        zipItem "${platform}"
    done
    rm -rf *.jar
    mv -f *.zip release/
}

prepareEnvs() {
    rm -rf *.jar
    rm -rf *.zip
    rm -rf release/
    rm -rf target/
    rm -rf log/

    rm -rf pkgs/
    rm -rf *.gz
    mkdir release
    mkdir -p pkgs/sonic-android-supply/
    mkdir -p pkgs/sonic-go-mitmproxy/
    mkdir -p pkgs/sonic-ios-bridge/
    chmod -R 777 *
}
updateNewVersion() {
    # get last full version
    # curl -s https://api.github.com/repos/SonicCloudOrg/sonic-ios-bridge/releases/latest | grep tag_name|cut -f4 -d "\""
    # get last version string
    # curl -s https://api.github.com/repos/SonicCloudOrg/sonic-ios-bridge/releases/latest | grep tag_name|cut -f4 -d "\""|cut -b 2-
    androidSupportVersion=$(curl -s https://api.github.com/repos/SonicCloudOrg/sonic-android-supply/releases/latest | grep tag_name | cut -f4 -d "\"" | cut -b 2-)
    goMitmproxyVersion=$(curl -s https://api.github.com/repos/SonicCloudOrg/sonic-go-mitmproxy/releases/latest | grep tag_name | cut -f4 -d "\"" | cut -b 2-)
    iosBridgeVersion=$(curl -s https://api.github.com/repos/SonicCloudOrg/sonic-ios-bridge/releases/latest | grep tag_name | cut -f4 -d "\"" | cut -b 2-)
}

downAndExtraFiles() {
    # https://github.com/SonicCloudOrg/sonic-android-supply/releases/download/v0.0.2/sonic-android-supply_0.0.2_linux_arm64.tar.gz
    ## Note: this platform is _, not -
    platforms=("windows_x86" "windows_x86_64" "macosx_arm64" "macosx_x86_64" "linux_arm64" "linux_x86" "linux_x86_64")
    for platform in "${platforms[@]}"; do
        echo "=============================================================================================================="
        echo "=====================downAndExtraFiles Extra package [${platform}] ==========================================="
        echo "=============================================================================================================="
        # https://github.com/SonicCloudOrg/sonic-android-supply/releases/download/v0.0.2/sonic-android-supply_0.0.2_linux_arm64.tar.gz
        url="https://github.com/SonicCloudOrg/sonic-android-supply/releases/download/v${androidSupportVersion}/sonic-android-supply_${androidSupportVersion}_${platform}.tar.gz"
        #    wget --no-check-certificate --content-disposition $url
        curl -LJOs $url
        if [ $# == 0 ]; then
            mkdir -p pkgs/sonic-android-supply/${androidSupportVersion}_${platform}
            tar zxvf sonic-android-supply_${androidSupportVersion}_${platform}.tar.gz -C pkgs/sonic-android-supply/${androidSupportVersion}_${platform}
        fi
        if [ $# == 0 ]; then
            echo "config [sonic-android-supply: ${androidSupportVersion}] success~~"
        fi
        # https://github.com/SonicCloudOrg/sonic-go-mitmproxy/releases/download/v1.3.3/sonic-go-mitmproxy_1.3.3_linux_arm64.tar.gz
        url="https://github.com/SonicCloudOrg/sonic-go-mitmproxy/releases/download/v${goMitmproxyVersion}/sonic-go-mitmproxy_${goMitmproxyVersion}_${platform}.tar.gz"
        #    wget --no-check-certificate --content-disposition $url
        curl -LJOs $url
        if [ $# == 0 ]; then
            mkdir -p pkgs/sonic-go-mitmproxy/${goMitmproxyVersion}_${platform}
            tar zxvf sonic-go-mitmproxy_${goMitmproxyVersion}_${platform}.tar.gz -C pkgs/sonic-go-mitmproxy/${goMitmproxyVersion}_${platform}
        fi
        if [ $# == 0 ]; then
            echo "config [sonic-go-mitmproxy: ${goMitmproxyVersion}] success~~"
        fi
        # https://github.com/SonicCloudOrg/sonic-ios-bridge/releases/download/v1.3.5/sonic-ios-bridge_1.3.5_linux_arm64.tar.gz
        url="https://github.com/SonicCloudOrg/sonic-ios-bridge/releases/download/v${iosBridgeVersion}/sonic-ios-bridge_${iosBridgeVersion}_${platform}.tar.gz"
        #    wget --no-check-certificate --content-disposition $url
        curl -LJOs $url
        if [ $# == 0 ]; then
            mkdir -p pkgs/sonic-ios-bridge/${iosBridgeVersion}_${platform}
            tar zxvf sonic-ios-bridge_${iosBridgeVersion}_${platform}.tar.gz -C pkgs/sonic-ios-bridge/${iosBridgeVersion}_${platform}
        fi
        if [ $# == 0 ]; then
            echo "config [sonic-ios-bridge: ${iosBridgeVersion}] success~~"
        fi
    done
    rm -rf *.tar.gz
}

main() {
    # 0. make env. clean temp dirs, and make sure jdk version
    prepareEnvs           # 0. clean temp dir and files
    updateNewVersion      # 0.1. get netest libs version
    downAndExtraFiles     # 0.2. down load extra libs
    makesureJavaVersion15 # 0.3. make sure JDK version 15
    # 1. modify platform sonic-agent Version{SONIC_VERSION} in pom.xml
    replaceVersionToTargetVerion
    if [ $# == 0 ]; then
        echo "=====================replaceVersionToTargetVerion succes====================="
    fi
    # 2. build all platrom
    cleanAndBuildAllPlatform
    if [ $# == 0 ]; then
        echo "=====================cleanAndBuildAllPlatform succes====================="
    fi
    # 3. reset version
    resetVersion
    if [ $# == 0 ]; then
        echo "=====================resetVersion succes====================="
    fi
    # 4. zip relase packages
    zipPkgs
    if [ $# == 0 ]; then
        echo "=====================zipPkgs succes====================="
    fi
}

main
