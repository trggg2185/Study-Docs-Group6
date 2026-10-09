# Firebase Setup cho StudyDocs

Tài liệu này hướng dẫn cấu hình Firebase cho ứng dụng Flutter StudyDocs, bao gồm Firebase Core, đăng nhập Google, Android và Web.

## Firebase project hiện tại

- Project ID: `study-docs-group6`
- Firebase options: `lib/firebase_options.dart`
- Android config: `android/app/google-services.json`
- FlutterFire metadata: `firebase.json`

Không tạo project mới nếu đang cấu hình cho nhóm này. Mỗi thành viên cần được mời vào project Firebase với quyền phù hợp trước khi chạy FlutterFire CLI.

## 1. Cài công cụ

Cần cài Flutter/Dart và Node.js LTS. Mở PowerShell tại thư mục dự án và cài Firebase CLI cùng FlutterFire CLI:

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

Nếu Windows không nhận các lệnh `firebase` hoặc `flutterfire`, thêm các thư mục cài đặt vào `PATH` của phiên PowerShell hiện tại:

```powershell
$env:Path += ";C:\Program Files\nodejs;$env:APPDATA\npm;$env:LOCALAPPDATA\Pub\Cache\bin"
```

Có thể gọi trực tiếp các launcher `.cmd`/`.bat` nếu PowerShell chặn script:

```powershell
& "$env:APPDATA\npm\firebase.cmd" --version
& "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire.bat" --version
```

## 2. Đăng nhập và cấu hình app

Đăng nhập Firebase CLI bằng tài khoản đã được cấp quyền:

```powershell
firebase login
firebase projects:list
```

Trong danh sách, xác nhận có project `study-docs-group6`. Từ thư mục gốc của dự án, đăng ký/cập nhật cấu hình cho Android, iOS và Web:

```powershell
flutterfire configure --project=study-docs-group6 --platforms=android,ios,web
```

Nếu lệnh không được nhận diện trên Windows, dùng đường dẫn launcher:

```powershell
& "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire.bat" configure --project=study-docs-group6 --platforms=android,ios,web
```

FlutterFire tạo/cập nhật `lib/firebase_options.dart` và cấu hình native mà nền tảng được chọn yêu cầu. Kiểm tra file được cập nhật trong Git trước khi commit. Nếu thêm một platform mới sau này, chạy lại lệnh trên với platform đó.

Các package Firebase hiện dùng trong dự án được khai báo trong `pubspec.yaml`: `firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore` và `firebase_storage`.

## 3. Khởi tạo Firebase

Firebase phải được khởi tạo trước khi tạo hoặc sử dụng `FirebaseAuth`, Firestore hay Storage. Dự án thực hiện bước này trong `lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

Giữ `WidgetsFlutterBinding.ensureInitialized()` trước `Firebase.initializeApp()` và import `lib/firebase_options.dart`.

## 4. Bật Google Sign-In

Trong [Firebase Console](https://console.firebase.google.com/):

1. Mở project `study-docs-group6`.
2. Vào **Authentication** và chọn **Get started** nếu Authentication chưa được thiết lập.
3. Trong **Sign-in method** (hoặc **Sign-in providers**), chọn **Google**, bật provider, chọn email hỗ trợ rồi lưu.

### Web

Ứng dụng Web gọi Firebase Auth popup. Trong **Authentication → Settings → Authorized domains**, cần có domain đang dùng để mở app, thường là `localhost` khi chạy bằng `flutter run -d chrome`. Thêm domain triển khai thực tế trước khi phát hành. Không cần SHA-1 cho đăng nhập Web.

### Android

Ứng dụng Android hiện đăng ký với package name `com.example.test_flutter` trong Firebase. Nếu thay `applicationId` trong `android/app/build.gradle.kts`, phải đăng ký Android app tương ứng trong Firebase rồi chạy lại `flutterfire configure`.

Google Sign-In trên Android cần SHA-1 của chứng chỉ ký ứng dụng. Nếu Gradle wrapper có trong project, chạy ở thư mục `android`:

```powershell
.\gradlew.bat signingReport
```

Trong kết quả, tìm `Variant: debug` và sao chép fingerprint `SHA1`. Nếu wrapper không có hoặc lệnh trên không chạy, sau khi Android debug keystore đã được tạo, có thể đọc fingerprint bằng:

```powershell
keytool -list -v -alias androiddebugkey `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android -keypass android
```

Thêm SHA-1 tại **Project settings → General → Your apps → Android app → Add fingerprint**. Bản phát hành cần fingerprint từ release keystore riêng. Sau khi cập nhật fingerprint/provider, chạy lại `flutterfire configure` và dùng cấu hình Android mới nhất.

## 5. Chạy và kiểm tra

Sau khi cập nhật cấu hình:

```powershell
flutter pub get
flutter run -d chrome
```

Để chạy Android, mở emulator hoặc kết nối thiết bị rồi chạy:

```powershell
flutter run
```

## Xử lý lỗi thường gặp

- **`configuration-not-found`**: kiểm tra đã bật Google provider trong Firebase Authentication chưa, và ứng dụng đang dùng đúng `projectId` trong `lib/firebase_options.dart`.
- **`operation-not-allowed`**: Google provider chưa được bật trong Authentication.
- **`unauthorized-domain`**: thêm chính xác hostname của ứng dụng vào **Authentication → Settings → Authorized domains**.
- **Không thấy project trong `flutterfire configure`**: đăng nhập đúng tài khoản Firebase và xác nhận tài khoản đã được mời vào project.
- **Android báo lỗi cấu hình Google/OAuth**: xác nhận package name khớp, thêm SHA-1 debug/release thích hợp, rồi cấu hình lại bằng FlutterFire CLI.
- **PowerShell báo không nhận lệnh hoặc chặn script**: kiểm tra `PATH` theo mục 1 và gọi launcher `firebase.cmd`/`flutterfire.bat` trực tiếp.

## Lưu ý bảo mật

Các file cấu hình client như `firebase_options.dart` và `google-services.json` là thông tin cấu hình ứng dụng, không thay thế cơ chế phân quyền. Bảo vệ dữ liệu bằng Firebase Security Rules phù hợp; không đưa service-account private key hoặc thông tin xác thực máy chủ vào ứng dụng hay repository.
