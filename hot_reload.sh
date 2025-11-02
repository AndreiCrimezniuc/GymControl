#!/bin/bash

# 1. Запускаем flutter только в симуляторе
flutter run -d 'iPhone 16' --pid-file=/tmp/flutter.pid &

# 2. Ждём пока PID появится
echo "⏳ Waiting for Flutter to start..."
while [ ! -f /tmp/flutter.pid ]; do sleep 1; done
echo "✅ Flutter PID file found"

# 3. Запускаем nodemon для наблюдения за изменениями
npx nodemon -e dart -x "cat /tmp/flutter.pid | xargs kill -s USR1"
