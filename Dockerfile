FROM ubuntu:18.04

RUN apt update && \
apt-get install -y curl git diffutils wget jq && \
mkdir /Hearthstone && \
git clone https://github.com/Akinaux/HS-card-diff.git /Hearthstone
