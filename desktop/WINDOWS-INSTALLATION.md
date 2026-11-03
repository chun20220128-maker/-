# 校園廚餘管理 Windows 單機版

適用 Windows 10／11 64 位元（x64）。手機請繼續使用網頁版，兩邊不會自動同步。

## 安裝

1. 到儲存庫 Releases，下載 `CampusFoodWaste-Setup-1.0.0-x64.exe`。
2. 執行安裝檔，依指示選擇安裝資料夾。
3. 安裝後從桌面或開始功能表點「校園廚餘管理」。

此安裝檔未使用付費程式碼簽章，Windows 可能顯示「未知的發行者」。請確認下載來源是此儲存庫；若校方設備政策禁止安裝，請資訊人員協助。可用 Release 附上的 `SHA256SUMS.txt` 核對檔案。

已保留既有介面、學年度班級與人數設定、CSV 歷史匯入、統計、菜單與離線 PDF 預覽，並內建經同意公開的 2026 年 9–11 月 40 天、520 筆資料。

## 從網頁版搬入現有資料

1. 在原本有正式資料的網頁版，按頁尾「匯出完整備份（含菜單）」。
2. 在桌面程式頁尾，選「匯入網頁版／完整備份」，選擇匯出的 JSON。
3. 確認資料筆數與菜單，並先建立一份新的完整備份。

CSV 只含秤重等資料，JSON 完整備份才包含班級設定、人數及菜單附件。

## 本機保存與備份

- 主資料庫：`%APPDATA%\CampusFoodWaste\campus-food-waste.sqlite`，秤重、班級、人數、備註與菜單附件都保存在這份 SQLite 資料庫。
- 每日自動備份：`%APPDATA%\CampusFoodWaste\backups\auto-YYYY-MM-DD.sqlite`，保留最近 30 份，每天一份。
- 選單「檔案 → 開啟資料資料夾」可查看固定位置。
- 「檔案 → 建立資料庫備份」可將完整 `.sqlite` 保存到其他磁碟；「還原資料庫備份」可還原，也會先保留還原前資料。
- 原本網頁版的 JSON 匯出／匯入仍然可以使用。
- 自動備份與資料庫在同一部電腦，不能防止硬碟故障，請定期另存到外接磁碟或雲端硬碟。
- 解除安裝會移除程式，保留上述資料與備份；重新安裝後可繼續使用。請不要手動刪除資料資料夾。

## 開發與驗證

使用 Node.js 24，進入 `desktop` 目錄：

```
npm ci
node node_modules/electron/install.js
npm run prepare-ui
npm test
npm run test:desktop
npm run build:win
npm run checksums
```

Windows 建置工作流程會執行資料庫測試、Electron 啟動／持久化／PDF／備份還原測試，產生安裝檔後再實際安裝、啟動安裝後版本及解除安裝，通過後才發布 Release。Linux 測試以 headless 執行，Windows 安裝驗證由 GitHub Windows runner 執行。
