#!/bin/bash

docker run --rm -i -t --name fluent-plugin-dev -v $(pwd):/app fluent-plugin-dev /bin/bash