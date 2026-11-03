!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "WinVer.nsh"
Name "校園廚餘管理"
VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=1028 "ProductName" "校園廚餘管理"
VIAddVersionKey /LANG=1028 "FileDescription" "校園廚餘管理 Windows 安裝程式"
VIAddVersionKey /LANG=1028 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1028 "LegalCopyright" "校園廚餘管理"
InstallDir "$LOCALAPPDATA\Programs\CampusFoodWaste"
InstallDirRegKey HKCU "Software\CampusFoodWaste" "InstallPath"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 64
ShowInstDetails show
ShowUninstDetails show
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE ValidateDirectory
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\校園廚餘管理.exe"
!define MUI_FINISHPAGE_RUN_TEXT "開啟校園廚餘管理"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "English"
Function .onInit
 SetShellVarContext current
 ${IfNot} ${RunningX64}
  MessageBox MB_ICONSTOP "此版本需要 Windows 10／11 64 位元系統。"
  Abort
 ${EndIf}
 ${IfNot} ${AtLeastWin10}
  MessageBox MB_ICONSTOP "此版本需要 Windows 10 或更新版本。"
  Abort
 ${EndIf}
 FindWindow $0 "Chrome_WidgetWin_1" "校園廚餘管理 — Windows 單機版"
 ${If} $0 != 0
  MessageBox MB_ICONEXCLAMATION "請先關閉校園廚餘管理，再執行安裝。"
  Abort
 ${EndIf}
 !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd
Function ValidateDirectory
 IfFileExists "$INSTDIR\campus-install.marker" valid
 ClearErrors
 FindFirst $0 $1 "$INSTDIR\*"
 IfErrors valid
 inspect_entry:
  StrCmp $1 "." next_entry
  StrCmp $1 ".." next_entry
  StrCmp $1 "" empty_directory
  FindClose $0
  MessageBox MB_ICONEXCLAMATION "請選擇空白資料夾或原本的校園廚餘管理安裝資料夾。"
  Abort
 next_entry:
  ClearErrors
  FindNext $0 $1
  IfErrors empty_directory inspect_entry
 empty_directory:
  FindClose $0
 valid:
FunctionEnd
Section "安裝校園廚餘管理"
 Call ValidateDirectory
 SetShellVarContext current
 SetOutPath "$INSTDIR"
 File /r "${APP_DIR}"
 FileOpen $0 "$INSTDIR\campus-install.marker" w
 FileWrite $0 "CampusFoodWaste 1"
 FileClose $0
 WriteUninstaller "$INSTDIR\解除安裝.exe"
 CreateDirectory "$SMPROGRAMS\校園廚餘管理"
 CreateShortcut "$DESKTOP\校園廚餘管理.lnk" "$INSTDIR\校園廚餘管理.exe"
 CreateShortcut "$SMPROGRAMS\校園廚餘管理\校園廚餘管理.lnk" "$INSTDIR\校園廚餘管理.exe"
 CreateShortcut "$SMPROGRAMS\校園廚餘管理\解除安裝.lnk" "$INSTDIR\解除安裝.exe"
 WriteRegStr HKCU "Software\CampusFoodWaste" "InstallPath" "$INSTDIR"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\CampusFoodWaste" "DisplayName" "校園廚餘管理"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\CampusFoodWaste" "DisplayVersion" "${VERSION}"
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\CampusFoodWaste" "UninstallString" '$\"$INSTDIR\解除安裝.exe$\"'
 WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\CampusFoodWaste" "DisplayIcon" "$INSTDIR\校園廚餘管理.exe"
 WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\CampusFoodWaste" "NoModify" 1
 WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\CampusFoodWaste" "NoRepair" 1
SectionEnd
Function un.onInit
 SetShellVarContext current
 IfFileExists "$INSTDIR\campus-install.marker" verified
 MessageBox MB_ICONSTOP "找不到有效的安裝標記，停止解除安裝以保護其他檔案。"
 Abort
 verified:
 FindWindow $0 "Chrome_WidgetWin_1" "校園廚餘管理 — Windows 單機版"
 ${If} $0 != 0
  MessageBox MB_ICONEXCLAMATION "請先關閉校園廚餘管理，再解除安裝。"
  Abort
 ${EndIf}
FunctionEnd
Section "Uninstall"
 SetShellVarContext current
 Delete "$DESKTOP\校園廚餘管理.lnk"
 RMDir /r "$SMPROGRAMS\校園廚餘管理"
 DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\CampusFoodWaste"
 DeleteRegKey HKCU "Software\CampusFoodWaste"
 RMDir /r "$INSTDIR"
 ; 保留 $APPDATA\CampusFoodWaste 的資料庫、菜單與備份。
SectionEnd
