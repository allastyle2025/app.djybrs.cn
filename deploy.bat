@echo off
echo Building APK...
flutter build apk --release && (
    echo Build successful, copying to server...
    scp build\app\outputs\flutter-apk\app-release.apk root@192.168.10.68:~/Downloads/apk/ && (
        echo Done!
    ) || (
        echo SCP failed!
    )
) || (
    echo Build failed!
)