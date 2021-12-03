#!/usr/bin/env bash
flutter build apk --release && \
flutter build web --release && \
firebase deploy --only hosting
