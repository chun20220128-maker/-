'use strict';
const fs=require('node:fs'),path=require('node:path');
const source=path.join(__dirname,'../../index.html');let html=fs.readFileSync(source,'utf8');
function replace(old,next){if(!html.includes(old))throw Error('找不到預期的網頁片段，停止打包：'+old.slice(0,80));html=html.replace(old,next)}
replace("const stored=localStorage.getItem('foodWasteDemoV1')","const stored=window.desktop.loadState()");
replace("localStorage.setItem('foodWasteDemoV1',JSON.stringify(state))","window.desktop.saveState(JSON.stringify(state))");
const start=html.indexOf('async function dbAction('),end=html.indexOf('\n',start);if(start<0)throw Error('缺少附件儲存介面');
html=html.slice(0,start)+`async function dbAction(mode,fn){const ops=[];let read=false;let result;fn({getAll:()=>{read=true;return{}},put:item=>{ops.push({type:'put',item});result=item.id;return{result:item.id}},delete:id=>{ops.push({type:'delete',id});return{}}});if(read){if(mode!=='readonly'||ops.length)throw Error('不支援混合讀寫');return(await window.desktop.getMenus()).map(item=>{const{payload,...meta}=item;return{...meta,blob:new Blob([payload],{type:item.kind==='pdf'?'application/pdf':item.kind==='jpg'?'image/jpeg':'application/octet-stream'})}})}if(mode!=='readwrite')throw Error('附件寫入模式不符');const converted=[];for(const op of ops){if(op.type==='put'){const{blob,...meta}=op.item;converted.push({type:'put',item:{...meta,payload:new Uint8Array(await blob.arrayBuffer())}})}else converted.push(op)}await window.desktop.applyMenus(converted);return result}`+html.slice(end);
replace('<meta charset="utf-8">',`<meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src 'self' blob: data:; script-src 'self' 'unsafe-inline' 'wasm-unsafe-eval' blob:; worker-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' blob: data:; font-src 'self' blob: data:; connect-src 'self' blob: https://raw.githubusercontent.com; object-src 'none'; base-uri 'none'; form-action 'none'">`);
replace('<title>校園廚餘管理</title>','<title>校園廚餘管理 — Windows 單機版</title>');
html=html.replace('校園廚餘管理 · 互動試用版','Windows 單機版 · 本機資料庫');
html=html.replace(/<footer>[\s\S]*?<\/footer>/,`<footer>Windows 單機版：資料與菜單儲存於本機 SQLite 資料庫，自動保留最近 30 份每日備份。<div class="row"><button onclick="window.desktop.showDataFolder()">開啟資料資料夾</button><button onclick="window.desktop.createBackup()">建立資料庫備份</button><button onclick="window.desktop.restoreBackup()">還原資料庫備份</button><button onclick="exportBackup()">匯出完整備份（含菜單）</button><label class="restore-label">匯入網頁版／完整備份 <input type="file" id="restoreBackup" accept=".json"></label></div>此單機版不會與手機網站自動同步。請定期將備份複製到其他磁碟或雲端硬碟。</footer>`);
html=html.replaceAll('瀏覽器無法保存','本機資料庫無法寫入').replaceAll('資料僅存在目前瀏覽器','資料存在本機資料庫').replaceAll('資料儲存在目前瀏覽器','資料儲存在本機資料庫').replaceAll('檔案保存在此瀏覽器','檔案保存在本機資料庫').replaceAll('此瀏覽器無法開啟附件資料庫；請使用一般模式的 Chrome／Edge，並允許本機儲存。','無法開啟本機附件資料庫，請重新啟動程式；若仍失敗，請先備份資料資料夾並查看 error.log。').replaceAll('歷年資料保留在此瀏覽器，並非雲端同步','歷年資料保留在本機資料庫，並非雲端同步');
fs.writeFileSync(path.join(__dirname,'../app/index.html'),html);
fs.copyFileSync(path.join(__dirname,'../../PDFJS-LICENSE.txt'),path.join(__dirname,'../app/PDFJS-LICENSE.txt'));
console.log('已建立桌面介面，改用本機資料庫。');
