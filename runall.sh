#!/usr/bin/env bash

./asm-metrics-aggregator-loop.sh
./asm-metrics-synth.sh
./asm-diskgroup-breakout.sh
./asm-metrics-chart-synth.sh

