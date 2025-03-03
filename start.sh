#!/bin/bash

# Ensure Dart is installed
if ! command -v dart &> /dev/null
then
    echo "Dart is not installed. Please install Dart first."
    exit 1
fi

# Run the Dart script
dart lib/main.dart "$@"
