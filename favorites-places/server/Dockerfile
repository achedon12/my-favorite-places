FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm i

COPY . .

RUN npm run build

FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

COPY --from=build /app/node_modules ./node_modules

COPY --from=build /app/dist ./dist

CMD ["npm", "start"]