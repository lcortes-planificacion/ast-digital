const {chromium}=require('/home/claude/.npm-global/lib/node_modules/playwright');
const URL='http://127.0.0.1:8765/ast-digital-32.html';
const SH='/tmp/claude-0/-home-claude/eaad93d9-02f4-58d6-8c55-d9b5752ef99b/scratchpad/shots/';
let n=0,f=0; const fallas=[];
function ok(t,v){ n++; if(v) console.log('OK   '+t); else { f++; fallas.push(t); console.log('FALLA '+t); } }
async function ctxNuevo(b,vp,estado){
  const c=await b.newContext({viewport:vp||{width:1280,height:900},storageState:estado,isMobile:!!(vp&&vp.width<500),hasTouch:!!(vp&&vp.width<500)});
  await c.route('**/wlxhephhhlhufgwfmwfm.supabase.co/**',async r=>{ const u=r.request().url().replace(/^https:\/\/wlxhephhhlhufgwfmwfm\.supabase\.co/,'http://127.0.0.1:8770');
    try{ const resp=await r.fetch({url:u}); await r.fulfill({response:resp}); }catch(e){ await r.abort(); } });
  return c;
}
async function abrir(c){ const p=await c.newPage(); p.errs=[]; p.on('pageerror',e=>p.errs.push(e.message)); p.on('dialog',d=>d.accept());
  await p.goto(URL); await p.waitForFunction(()=>typeof LISTO!=='undefined'&&LISTO,null,{timeout:15000}); await p.waitForTimeout(500); return p; }
async function dock(p,t){ await p.locator('#dock .d-b',{hasText:t}).first().click(); }
async function dlgOk(p){ await p.locator('.ovl .dlg button').last().click(); await p.waitForTimeout(300); }
async function trazo(p,sel){ await p.locator(sel||'#pad').scrollIntoViewIfNeeded(); const bx=await p.locator(sel||'#pad').boundingBox();
  await p.mouse.move(bx.x+30,bx.y+40); await p.mouse.down(); await p.mouse.move(bx.x+120,bx.y+90,{steps:6}); await p.mouse.move(bx.x+200,bx.y+50,{steps:6}); await p.mouse.up(); }
async function login(p,u,c,nueva){
  await p.evaluate(()=>{ const po=document.querySelector('#portada'); if(po){po.classList.add('off');po.style.display='none';} if(USR) cerrarSesionUsr('',true); LOGIN_DEST=null; vista='login'; render(); });
  await p.waitForTimeout(200);
  await p.fill('#l_usr',u); await p.fill('#l_cla',c); await dock(p,'Ingresar'); await p.waitForTimeout(1800);
  if(nueva && await p.locator('#k_new').count()){ await p.fill('#k_act',c); await p.fill('#k_new',nueva); await p.fill('#k_rep',nueva); await dock(p,'Guardar contraseña'); await p.waitForTimeout(1500); }
}
async function sinScroll(p){ return await p.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth+1); }
module.exports={chromium,URL,SH,ok,ctxNuevo,abrir,dock,dlgOk,trazo,login,sinScroll,res:()=>({n,f,fallas})};
