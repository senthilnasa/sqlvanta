<div align="center">

  <img src="https://raw.githubusercontent.com/senthilnasa/sqlvanta/main/res/logo_head.png" alt="SQLvanta Logo" width="180"/>
  
  # SQLvanta 🚀
  
  **The Next-Generation, Open-Source Database GUI for Modern Developers.**
  
  <p align="center">
    <a href="https://github.com/senthilnasa/sqlvanta/stargazers"><img src="https://img.shields.io/github/stars/senthilnasa/sqlvanta?style=social" alt="Stars Badge"/></a>
    <a href="https://github.com/senthilnasa/sqlvanta/network/members"><img src="https://img.shields.io/github/forks/senthilnasa/sqlvanta?style=social" alt="Forks Badge"/></a>
    <a href="https://sqlvanta.senthilnasa.me"><img src="https://img.shields.io/badge/Website-Live-brightgreen?style=flat&logo=google-chrome" alt="Website"/></a>
    <a href="https://github.com/senthilnasa/sqlvanta/issues"><img src="https://img.shields.io/github/issues/senthilnasa/sqlvanta" alt="Issues"/></a>
    <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"/></a>
  </p>

  [**⭐ Give us a Star if you love SQLvanta!⭐**](#)

  *Blazing fast • 100% Free & Open-Source • Cross-Platform (Mac, Windows, Linux, Web)*

</div>

<br/>

## 🎯 What is SQLvanta?
Tired of slow, Electron-based, or wildly expensive database clients? So were we. 

**SQLvanta** is a lightning-fast, native SQL execution and database management tool built entirely in Flutter. Engineered for **speed and developer joy**, it brings a beautiful UI and a world-class Visual Schema ERD Designer directly to your desktop or browser.

Whether you're managing complex enterprise MySQL architectures or tweaking a small weekend side-project DB, SQLvanta gets out of your way and makes database management a fluid, 60-FPS experience.

<div align="center">
  <br/>
  
  [![Share on X / Twitter](https://img.shields.io/badge/Share_on_X_/%_Twitter-000000?style=for-the-badge&logo=x&logoColor=white)](https://twitter.com/intent/tweet?text=I%20just%20found%20this%20amazing%20Open-Source%20Database%20Manager%20SQLvanta!%20🚀%20Check%20it%20out:%20https://github.com/senthilnasa/sqlvanta)
  [![Share on LinkedIn](https://img.shields.io/badge/Share_on_LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/sharing/share-offsite/?url=https://github.com/senthilnasa/sqlvanta)
  [![Hunt on Product Hunt](https://img.shields.io/badge/Product_Hunt-DA552F?style=for-the-badge&logo=product-hunt&logoColor=white)](#)
</div>

---

## 🔥 Why SQLvanta is taking over

Search the internet for an "Open-Source macOS MySQL client" or a "Free Windows DB Manager" and you'll find outdated, heavy, or paid tools. **We fixed that.**

✅ **Interactive Visual Designer**: Reverse-engineer your databases instantly into stunning ER Diagrams. Drag, drop, analyze relationships, and export!
✅ **Zero Telemetry, 100% Privacy**: Your credentials and data are encrypted locally. We track *nothing*.
✅ **Native Speed**: By leveraging the Flutter Engine and pure-Dart execution environments, SQLvanta outpaces web-wrapper alternatives on memory and CPU.
✅ **Dark Mode by Default**: Tailored color palettes for developers who code at 2 AM.

---

## 📸 Sneak Peek
> *(Pro tip: Drop your `.png` or `.gif` UI recordings in `docs/assets/` to automatically render them here!)*

| 🗃️ Advanced Workspace Layout | 🗺️ Dynamic Schema Visualizer |
| :---: | :---: |
| *(Image 1 Placeholder)*<br>`docs/assets/dashboard.gif` | *(Image 2 Placeholder)*<br>`docs/assets/schema.png` |

---

## 📥 Download SQLvanta

Skip the build process and download the pre-compiled, insanely fast native binaries. SQLvanta is fully CI/CD automated via GitHub Actions.

[![Download Latest Release](https://img.shields.io/github/v/release/senthilnasa/sqlvanta?label=Latest%20Stable%20Release&style=for-the-badge&color=brightgreen)](https://github.com/senthilnasa/sqlvanta/releases/latest)

Choose your platform below to get the latest executable:
- 🪟 [**Download for Windows (.zip)**](https://github.com/senthilnasa/sqlvanta/releases/latest/download/sqlvanta-windows.zip)
- 🍏 [**Download for macOS (.zip)**](https://github.com/senthilnasa/sqlvanta/releases/latest/download/sqlvanta-macos.zip)
- 🐧 [**Download for Linux (.tar.gz)**](https://github.com/senthilnasa/sqlvanta/releases/latest/download/sqlvanta-linux.tar.gz)
- 🤖 [**Download for Android (.apk)**](https://github.com/senthilnasa/sqlvanta/releases/latest/download/sqlvanta-android.apk)

*(Note: macOS and Windows binaries may require bypassing the "Unidentified Developer" prompt on first launch since the open-source auto-builds are currently unsigned.)*

---

## ⚡ Quick Start Guide
Get SQLvanta running locally in **under 2 minutes**:

```bash
# 1. Clone the repository
git clone https://github.com/senthilnasa/sqlvanta.git

# 2. Enter directory
cd sqlvanta

# 3. Resolve ultra-fast dependencies
flutter pub get

# 4. Generate Riverpod & Drift files
dart run build_runner build --delete-conflicting-outputs

# 5. Launch the beast!
flutter run -d macos  # or windows, linux, web
```

---

## 💖 Join the Revolution
SQLvanta is exploding in growth, and we want **you** to be a part of it. The easiest way to support us?

1. **Star this Repo:** (It helps us trend on GitHub!)
2. **Spread the Word:** Share the project on Twitter, Reddit (r/FlutterDev, r/Database, r/Programming), and Hacker News.
3. **Contribute:** Grab an issue labeled `good first issue`. We actively mentor contributors!

### Core Contributors & Maintainers
A massive thank you to the team who brings this project to life.
- **[Senthilnasa](#)** - Creator & Architect.

*(Want to see your name here? [Read our CONTRIBUTING.md](CONTRIBUTING.md) and open a PR!)*

---

## 🛡️ Secure & Licensed
SQLvanta takes your data security seriously by using native OS Keychains (DPAPI on Windows, Keychain on macOS) for local password vaults. 

📝 Released under the **MIT License**. Free to fork, free to use, free forever.
