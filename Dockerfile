FROM cvisionai/wget AS download

ENV MICROSOFT_PROD_URL='https://packages.microsoft.com/config/ubuntu/22.10/packages-microsoft-prod.deb'
ENV LOVE_URL='https://github.com/love2d/love/releases/download/11.3/love-11.3-linux-x86_64.tar.gz'
ENV MONOKICK_URL='https://github.com/flibitijibibo/MonoKickstart/archive/refs/heads/master.tar.gz'

RUN wget --output-document=packages-microsoft-prod.deb $MICROSOFT_PROD_URL \
    && wget --output-document=love.tar.gz $LOVE_URL \
    && mkdir love \
    && tar --extract --verbose --file=love.tar.gz -C love \
    && rm --force love.tar.gz \
    && wget --output-document=MonoKickstart.tar.gz $MONOKICK_URL \
    && mkdir MonoKickstart \
    && tar --extract --verbose --file=MonoKickstart.tar.gz -C MonoKickstart \
    && rm --force MonoKickstart.tar.gz

FROM ubuntu

WORKDIR /workspaces/

COPY --from=download packages-microsoft-prod.deb .

# dotnet-sdk-7.0 for building with dotnet
# libgl1-mesa-glx for opengl and display passthrough
# libpulse0 libasound2 libasound2-plugins for audio passthrough

RUN apt-get update \
    && apt-get install -y \
        luarocks \
        libgtk-3-dev \
        libgl1-mesa-glx \
        libpulse0 libasound2 libasound2-plugins \
        ca-certificates \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y \
        dotnet-sdk-7.0 \
    && rm packages-microsoft-prod.deb \
    && rm -rf /var/lib/apt/lists/*

COPY . .

COPY --from=download ./love .

RUN mv love/dest/* love/ \
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

RUN cd src \
    && zip -9 -r love/olympus.love . \
    && cd ..

COPY --from=download ./MonoKickstart .

RUN mv MonoKickstart/precompiled/kick.bin.x86_64 MonoKickstart/precompiled/Olympus.Sharp.bin.x86_64 \
    && rm -f MonoKickstart/precompiled/kick.bin.x86_64.debug \
    && cp -r MonoKickstart/precompiled/ love/sharp/ \
    && rm -rf MonoKickstart

    #&& echo "${env:BUILD_BUILDNUMBER}-azure-${env:BUILD_BUILDID}-$(($env:BUILD_SOURCEVERSION).Substring(0, 5))" | Set-Content src/version.txt
RUN cp olympus.sh love/olympus.sh \
    && chmod a+rx love/olympus.sh \
    && rm love/lib/x86_64-linux-gnu/libz.so.1 \
    && rm love/usr/lib/x86_64-linux-gnu/libfreetype.so.6

USER $AUDIO_USER