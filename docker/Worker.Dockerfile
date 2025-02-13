FROM base

RUN mkdir /app/cache

COPY . /app
WORKDIR /app

RUN pip install .

ENV PORT=9123
EXPOSE 9123
