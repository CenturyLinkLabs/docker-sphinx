#!/bin/bash

indexer --all "$@" && searchd && while true; do indexer --all --rotate "$@"; sleep 5; done
