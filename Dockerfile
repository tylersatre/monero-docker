FROM ubuntu:bionic AS build

# Version and has of version used to check the download
ENV VERSION=0.16.0.0
ENV MONERO_ARCHIVE_HASH=e507943b46e9d7c9ccdb641dcccb9d8205dd9de660a0ab5566dac5423f8b95e2

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y wget

WORKDIR /root

RUN wget -O monero-linux-x64-v${VERSION}.tar.bz2 https://downloads.getmonero.org/cli/linux64
# The image build will fail if the hash doesn't match
RUN [[ $(sha256sum monero-linux-x64-v${VERSION}.tar.bz2) = *${MONERO_ARCHIVE_HASH}* ]]

RUN tar -xvf monero-linux-x64-v${VERSION}.tar.bz2
RUN rm monero-linux-x64-v${VERSION}.tar.bz2
RUN cp ./monero-x86_64-linux-gnu-v${VERSION}/monerod .
RUN rm -r monero-*


FROM ubuntu:bionic

# Create non root user and switch
RUN useradd -ms /bin/bash monero
RUN mkdir -p /home/monero/.bitmonero && chown -R monero:monero /home/monero/.bitmonero
USER monero
WORKDIR /home/monero

COPY --chown=monero:monero --from=build /root/monerod /home/monero/monerod

# blockchain loaction
VOLUME ["/home/monero/.bitmonero"]

EXPOSE 18080 18081

ENTRYPOINT ["./monerod"]
# See https://monerodocs.org/interacting/monerod-reference/
CMD ["--non-interactive","--enforce-dns-checkpointing","--restricted-rpc", "--rpc-bind-ip=0.0.0.0", "--confirm-external-bind"]