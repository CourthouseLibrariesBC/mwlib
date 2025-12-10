FROM base

RUN apt-get update && apt-get install -y pdftk-java && rm -rf /var/lib/apt/lists/*

RUN mkdir /app/cache

COPY . /app
WORKDIR /app

RUN pip install .

ENV PORT=9123
EXPOSE 9123
