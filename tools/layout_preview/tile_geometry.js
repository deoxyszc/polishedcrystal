// Screen-space coverage only. This does not infer VRAM allocation or tile IDs.
function tileCells(x,y,w,h){
 if(w<=0||h<=0)return [];
 const cells=[];
 for(let ty=Math.floor(y/8);ty<Math.ceil((y+h)/8);ty++)
  for(let tx=Math.floor(x/8);tx<Math.ceil((x+w)/8);tx++)cells.push([tx,ty]);
 return cells;
}
function pixelCoverage(e,glyphs){
 let points=[];
 if(e.type==='image'){
  const p=Uint8Array.from(atob(e.rgba),c=>c.charCodeAt(0));
  for(let y=0;y<e.h;y++)for(let x=0;x<e.w;x++)if(p[(y*e.w+x)*4+3])points.push([e.x+x,e.y+y]);
 }else{
  let pen=e.x;
  for(const char of e.text){const g=glyphs[char];if(!g){pen+=12;continue}
   for(let y=0;y<g.h;y++)for(let x=0;x<g.w;x++)if(g.pixels[y*g.w+x])points.push([pen+x,e.y+y+(g.h===12?e.cjk:e.latin)]);
   pen+=g.w;
  }
 }
 let cells=new Map(),box=null;
 for(const [x,y] of points){const tx=Math.floor(x/8),ty=Math.floor(y/8);cells.set(tx+','+ty,[tx,ty]);if(!box)box={x,y,right:x+1,bottom:y+1};else{box.x=Math.min(box.x,x);box.y=Math.min(box.y,y);box.right=Math.max(box.right,x+1);box.bottom=Math.max(box.bottom,y+1)}}
 return {cells:[...cells.values()],box:box?{x:box.x,y:box.y,w:box.right-box.x,h:box.bottom-box.y}:null};
}
function occupancy(e,glyphs){
 const visible=pixelCoverage(e,glyphs);
 const w=e.type==='image'?e.w:[...e.text].reduce((n,c)=>n+(glyphs[c]?.w||12),0);
 const h=e.type==='image'?e.h:16;
 const writeWidth=e.type==='image'?w:Math.ceil(w/8)*8;
 return {visible,cropCells:tileCells(e.x,e.y,w,h),writeCells:e.type==='image'?null:tileCells(e.x,e.y,writeWidth,16),
  resourceTiles:null,alignment:e.x%8===0&&e.y%8===0,missing:e.type==='image'?[]:[...new Set([...e.text].filter(c=>!glyphs[c]))]};
}
if(typeof module!=='undefined')module.exports={tileCells,pixelCoverage,occupancy};
