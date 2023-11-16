FROM node:14.21.2-alpine3.16 as installer
COPY . /juice-shop
WORKDIR /juice-shop
RUN apk add --no-cache make
RUN apk add build-base
RUN apk add --no-cache libstdc++6
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools

#Set Registry to Nexus Repo
# RUN npm config set strict-ssl false
# RUN npm config set registry https://nexus.nsth.net/repository/npm-proxy/
# RUN npm config set always-auth=true
# RUN npm config set _auth ${NEXUS_AUTH}

RUN npm i -g typescript ts-node
RUN npm install --omit=dev --unsafe-perm
RUN npm install --save trend_app_protect
RUN cat package-lock.json
RUN npm dedupe
RUN rm -rf frontend/node_modules
RUN rm -rf frontend/.angular
RUN rm -rf frontend/src/assets
RUN mkdir logs && \
    chown -R 65532 logs && \
    chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/ && \
    chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/
USER 65532
EXPOSE 3000
CMD ["/juice-shop/build/app.js"]