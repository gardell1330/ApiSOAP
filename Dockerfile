FROM debian:9.11
# Wine on Debian 9, see https://wiki.winehq.org/Debian
# Winetricks, see https://wiki.winehq.org/Winetricks#Installing_winetricks
# WINEDEBUG=-all to suppress Wine debug output
# .NET Runtime via Winetricks, install sequence:
#   v4.0 on WinXP, v4.5 on Win7, v4.6 on Win2003, v4.6.1 on Win7.
RUN set -x \
    && tempDeps='software-properties-common apt-transport-https gnupg wget curl cabextract' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $tempDeps \
    && dpkg --add-architecture i386 \
    && wget -qO - https://dl.winehq.org/wine-builds/winehq.key | apt-key add - \
    && apt-add-repository https://dl.winehq.org/wine-builds/debian/ \
    && apt-get update \
    && apt-get install -y --no-install-recommends winehq-staging \
    && curl -s https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks > /usr/local/bin/winetricks \
    && chmod +x /usr/local/bin/winetricks \
    && export WINEDEBUG=-all \
    && winetricks -q --force dotnet461 dotnet_verifier

# .NET Framework 4.6.1 Developer Pack installer requires X server
RUN set -x \
    && apt-get update \
    && apt-get -y install xvfb git \
    && curl -L -o /tmp/ndp461-devpack-kb3105179-enu.exe https://go.microsoft.com/fwlink/?linkid=2099470 \
    && export WINEDEBUG=-all \
    && xvfb-run wine /tmp/ndp461-devpack-kb3105179-enu.exe /q

## Various dev tools
#RUN set -x \
    #&& apt-get update \
    #&& apt-get -y install vim mc tree less locate procps net-tools

# Compile sample project based on ASP.NET Web Forms
# NuGet <= v4.5.3 works under Wine v4.16 Staging but NuGet v4.6.4+ crashes with Win32Exception
RUN set -x \
    && curl -o /root/.wine/drive_c/windows/syswow64/nuget.exe https://dist.nuget.org/win-x86-commandline/v4.5.3/nuget.exe \
    && git clone https://github.com/gardell1330/ApiSOAP /app \
    && cd '/app/apisoap' \
    && export WINEPATH='C:/windows/Microsoft.NET/Framework64/v4.0.30319' \
    && export WINEDEBUG=-all \
    && wine nuget install MSBuild.Microsoft.VisualStudio.Web.targets -Version 14.0.0.3 -OutputDirectory packages \
    && wine msbuild ApiSOAP.sln \
        /p:VSToolsPath=../packages/MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3/tools/VSToolsPath
CMD bash