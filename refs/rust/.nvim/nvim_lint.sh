#!/bin/bash

cargo clippy --workspace --no-deps --message-format=short 2>&1 | head -n -2
