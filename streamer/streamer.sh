#!/bin/bash

echo "starting streamer"

/usr/bin/java -cp /usr/local/lib/R/site-library/AWR/java/*:/usr/local/lib/R/site-library/AWR.Kinesis/java/*:./     com.amazonaws.services.kinesis.multilang.MultiLangDaemon     ./app.properties
