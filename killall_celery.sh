#!/bin/bash

ps aux | grep celery | grep -v grep | grep -v killall | awk '{print $2}' | xargs sudo kill -9
echo "Remaining celery nodes:"
ps aux | grep celery | grep -v grep | grep -v killall
