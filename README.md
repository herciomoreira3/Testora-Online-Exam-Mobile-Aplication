# Testora - Aplikasaun Teste Online (MVP) 🎓

Testora mak aplikasaun mobile (Android & iOS) ne'ebé dezenvolve espesiál ba estudante eskola no universidade sira iha Timor-Leste. Aplikasaun ne'e permite uzuáriu sira atu tuir teste online ho interface ne'ebé uza 100% **Lian Tetun**.

## 🚀 Rekursu Prinsipál
- **Autentikasaun Seguru**: Tama (Login) no Rejista uza Firebase Authentication.
- **Lista Teste**: Haree lista teste sira ne'ebé disponivel no ativu.
- **Tuir Teste (Temporizadór Real-time)**: Sistema teste interativu ho tempu ne'ebé konta tun (countdown).
- **Rezultadu & Istória**: Haree pontu (skor) kedas hafoin remata teste no mós haree istória teste sira ne'ebé tuir ona.
- **Lokalizasaun Kompletu**: Interface aplikasaun 100% uza Lian Tetun.

## 🛠️ Teknolojia & Arkitetura
Aplikasaun ne'e dezenvolve uza prinsipál **Clean Architecture (Feature-First)** atu garante kódigu sira estruturadu no fasil atu halo manutensaun.
- **Framework**: [Flutter](https://flutter.dev/) (>= 3.24.0)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Firestore)
- **State Management**: [Riverpod](https://riverpod.dev/) (`riverpod_annotation`)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Localization**: [easy_localization](https://pub.dev/packages/easy_localization)
- **Fonts**: [google_fonts](https://pub.dev/packages/google_fonts)

## 📁 Estrutura Diretóriu
```text
lib/
├── core/       # Konfigurasaun router, theme, localization, constants, dll.
├── features/   # Módulu aplikasaun (auth, exam, history, profile)
├── shared/     # Komponente globál (model, widget reusable, service)
└── main.dart   # Ponto de entrada (Entry point) aplikasaun nian
```

## ⚙️ Rekizitu Sistema nian (Prerequisites)
Garante katak komputadór ita boot nian instala ona:
- **Flutter SDK** (Versaun foun liu)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **FlutterFire CLI** (`dart pub global activate flutterfire_cli`)
- **GitHub Desktop** / **GitHub CLI** (`gh`)

## 💻 Oinsá Halai Projetu iha Lokál

1. **Clone Repozitóriu (Husi GitHub)**
   ```bash
   git clone https://github.com/<USERNAME_ANDA>/testora.git
   cd testora
   ```

2. **Instala Dependénsia sira**
   ```bash
   flutter pub get
   ```

3. **Jera Kódigu Riverpod & GoRouter (build_runner)**
   Tamba projetu ne'e uza `riverpod_annotation`, halai komandu ne'e hodi jera kódigu foun bainhira halo provider foun:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Konfigurasaun Firebase**
   Tamba projetu ne'e liga ona ba Firebase (`testora-ee95f`), garante katak `firebase_options.dart` jera ho loloos:
   ```bash
   firebase login
   flutterfire configure --project=testora-ee95f
   ```

5. **Halai Aplikasaun**
   ```bash
   flutter run
   ```

## 📝 Nota ba Dezenvolvimentu
- **Lian**: Teks foun hotu iha UI tenke tau iha laran ba file `assets/lang/tetun.json` no bolu uza sintaxe `.tr()` (ezemplu: `Text('login'.tr())`).
- **Baze de Dadus (Database)**: Skema no Security Rules Firestore define ona ho metin. Favór haree ba gia prinsipál (`issue.md`) antes atu modifika modelu dadus sira.

---
*Dezenvolve hodi apoia edukasaun dijitál iha Timor-Leste.* 🇹🇱
