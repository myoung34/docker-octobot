FROM alpine:latest

RUN apk add -U --no-cache imagemagick nodejs yarn curl

RUN mkdir -p /opt/hubot/scripts/
COPY package.json /opt/hubot/
WORKDIR /opt/hubot
RUN yarn install

COPY . /opt/hubot/
ENV PATH $PATH:/opt/hubot/node_modules/.bin

VOLUME /opt/hubot/images

CMD hubot --adapter slack --name $HUBOT_NAME
