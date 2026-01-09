# Kurulum ve Çalıştırma Adımları

Projeyi yerel makinede çalıştırmak için aşağıdaki adımları izleyin.

## Ön Koşullar

Bilgisayarınızda aşağıdaki araçların kurulu olması gerekmektedir:
- Flutter SDK
- Git
- Android Emülatör veya fiziksel bir Android cihaz

## 1. Projeyi İndirme

Proje dosyalarını GitHub deposundan klonlayın veya zip dosyasından çıkarın:
```bash
git clone <repository-url>
cd <proje-dizini>
```

## 2. Bağımlılıkların Yüklenmesi

Terminalde proje dizinine giderek gerekli paketleri indirin:
```bash
flutter pub get
```

## 3. Firebase Yapılandırması

Firebase entegrasyonu için aşağıdaki adımları tamamlayın:

- Projenizin [Firebase Console](https://console.firebase.google.com/) üzerinden oluşturulan proje ile eşleştiğinden emin olun
- Güncel `google-services.json` dosyasını `android/app/` dizinine yerleştirin
- Terminalde aşağıdaki komutu çalıştırarak `firebase_options.dart` dosyasını güncelleyin:
```bash
flutterfire configure
```

## 4. Uygulamanın Başlatılması

- Android emülatörünü başlatın
- Terminalde veya IDE üzerinde aşağıdaki komutu çalıştırın:
```bash
flutter run
```

## 5. İzinler

Uygulamanın düzgün çalışması için `AndroidManifest.xml` dosyasında internet izninin (`android.permission.INTERNET`) tanımlı olduğundan emin olun.
```xml
<uses-permission android:name="android.permission.INTERNET" />
```
