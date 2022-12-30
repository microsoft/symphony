#!/usr/bin/env bash

foo=$(< /dev/urandom env LC_ALL=C tr -dc 'a-z' | fold -w 8 | head -n 1)

echo "$foo"