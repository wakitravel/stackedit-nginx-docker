ARG ALPINE_VERSION=3.10
ARG GO_VERSION=1.13.0
ARG STACKEDIT_VERSION=v5.14.5

# Compilamos stackedit.
FROM alpine:${ALPINE_VERSION} AS stackedit
ARG STACKEDIT_VERSION
WORKDIR /stackedit
RUN apk add -q --progress --update --no-cache git npm python2
RUN wget -q https://github.com/benweet/stackedit/archive/${STACKEDIT_VERSION}.tar.gz -O stackedit.tar.gz && \
    tar -xzf stackedit.tar.gz --strip-components=1 && \
    rm stackedit.tar.gz
RUN npm install
RUN npm audit fix
ENV NODE_ENV=production
RUN sed -i "s/assetsPublicPath: '\/',/assetsPublicPath: '.\/',/g" config/index.js && cat config/index.js
RUN npm run build

# Nos basamos en NGINX ALPINE que viene con envsubst
FROM nginx:alpine

COPY --from=stackedit --chown=101 /stackedit/dist   /html/dist
COPY --from=stackedit --chown=101 /stackedit/static /html/static
COPY conf.d/default.conf.template /etc/nginx/conf.d/

# El comando por defecto
CMD /bin/sh -c "envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'"
