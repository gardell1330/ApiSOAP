FROM maloneweb/docker-wine-base:latest

ARG DEBIAN_FRONTEND="noninteractive"
ARG WINE_MONO_VERSION="4.7.3"

# XVFB
ARG DISPLAY=:0

# Wine
ARG WINEPREFIX=/root/.wine
ARG WINEARCH=win32

# Custom Helper Scripts
COPY scripts/waitforprocess.sh /usr/local/bin/waitforprocess.sh
COPY scripts/x11-start.sh /usr/local/bin/x11-start.sh

# Build Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Required for winetricks
    cabextract \
    p7zip \
    unzip \
    wget \
    xvfb \
    zenity \
    # Winetricks and Permissions
    && curl -s https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks > /usr/local/bin/winetricks \
    && chmod +x /usr/local/bin/winetricks \
    && chmod +x /usr/local/bin/*.sh \
    # Mono For Wine
    && mkdir /tmp/wine-mono \
    && wget https://dl.winehq.org/wine/wine-mono/${WINE_MONO_VERSION}/wine-mono-${WINE_MONO_VERSION}.msi -O /tmp/wine-mono/wine-mono-${WINE_MONO_VERSION} \ 
    # Install .NET Framework 2.0 and 4.6.2
    && wine wineboot --init \
    && waitforprocess.sh wineserver \
    && x11-start.sh \
    && winetricks --unattended -q --force dotnet461 dotnet_verifier    

# .NET Framework 4.6.1 Developer Pack installer requires X server
RUN set -x \
    curl -L -o /tmp/ndp461-devpack-kb3105179-enu.exe https://go.microsoft.com/fwlink/?linkid=2099470 \
    && export WINEDEBUG=-all \
    && xvfb-run wine /tmp/ndp461-devpack-kb3105179-enu.exe /q

# Copy Over Wine Prefix
FROM maloneweb/docker-wine-base:latest

ENV WINEPREFIX /root/.wine
ENV WINEARCH win32

RUN mkdir -p /usr/share/wine/mono

COPY --from=0 /root/.wine /root/.wine
COPY --from=0 /tmp/wine-mono /usr/share/wine/mono

RUN set -x \
    && curl -o /root/.wine/drive_c/windows/syswow64/nuget.exe https://dist.nuget.org/win-x86-commandline/v4.5.3/nuget.exe \
    && git clone https://github.com/gardell1330/ApiSOAP /app \
    && cd '/app/ApiSOAP' \
    && export WINEPATH='C:/windows/Microsoft.NET/Framework64/v4.0.30319' \
    && export WINEDEBUG=-all \
    && wine nuget install MSBuild.Microsoft.VisualStudio.Web.targets -Version 14.0.0.3 -OutputDirectory packages \
    && wine msbuild api_soap.sln \
        /p:VSToolsPath=../packages/MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3/tools/VSToolsPath

CMD bash