'use strict';
const {contextBridge,ipcRenderer}=require('electron');
contextBridge.exposeInMainWorld('desktop',{
 loadState:()=>{const r=ipcRenderer.sendSync('data:load');if(!r.ok)throw Error(r.error);return r.value},
 saveState:value=>{const r=ipcRenderer.sendSync('data:save',value);if(!r.ok)throw Error(r.error);return true},
 getMenus:()=>ipcRenderer.invoke('menus:get'),
 applyMenus:ops=>ipcRenderer.invoke('menus:apply',ops),
 showDataFolder:()=>ipcRenderer.invoke('app:show-data'),
 createBackup:()=>ipcRenderer.invoke('app:backup'),
 restoreBackup:()=>ipcRenderer.invoke('app:restore')
});
