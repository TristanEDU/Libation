FROM --platform=${BUILDPLATFORM} mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG TARGETARCH

COPY Source /Source
RUN dotnet publish \
    /Source/LibationAvalonia/LibationAvalonia.csproj \
    --os linux \
    --arch ${TARGETARCH} \
    --configuration Release \
    --output /Source/bin/Publish/Linux-avalonia \
    -p:PublishProtocol=FileSystem \
    -p:PublishReadyToRun=true \
    -p:SelfContained=true

FROM mcr.microsoft.com/dotnet/runtime-deps:10.0
ARG USER_UID=1001
ARG USER_GID=1001

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DISPLAY=:1
ENV LIBATION_HOME=/config

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        fluxbox \
        novnc \
        websockify \
        x11vnc \
        xvfb \
    && groupadd --gid ${USER_GID} libation \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash libation \
    && mkdir -p /libation /config /data \
    && chown -R libation:${USER_GID} /libation /config /data /home/libation

COPY --from=build /Source/bin/Publish/Linux-avalonia /libation
COPY Docker/webui/start-webui.sh /usr/local/bin/start-webui.sh

RUN chmod +x /usr/local/bin/start-webui.sh

USER libation
WORKDIR /home/libation

EXPOSE 6080
VOLUME ["/config", "/data"]

CMD ["/usr/local/bin/start-webui.sh"]
