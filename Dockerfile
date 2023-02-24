FROM ubuntu

WORKDIR /workspaces/

# dotnet-sdk-7.0 for building with dotnet
# libgl1-mesa-glx for opengl and display passthrough
# libpulse0 libasound2 libasound2-plugins for audio passthrough

RUN wget https://packages.microsoft.com/config/ubuntu/22.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && sudo dpkg -i packages-microsoft-prod.deb \
    && sudo apt-get update \
    && sudo apt-get install -y \
        luarocks \
        libgtk-3-dev \
        dotnet-sdk-7.0 \
        libgl1-mesa-glx \
        libpulse0 libasound2 libasound2-plugins \
    && rm packages-microsoft-prod.deb \
    && sudo rm -rf /var/lib/apt/lists/*

ENV LOVEURL='https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz'
ENV LOVETAR='love.tar.gz'

RUN wget $LOVEURL -O $LOVETAR \
    && mkdir love \
    && tar xvf $LOVETAR -C love \
    && rm -f $LOVETAR \
    && mv love/dest/* love/ \
    && rmdir love/dest

ENV LUAROCKSPREARGS=
ENV LUAROCKSARGS=
#'LUA_LIBDIR="/usr/local/opt/lua/lib"'

RUN luarocks config lua_version 5.1 \
    && luarocks \
    && luarocks $LUAROCKSPREARGS install --tree=luarocks https://raw.githubusercontent.com/0x0ade/lua-subprocess/master/subprocess-scm-1.rockspec $LUAROCKSARGS \
    && luarocks $LUAROCKSPREARGS install --tree=luarocks https://raw.githubusercontent.com/Vexatos/nativefiledialog/master/lua/nfd-scm-1.rockspec $LUAROCKSARGS \
    && luarocks $LUAROCKSPREARGS install --tree=luarocks lsqlite3complete $LUAROCKSARGS \
    && cp luarocks/lib/lua/**/* love/ \
    && rm -rf luarocks/

RUN mkdir -p love/sharp \
    && cp lib-linux/**/* love/sharp \
    && cp lib-mono/* love/sharp

ENV netBuildPlatform='Any CPU'
ENV netBuildConfiguration='Release'

RUN dotnet restore sharp/*.csproj \
    && dotnet msbuild sharp/*.sln "/p:Configuration=$netBuildConfiguration" "/p:Platform=$netBuildPlatform" \
    && cp --remove-destination \
        $(find sharp/bin/Release/**/ -type f -and ! \( \
            -name 'xunit.*' \
            -or -name 'System.*' \
            -or -name 'Microsoft.*' \
            -or -name '*.Tests.dll' \
            -or -name '*.pdb' \
        \)) \
        love/sharp \
    && rm -rf sharp/bin/

RUN zip -9 -r love/olympus.love src/

ENV MONOKICKURL='https://github.com/flibitijibibo/MonoKickstart.git'

RUN git clone --depth 1 $MONOKICKURL \
    && mv MonoKickstart/precompiled/kick.bin.x86_64 MonoKickstart/precompiled/Olympus.Sharp.bin.x86_64 \
    && rm -f MonoKickstart/precompiled/kick.bin.x86_64.debug \
    && cp -r MonoKickstart/precompiled/ love/sharp/ \
    && rm -rf MonoKickstart

    #&& echo "${env:BUILD_BUILDNUMBER}-azure-${env:BUILD_BUILDID}-$(($env:BUILD_SOURCEVERSION).Substring(0, 5))" | Set-Content src/version.txt
RUN cp olympus.sh love/olympus.sh \
    && chmod a+rx love/olympus.sh \
    && rm love/lib/x86_64-linux-gnu/libz.so.1 \
    && rm love/usr/lib/x86_64-linux-gnu/libfreetype.so.6
