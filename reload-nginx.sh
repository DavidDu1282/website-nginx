#!/bin/sh
docker-compose -f /path/to/your/docker-compose.yml exec -T nginx nginx -s reload