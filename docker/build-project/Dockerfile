FROM ubuntu:24.04

ARG INPUT_REPO
ARG INPUT_BRANCH
ARG INPUT_GAME_NAME
ARG INPUT_DEFAULT_EXPORT
ARG INPUT_XR_PLUGINS
ARG INPUT_NIGHTLY

# $HOME is overwritten by Github Action at runtime
ENV HOMEDIR '/root'

ENV BIN 'release/bin'
ENV BUILD_ARGS '--headless'
ENV BUILD_PLATFORMS 'Linux Windows Mac Android QuestAndroid PicoAndroid Web Linux_arm64'
ENV GODOT_VERSION '4.8-beta5'
ENV GODOT_BASE 'https://github.com/godotengine/godot-builds/releases/download/4.8-beta5'
ENV GODOT_ZIP 'Godot_v4.8-beta5_linux.x86_64.zip'
ENV GODOT_TPZ 'Godot_v4.8-beta5_export_templates.tpz'
ENV GODOT_EDITOR 'Godot_v4.8-beta5_linux.x86_64'
ENV SANDBOX_ZIP_URL 'https://github.com/libriscv/godot-sandbox/releases/download/v0.60/godot-sandbox.zip'
ENV SANDBOX_ZIP_SHA256 '6b7f4c6a74d283352036c2cf6baf4672059ab17d4eaf00386a0357eda73ce865'
ENV TEMPLATE_DIR "$HOMEDIR/.local/share/godot/export_templates"
ENV ANDROID_SDK_ROOT "$HOMEDIR/android_sdk"
ENV ANDROID_HOME "$HOMEDIR/android_sdk"
ENV XR_PLUGIN_REPO 'V-Sekai/godot_openxr_vendors'

COPY ./build.sh /
RUN chmod +x /build.sh

WORKDIR $HOMEDIR

# Using process substitution feature (not POSIX)
SHELL [ "/bin/bash", "-c" ]

RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y git curl jq zip unzip fontconfig openjdk-17-jdk tree

RUN mkdir -p "./src"
COPY ./editor_settings-4.tres ./src/
COPY ./export_presets.cfg ./src/

# Stock Godot and its export templates, checked against the release's SHA512-SUMS.txt
RUN curl -sS -fL -O "${GODOT_BASE}/SHA512-SUMS.txt" -O "${GODOT_BASE}/${GODOT_ZIP}" -O "${GODOT_BASE}/${GODOT_TPZ}" \
    && grep -E " (${GODOT_ZIP}|${GODOT_TPZ})\$" SHA512-SUMS.txt | sha512sum -c - \
    && unzip -q "${GODOT_ZIP}" && chmod +x "${GODOT_EDITOR}" \
    && unzip -q "${GODOT_TPZ}" && rm "${GODOT_ZIP}" "${GODOT_TPZ}" \
    && "./${GODOT_EDITOR}" --headless --version | awk -F. '{print $NF}' > godot_editor_sha.txt

# The godot-sandbox addon's binaries, pinned, which the project's guests need
RUN curl -sS -fL -o sandbox.zip "${SANDBOX_ZIP_URL}" \
    && echo "${SANDBOX_ZIP_SHA256}  sandbox.zip" | sha256sum -c - \
    && unzip -q sandbox.zip 'addons/godot_sandbox/bin/*' -d ./src && rm sandbox.zip

RUN mkdir -p ./src/${BIN} \
    && cp templates/version.txt ${HOMEDIR} \
    && GODOT_VERSION=$( cat ${HOMEDIR}/version.txt ) \
    && mkdir -p ${TEMPLATE_DIR}/${GODOT_VERSION} \
    && mv -v templates/* ${TEMPLATE_DIR}/${GODOT_VERSION}/

# Setup Android
RUN curl -sS -OL 'https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip' \
    && unzip commandlinetools-linux-11076708_latest.zip \
    && mkdir -p ${ANDROID_SDK_ROOT} \
    && yes | ./cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses \
    && yes | ./cmdline-tools/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "ndk;23.2.8568313" 'cmdline-tools;latest' 'build-tools;34.0.0' 'platforms;android-34' 'cmake;3.22.1' \
    && curl -sS -OL 'https://dl.google.com/android/repository/platform-tools-latest-linux.zip' \
    && unzip platform-tools-latest-linux.zip -d ${ANDROID_SDK_ROOT} \
    && mkdir -p ./src/android/plugins ./src/android/build \
    && touch ./src/android/build/.gdignore \
    && GODOT_VERSION=$( cat ${HOMEDIR}/version.txt ) \
    && echo ${GODOT_VERSION} >> ./src/android/.build_version \
    && unzip ${TEMPLATE_DIR}/${GODOT_VERSION}/android_source.zip -d ./src/android/build

RUN keytool -v -genkey -keystore release.keystore -alias vsekaidebug -keyalg RSA -validity 10000 -dname "cn=Unknown, ou=Unknown, o=Unknown, c=Unknown" -storepass android


ENTRYPOINT ["/bin/bash", "-c", "/build.sh"] 
