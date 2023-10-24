FROM debian:buster-slim

ARG OWN_JAVA_VERSION="14.0.2"

ARG OWN_COMMAND_LINE_TOOLS_VERSION="7302050"  # Latest: 10406996
ARG OWN_ANDROID_NDK_VERSION="21"  # Other versions: https://github.com/android/ndk/wiki/Unsupported-Downloads

ARG OWN_SMARTTUBE_TAG="19.57"

ARG OWN_DEVICE_IP="192.168.1.128"             # Android Device IP Address


# Set environment variables
ENV JAVA_HOME /root/.sdkman/candidates/java/current
ENV ANDROID_SDK_ROOT /usr/local/android-sdk
ENV ANDROID_NDK_HOME "/usr/local/android-ndk-r${OWN_NDK_VERSION}"
ENV PLATFORN_TOOLS_PATH "/usr/local/platform-tools"

ENV PATH "${ANDROID_NDK_HOME}:${PLATFORN_TOOLS_PATH}:${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"
ENV PATH "${PATH}"

# Install required software
RUN apt-get update     \
 && apt-get install -y \
        curl           \
        wget           \
        git            \
        unzip          \
        zip            \
    && apt-get clean   \
    && rm -rf /var/lib/apt/lists/*

# Install sdkman to install own java version
RUN wget -qO- "https://get.sdkman.io" | bash \
 && bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk install java ${OWN_JAVA_VERSION}-open && sdk use java ${OWN_JAVA_VERSION}-open"

# Download and install Android Platform Tools
RUN wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip \
 && unzip platform-tools-latest-linux.zip -d /usr/local                              \
 && rm platform-tools-latest-linux.zip

# Install Android SDK
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${OWN_COMMAND_LINE_TOOLS_VERSION}_latest.zip \
 && unzip commandlinetools-linux-${OWN_COMMAND_LINE_TOOLS_VERSION}_latest.zip                                            \
 && rm commandlinetools-linux-${OWN_COMMAND_LINE_TOOLS_VERSION}_latest.zip                                               \
 && mkdir -p /usr/local/android-sdk/cmdline-tools                                                                        \
 && mv cmdline-tools /usr/local/android-sdk/cmdline-tools/latest

# We accept the Android SDK licenses
RUN yes | sdkmanager --licenses

# Download and install Android NDK
RUN wget -q https://dl.google.com/android/repository/android-ndk-r${OWN_ANDROID_NDK_VERSION}e-linux-x86_64.zip \
 && unzip android-ndk-r${OWN_ANDROID_NDK_VERSION}e-linux-x86_64.zip -d /usr/local                              \
 && rm android-ndk-r${OWN_ANDROID_NDK_VERSION}e-linux-x86_64.zip

# Switch workspace
WORKDIR /workspace

# We download the source code of the SmartTube project from GitHub
RUN git clone https://github.com/yuliskov/SmartTube.git \
 && cd SmartTube                                        \
 && git checkout ${OWN_SMARTTUBE_TAG}                   \
 && git submodule update --init                         \
 # Small hack
 && cp -r SharedModules ..                              \
 && cp -r SharedModules MediaServiceCore                \
 && chmod +x gradlew

# Switch workspace
WORKDIR /workspace/SmartTube

# Connect to device - connect again on fail
RUN adb connect ${OWN_DEVICE_IP}                          \
 && echo "Connected to Android device (${OWN_DEVICE_IP})" \
 || adb connect ${OWN_DEVICE_IP}

# Build project
RUN ./gradlew clean installStorigDebug

