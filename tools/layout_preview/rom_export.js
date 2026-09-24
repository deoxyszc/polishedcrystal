function exportRomLayout(){
 const names=CONTRACT.names,templates=CONTRACT.templates;
 try {
  validateRomItems(items);
  const result=items.map(e=>{let v={...e,binding:e.binding||names[e.name]};if(!v.binding)throw Error('缺少游戏绑定：'+e.text);delete v.rgba;if(templates[v.binding])v.template=e.template||templates[v.binding];return v});
  if(result.length!==15||new Set(result.map(e=>e.binding)).size!==15)throw Error('需要完整15个粉页绑定元素；请先导入确认方案');
  download('summary-pink-rom.json',new Blob([JSON.stringify({schema:2,page:'summary_pink',items:result,provenance:DATA.provenance},null,2)],{type:'application/json'}));
 }catch(e){$('status').textContent=e.message}
}
const romButton=document.createElement('button');romButton.textContent='导出ROM布局';romButton.onclick=exportRomLayout;$('export').after(romButton);
