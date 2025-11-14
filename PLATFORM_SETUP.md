# Platform Configuration Guide

This guide explains how to configure platform-specific permissions for the Diet Tracking App.

## Android Configuration

### 1. AndroidManifest.xml

Add the following permissions to your `android/app/src/main/AndroidManifest.xml` file:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required for camera access -->
    <uses-permission android:name="android.permission.CAMERA"/>
    
    <!-- Required for accessing photos from gallery -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <!-- For Android 13+ media access -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    
    <!-- Required for internet access -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application
        android:label="meal_management_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- Your activity configurations -->
    </application>
</manifest>
```

### 2. build.gradle

Ensure minimum SDK version is at least 21 in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
    }
}
```

## iOS Configuration

### 1. Info.plist

Add the following keys to your `ios/Runner/Info.plist` file:

```xml
<dict>
    <!-- Camera access description -->
    <key>NSCameraUsageDescription</key>
    <string>음식 사진을 찍어 영양 정보를 분석하기 위해 카메라 접근이 필요합니다.</string>
    
    <!-- Photo library access description -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>갤러리에서 음식 사진을 선택하기 위해 사진 라이브러리 접근이 필요합니다.</string>
    
    <!-- For iOS 14+ -->
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>음식 사진을 저장하기 위해 사진 라이브러리 접근이 필요합니다.</string>
    
    <!-- Network security for HTTP requests -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
```

### 2. Podfile

Ensure platform version is at least 12.0 in `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

## Running the App

After adding these configurations:

1. For Android:
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

2. For iOS:
   ```bash
   flutter clean
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter run
   ```

## Testing Camera/Gallery Access

When you first try to use the camera or gallery features:
1. The app will request permissions from the user
2. User must grant permissions for the features to work
3. On Android, you may need to grant storage permissions in app settings
4. On iOS, permissions are requested automatically with the usage descriptions

## Troubleshooting

### Android Issues

- **Permission denied**: Check that all permissions are in AndroidManifest.xml
- **Camera not opening**: Verify CAMERA permission and minSdkVersion >= 21
- **Gallery access fails**: For Android 13+, ensure READ_MEDIA_IMAGES is added

### iOS Issues

- **Permission dialog not showing**: Verify all NSUsageDescription keys are in Info.plist
- **Build errors**: Run `pod install` in ios directory
- **Camera crashes**: Check Info.plist has NSCameraUsageDescription

## Additional Notes

- The app stores food data locally using SharedPreferences
- Camera quality is limited to 1024x1024 pixels for performance
- Images are compressed to 85% quality to reduce storage
