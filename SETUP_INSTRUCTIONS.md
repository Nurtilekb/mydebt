# Инструкция по настройке Google Sign-In

## Проблема
Google Sign-In не работает, потому что SHA1 ключ отладочного сертификата не добавлен в Firebase Console.

## Решение

### Шаг 1: Получить SHA1 ключ
SHA1 ключ для debug сборки уже сгенерирован:
```
94:F2:96:8A:20:1D:B0:22:35:A0:28:26:37:E0:4A:9D:26:A2:9E:98
```

### Шаг 2: Добавить SHA1 в Firebase Console
1. Откройте Firebase Console: https://console.firebase.google.com/project/for-a-debt/settings/general/android:com.example.mydebt
2. Найдите раздел "SHA certificate fingerprints"
3. Нажмите "Add fingerprint"
4. Вставьте SHA1: `94:F2:96:8A:20:1D:B0:22:35:A0:28:26:37:E0:4A:9D:26:A2:9E:98`
5. Сохраните изменения

### Шаг 3: Обновить google-services.json
1. После добавления SHA1, скачайте обновленный файл `google-services.json` из Firebase Console
2. Замените текущий файл `/workspace/android/app/google-services.json` на новый

### Шаг 4: Пересобрать приложение
```bash
flutter clean
flutter pub get
flutter run
```

## UI улучшения
- Добавлена подсказка с SHA1 ключом на экране авторизации
- Добавлено диалоговое окно при ошибке входа с указанием возможных причин
- Интерфейс стилизован под iPhone (Cupertino дизайн)

## Примечание
Для production сборки нужно будет получить SHA1 от release ключа и также добавить его в Firebase Console.
