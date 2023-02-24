FROM ubuntu

WORKDIR /workspaces/

RUN wget https://packages.microsoft.com/config/ubuntu/22.10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && sudo dpkg -i packages-microsoft-prod.deb \
    && sudo apt-get update \
    && sudo apt-get install -y \
        luarocks \
        libgtk-3-dev \
        libgl1-mesa-glx \
        libluajit-5.1-2 \
        love \
        dotnet-sdk-7.0 \
    && rm packages-microsoft-prod.deb \
    && rm -rf /var/lib/apt/lists/*

ENV LUAROCKSPREARGS=
ENV LUAROCKSARGS='LUA_LIBDIR="/usr/local/opt/lua/lib"'

RUN luarocks config lua_version 5.1 \
    && luarocks \
    && luarocks $LUAROCKSPREARGS install --tree=luarocks https://raw.githubusercontent.com/0x0ade/lua-subprocess/master/subprocess-scm-1.rockspec $LUAROCKSARGS \
    && luarocks $LUAROCKSPREARGS install --tree=luarocks https://raw.githubusercontent.com/Vexatos/nativefiledialog/master/lua/nfd-scm-1.rockspec $LUAROCKSARGS \
    && luarocks $LUAROCKSPREARGS install --tree=luarocks lsqlite3complete $LUAROCKSARGS

ENV netBuildPlatform='Any CPU'
ENV netBuildConfiguration='Release'

RUN dotnet restore sharp/*.csproj \
    && dotnet msbuild sharp/*.sln "/p:Configuration=$netBuildConfiguration" "/p:Platform=$netBuildPlatform"

RUN mkdir -p dist/sharp \
    && cp luarocks/lib/lua/**/* dist/ \
    && cp lib-linux/**/* dist/sharp \
    && cp lib-mono/* dist/sharp \
    && cp --remove-destination \
        $(find sharp/bin/Release/**/ -type f -and ! \( \
            -name 'xunit.*' \
            -or -name 'System.*' \
            -or -name 'Microsoft.*' \
            -or -name '*.Tests.dll' \
            -or -name '*.pdb' \
        \)) \
        dist/sharp

ENV MONOKICKURL='https://github.com/flibitijibibo/MonoKickstart.git'

RUN git clone --depth 1 $MONOKICKURL \
    && mv MonoKickstart/precompiled/kick.bin.x86_64 MonoKickstart/precompiled/Olympus.Sharp.bin.x86_64 \
    && rm -f MonoKickstart/precompiled/kick.bin.x86_64.debug \
    && cp -r MonoKickstart/precompiled/ dist/sharp/

    #&& echo "${env:BUILD_BUILDNUMBER}-azure-${env:BUILD_BUILDID}-$(($env:BUILD_SOURCEVERSION).Substring(0, 5))" | Set-Content src/version.txt
RUN cp olympus.sh love/$LOVEBINARYDIRECTORY/olympus.sh \
    && chmod a+rx love/$LOVEBINARYDIRECTORY/olympus.sh \
    && rm love/$LOVEBINARYDIRECTORY/lib/x86_64-linux-gnu/libz.so.1 \
    && rm love/$LOVEBINARYDIRECTORY/usr/lib/x86_64-linux-gnu/libfreetype.so.6 \
    && cd love \
    && mkdir love/$BUILD_ARTIFACTSTAGINGDIRECTORY/main \
    && zip --symlinks -r $BUILD_ARTIFACTSTAGINGDIRECTORY/main/dist.zip * \
    && cd ..