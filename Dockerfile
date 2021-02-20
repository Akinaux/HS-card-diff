FROM ubuntu:18.04

RUN apt update && \
apt-get install -y curl diffutils wget jq && \
mkdir /Hearthstone
COPY cards_diff.sh /Hearthstone/
