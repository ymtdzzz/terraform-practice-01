## Getting started

- generate ENCRYPT_KEY to `key.txt` (32 strings)
- copy `.env.example` to `.env`
- `docker-compose build --build-arg ENCRYPT_KEY=$(cat ./laravel/key.txt)`
- `docker-compose up`