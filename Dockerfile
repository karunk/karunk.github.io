FROM sparanoid/almace-scaffolding:latest

ADD ./_app/_pages/ /app/_app/_pages/
ADD ./_app/_layouts/ /app/_app/_layouts/
ADD ./_app/_includes/ /app/_app/_includes/
ADD ./_app/_data/ /app/_app/_data/
ADD ./_app/_posts/ /app/_app/_posts/
ADD ./_config.yml /app/_config.yml
ADD ./_app/assets /app/_app/assets

RUN ls

EXPOSE 4321 4321

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
