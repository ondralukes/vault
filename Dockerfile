FROM node:10

WORKDIR /usr/src/app

COPY ./src/package*.json ./

RUN npm install

COPY ./src/ .

EXPOSE 8080

RUN npm install browserify -g
RUN chmod +x browserify.sh
RUN ./browserify.sh

CMD ["node", "server.js"]
