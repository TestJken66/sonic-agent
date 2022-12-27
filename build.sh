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
cleanAndBuildAllPlatform() {
    mvn clean
    #    mvn package -Dplatform=linux-x86_64 -DreleaseMode=true -Dmaven.test.skip=true
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
        cp $(pwd)/pkgs/sonic-android-supply/${androidSupportVersion}_$1/sas $(pwd)/plugins/sonic-android-supply
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
    for platform in "${underline_platforms[@]}"; do
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

####################################################################################
############################ args: all、linux、mac、windows、my
####################################################################################
if [ ! -n "$1" ]; then
    echo "Not input args, Can't build, please input valid args! Support args:
    - all:      build all platrom, contains mac/linux/windows
    - mac:      build linux platrom, contains macosx-arm64 、 macosx-x86_64
    - linux:    build linux platrom, contains linux_arm64 、 linux_x86 、linux_x86_64
    - windows:  build windows platrom, contains windows_x86 、 windows_x86_64
    - my:       build your platform which build the source "
else
    if [[ "$1" == "all" ]]; then
        echo "input args [all], will build all platform packages~"
        ## Note: this platform is -, not _
        dash_platforms=("windows-x86" "windows-x86_64" "macosx-arm64" "macosx-x86_64" "linux-arm64" "linux-x86" "linux-x86_64")
        ## Note: this platform is _, not -
        underline_platforms=("windows_x86" "windows_x86_64" "macosx_arm64" "macosx_x86_64" "linux_arm64" "linux_x86" "linux_x86_64")
        # mapping
        platformsMap=(["windows_x86"]="windows-x86" ["windows_x86_64"]="windows-x86_64" ["macosx_arm64"]="macosx-arm64" ["macosx_x86_64"]="macosx-x86_64" ["linux_arm64"]="linux-arm64" ["linux_x86"]="linux-x86" ["linux_x86_64"]="linux-x86_64")
        main
    elif [[ "$1" == "mac" ]]; then
        echo "input args [mac], will build macOSX platform packages~"
        ## Note: this platform is -, not _
        dash_platforms=("macosx-arm64" "macosx-x86_64")
        ## Note: this platform is _, not -
        underline_platforms=("macosx_arm64" "macosx_x86_64")
        # mapping
        platformsMap=(["macosx_arm64"]="macosx-arm64" ["macosx_x86_64"]="macosx-x86_64")
        main
    elif [[ "$1" == "linux" ]]; then
        echo "input args [linux], will build Linux platform packages~"
        ## Note: this platform is -, not _
        dash_platforms=("linux-arm64" "linux-x86" "linux-x86_64")
        ## Note: this platform is _, not -
        underline_platforms=("linux_arm64" "linux_x86" "linux_x86_64")
        # mapping
        platformsMap=(["linux_arm64"]="linux-arm64" ["linux_x86"]="linux-x86" ["linux_x86_64"]="linux-x86_64")
        main
    elif [[ "$1" == "windows" ]]; then
        echo "input args [windows], will build Windows platform packages~"
        ## Note: this platform is -, not _
        dash_platforms=("windows-x86" "windows-x86_64")
        ## Note: this platform is _, not -
        underline_platforms=("windows_x86" "windows_x86_64")
        # mapping
        platformsMap=(["windows_x86"]="windows-x86" ["windows_x86_64"]="windows-x86_64")
        main
    elif [[ "$1" == "my" ]]; then
        _uname=$(uname)
        _mm=$(uname -m)
        _targetPlatform=""
        if [[ "$_uname" == "Darwin" ]]; then
            _targetPlatform="macosx"
        elif [[ "$_uname" == "Linux" ]]; then
            _targetPlatform="linux"
        fi
        echo "input args [my], will build ${_targetPlatform}-${_mm} platform packages~"
        ## Note: this platform is -, not _
        dash_platforms=("${_targetPlatform}-${_mm}")
        ## Note: this platform is _, not -
        underline_platforms=("${_targetPlatform}_${_mm}")
        # mapping
        platformsMap=(["${_targetPlatform}_${_mm}"]="${_targetPlatform}-${_mm}")
        main
    fi
fi

### get java version
#jversion=$(java -version 2>&1| awk 'NR==1{gsub(/"/,"");print $3}')
### get git version
# echo $(git --version 2>&1 |awk 'NR==1{gsub(/"/,"");print $3}')
