// Contract is exported by the Python compiler, not separately maintained here.
const CONTRACT=DATA.constraints;
function validateRomItems(values){
 const seen=new Set();
 for(const e of values){
  const role=e.binding||CONTRACT.names[e.name];
  if(!CONTRACT.roles.includes(role)||seen.has(role))throw Error('未知或重复绑定：'+role);seen.add(role);
  if(!Number.isInteger(e.x)||!Number.isInteger(e.y)||e.x<0||e.y<0||e.x>=160||e.y>=144)throw Error('坐标越界：'+role);
  const fixed=CONTRACT.fixed[role];
  if(fixed&&(e.x!==fixed[0]||e.y!==fixed[1]))throw Error('固定元素不能移动：'+role);
  if(!fixed){const origin=role==='ball'?CONTRACT.ball_origin:[0,0];if((e.x-origin[0])%8||(e.y-origin[1])%8)throw Error('仅支持8px移动：'+role)}
  const offsets=CONTRACT.offsets[role];if(offsets&&(e.cjk!==offsets[0]||e.latin!==offsets[1]))throw Error('字形偏移不受支持：'+role);
  if(e.template&&CONTRACT.templates[role]!==e.template)throw Error('动态模板不能更改：'+role);
 }
 if(seen.size!==CONTRACT.roles.length)throw Error('缺少绑定元素');
}
function moveBound(e,x,y){
 const role=e.binding||CONTRACT.names[e.name],fixed=CONTRACT.fixed[role];
 if(fixed){$('status').textContent='该元素由页面适配器固定，需先扩展实现才能移动。';return}
 const o=role==='ball'?CONTRACT.ball_origin:[0,0];
 e.x=Math.max(o[0]%8,Math.min(152+o[0]%8,Math.round((x-o[0])/8)*8+o[0]));
 e.y=Math.max(o[1]%8,Math.min(136+o[1]%8,Math.round((y-o[1])/8)*8+o[1]));
}
