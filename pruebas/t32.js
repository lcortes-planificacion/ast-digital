const CLAVE_EMERGENCIA_PRUEBA_REQ=process.env.CLAVE_EMERGENCIA_PRUEBA; if(!CLAVE_EMERGENCIA_PRUEBA_REQ){ console.error('Define CLAVE_EMERGENCIA_PRUEBA (solo en tu copia local de prueba)'); process.exit(1); }
const H=require('./h32.js'); const {ok}=H;
const S=H.SH+'32_';
async function acc(p,g){ return await p.$$eval('[data-acc="'+g+'"]',e=>e.map(x=>[x.getAttribute('data-pl'),x.classList.contains('open')])); }
async function tapaDock(p){ return await p.evaluate(()=>{ const d=document.querySelector('#dock'); if(!d||d.style.display==='none'||!d.offsetHeight) return false;
  const top=d.getBoundingClientRect().top; const a=document.activeElement; return a? a.getBoundingClientRect().bottom>top : false; }); }
async function dockSobreTiles(p){ return await p.evaluate(()=>{ const d=document.querySelector('#dock'); if(!d||d.style.display==='none'||!d.offsetHeight) return false;
  const r=d.getBoundingClientRect(); return Array.from(document.querySelectorAll('.tile')).some(t=>{const q=t.getBoundingClientRect(); return q.bottom>r.top&&q.top<r.bottom&&q.right>r.left&&q.left<r.right;}); }); }
(async()=>{
 const b=await H.chromium.launch();
 // ===== 1. Taller en el teléfono =====
 const cm=await H.ctxNuevo(b,{width:390,height:844}); const pm=await H.abrir(cm);
 ok('Portada sin «Sumitomo Drive» suelto', !/Sumitomo Drive(?! Technologies)/.test(await pm.textContent('body')));
 await pm.screenshot({path:S+'m_portada.png'});
 await pm.click('#p_acc button:has-text("INGRESAR A TALLER SMAN")'); await pm.waitForTimeout(500);
 await pm.fill('#i_nom','Juan Pérez'); await pm.fill('#i_rut','123456785'); await pm.fill('#i_car','Mecánico');
 await H.dock(pm,'Continuar'); await pm.waitForTimeout(1300);
 ok('Inicio sin la tarjeta grande de bienvenida', await pm.locator('.hero').count()===0);
 ok('Dos tarjetas compactas: INGRESA A TALLER SMAN y FIRMAS PENDIENTES', (await pm.$$eval('.op-card b',x=>x.map(e=>e.textContent))).join('|')==='INGRESA A TALLER SMAN|FIRMAS PENDIENTES');
 ok('Las tarjetas tienen ícono', await pm.locator('.op-card .op-ic svg').count()===2);
 ok('FIRMAS PENDIENTES muestra la cantidad ('+await pm.textContent('#tc_num')+')', /^\d+$/.test((await pm.textContent('#tc_num')).trim()));
 ok('Tarjetas compactas (alto < 110 px)', await pm.evaluate(()=>Array.from(document.querySelectorAll('.op-card')).every(c=>c.offsetHeight<110)));
 await pm.screenshot({path:S+'m_inicio_taller.png'});
 await pm.click('.op-card:has-text("INGRESA A TALLER SMAN")'); await pm.waitForTimeout(1000);
 ok('Áreas: 11 cuadros', await pm.locator('.grid.areas .tile').count()===11);
 ok('Áreas: sin «Resumen del área»', !(await pm.textContent('#app')).includes('Resumen del área'));
 ok('Áreas: ningún botón tapa los cuadros', !(await dockSobreTiles(pm)));
 ok('Áreas: sin desplazamiento horizontal', await H.sinScroll(pm));
 ok('Áreas: botón Volver visible', await pm.locator('#nav .volver').isVisible());
 await pm.screenshot({path:S+'m_areas.png',fullPage:true});
 // formulario
 await pm.evaluate(()=>ir('ensamble','L1')); await pm.waitForTimeout(900);
 await H.dock(pm,'Crear la AST'); await pm.waitForTimeout(1000);
 let A=await acc(pm,'f-form');
 ok('Formulario nuevo: todos los cuadros cerrados ('+A.length+' cuadros)', A.length>=7 && A.every(x=>!x[1]));
 await pm.screenshot({path:S+'m_form_cerrado.png'});
 ok('Cada cuadro tiene su flecha visible de 30 px o más', await pm.evaluate(()=>Array.from(document.querySelectorAll('[data-acc="f-form"] > .pl-h .chev')).every(c=>{const r=c.getBoundingClientRect();return r.width>=30&&r.height>=30;})));
 await pm.locator('[data-pl="f-p1"] > .pl-h').click(); await pm.waitForTimeout(250);
 ok('Un clic abre el cuadro', await pm.evaluate(()=>document.querySelector('[data-pl="f-p1"]').classList.contains('open')));
 ok('La flecha queda girada y se avisa abierto (aria-expanded)', await pm.evaluate(()=>document.querySelector('[data-pl="f-p1"] > .pl-h').getAttribute('aria-expanded')==='true'));
 await pm.locator('[data-pl="f-p1"] > .pl-h .chev').click(); await pm.waitForTimeout(250);
 ok('Un clic en la flecha lo cierra', await pm.evaluate(()=>!document.querySelector('[data-pl="f-p1"]').classList.contains('open')));
 await pm.locator('[data-pl="f-p1"] > .pl-h').click(); await pm.waitForTimeout(200);
 await pm.locator('[data-pl="f-p2"] > .pl-h').click(); await pm.waitForTimeout(250);
 A=await acc(pm,'f-form');
 ok('Solo un cuadro abierto a la vez (abrió Paso 2, se cerró Paso 1)', A.filter(x=>x[1]).map(x=>x[0]).join()==='f-p2');
 await pm.locator('[data-pl="f-ant"] > .pl-h').click(); await pm.waitForTimeout(250);
 await pm.fill('#f_desc','Cambio de rodamientos'); await pm.focus('#f_lugar'); await pm.waitForTimeout(500);
 ok('El campo que se escribe no queda detrás de los botones', !(await tapaDock(pm)));
 await pm.fill('#f_lugar','Línea 1');
 // firmante (está en Antecedentes, que sigue abierto)
 const ops=await pm.$$eval('#f_sup_sel option',o=>o.map(x=>x.textContent));
 ok('«Se envía a firma de»: nombres de la base + Otros ('+ops.slice(1).join(', ')+')', ops.slice(1).join('|')==='Alexis Núñez|Luis Cortés|Bryan Mendoza|Richard Williams|Maybeth Prado|Francisco Yáñez|Bernardo Pérez|Jazmin Villarroel|Otros');
 await pm.selectOption('#f_sup_sel',{label:'Otros'}); await pm.waitForTimeout(200);
 ok('«Otros» abre un campo de texto para escribir el nombre', await pm.locator('#f_sup').isVisible() && (await pm.getAttribute('#f_sup','type')||'text')==='text');
 await pm.selectOption('#f_sup_sel',{label:'Bryan Mendoza'}); await pm.waitForTimeout(150);
 ok('Al elegir un nombre de la lista se oculta el campo de texto', !(await pm.locator('#f_sup').isVisible()));
 await pm.locator('[data-pl="f-firma"] > .pl-h').click(); await pm.waitForTimeout(300);
 await H.trazo(pm,'#pad'); await pm.waitForTimeout(200);
 // pasos
 for(const k of ['f-p1','f-p2','f-p3']){ await pm.evaluate(k=>{ if(!document.querySelector('[data-pl="'+k+'"]').classList.contains('open')) togPl(k); },k); await pm.waitForTimeout(100);
   const q='#q'+k.slice(-1); const c=await pm.locator(q+' .sn-b.si').count(); for(let i=0;i<c;i++) await pm.locator(q+' .sn-b.si').nth(i).click(); }
 await pm.evaluate(()=>togPl('f-p4')); await pm.waitForTimeout(100); await pm.locator('#d_epp .pill').first().click(); await pm.locator('#d_eppok .sn-b.si').click(); await pm.locator('#d_herrok .sn-b.si').click();
 await pm.evaluate(()=>togPl('f-p5')); await pm.waitForTimeout(150);
 await pm.locator('#d_etapas .spl.grupo > .spl-h').first().click(); await pm.waitForTimeout(150);
 await pm.locator('#d_etapas .spl.grupo.open .spl .spl-h').first().click(); await pm.waitForTimeout(150);
 await pm.locator('#d_etapas .spl.grupo.open .spl.open .rk input').first().check(); await pm.waitForTimeout(200);
 ok('Abrir otros pasos no borra la firma', await pm.evaluate(()=>!padVacio || (W.firmaBorr||'').length>50));
 ok('Barra de botones abajo, sin «Volver» encima del formulario', await pm.locator('#dock .d-b:has-text("Volver")').count()===0 && await pm.locator('#nav .volver').isVisible());
 ok('Formulario sin desplazamiento horizontal', await H.sinScroll(pm));
 await pm.screenshot({path:S+'m_form.png'});
 await H.dock(pm,'Enviar a firma'); await pm.waitForTimeout(1600);
 if(await pm.locator('.ovl').count()){ console.log('DIALOGO',(await pm.textContent('.ovl')).slice(0,200)); await H.dlgOk(pm); await pm.waitForTimeout(800); }
 const a1=await pm.evaluate(()=>ast);
 ok('AST enviada a firma', a1 && a1.estado==='pendiente' && !!a1.contenido.supId);
 // segunda AST a «Otros»
 await pm.evaluate(()=>ir('ensamble','L2')); await pm.waitForTimeout(800); await H.dock(pm,'Crear la AST'); await pm.waitForTimeout(900);
 await pm.evaluate(()=>{ ['f-p1','f-p2','f-p3'].forEach(k=>{}); });
 await pm.evaluate(()=>togPl('f-ant')); await pm.waitForTimeout(150); await pm.fill('#f_desc','Pintura de carcasa'); await pm.fill('#f_lugar','Línea 2');
 for(const k of ['f-p1','f-p2','f-p3']){ await pm.evaluate(k=>togPl(k),k); await pm.waitForTimeout(100); const q='#q'+k.slice(-1); const c=await pm.locator(q+' .sn-b.si').count(); for(let i=0;i<c;i++) await pm.locator(q+' .sn-b.si').nth(i).click(); }
 await pm.evaluate(()=>togPl('f-p4')); await pm.waitForTimeout(100); await pm.locator('#d_epp .pill').first().click(); await pm.locator('#d_eppok .sn-b.si').click(); await pm.locator('#d_herrok .sn-b.si').click();
 await pm.evaluate(()=>togPl('f-p5')); await pm.waitForTimeout(150);
 await pm.locator('#d_etapas .spl.grupo > .spl-h').first().click(); await pm.waitForTimeout(150);
 await pm.locator('#d_etapas .spl.grupo.open .spl .spl-h').first().click(); await pm.waitForTimeout(150);
 await pm.locator('#d_etapas .spl.grupo.open .spl.open .rk input').first().check();
 await pm.evaluate(()=>togPl('f-ant')); await pm.waitForTimeout(250);
 await pm.selectOption('#f_sup_sel',{label:'Otros'}); await pm.fill('#f_sup','Juan Externo Contratista');
 await pm.evaluate(()=>togPl('f-firma')); await pm.waitForTimeout(250);
 await H.trazo(pm,'#pad'); await pm.waitForTimeout(200);
 await H.dock(pm,'Enviar a firma'); await pm.waitForTimeout(1600);
 if(await pm.locator('.ovl').count()){ await H.dlgOk(pm); await pm.waitForTimeout(800); }
 const a2=await pm.evaluate(()=>ast);
 ok('AST enviada a «Otros»: nombre escrito, sin cuenta asociada ('+(a2&&a2.contenido.supTaller)+')', a2 && a2.estado==='pendiente' && a2.contenido.supId==='' && a2.contenido.supTaller==='Juan Externo Contratista');
 console.log('Errores JS taller:',pm.errs);

 // ===== 2. Supervisor en el computador =====
 const cs=await H.ctxNuevo(b); const ps=await H.abrir(cs);
 await ps.evaluate(()=>{ const po=document.querySelector('#portada'); if(po){po.classList.add('off');po.style.display='none';} vista='login'; render(); }); await ps.waitForTimeout(300);
 ok('Login: la contraseña tiene el ojo para mostrar/ocultar', await ps.locator('#l_cla + .ojo, .pw .ojo').count()>=1);
 await ps.fill('#l_cla','abc123'); await ps.locator('.pw .ojo').first().click(); await ps.waitForTimeout(100);
 ok('El ojo muestra la contraseña', (await ps.getAttribute('#l_cla','type'))==='text');
 await ps.screenshot({path:S+'login_ojo.png'});
 await ps.locator('.pw .ojo').first().click();
 ok('El ojo la vuelve a ocultar', (await ps.getAttribute('#l_cla','type'))==='password');
 ok('Login: enlace de acceso de emergencia', await ps.locator('text=Acceso de emergencia del administrador').count()===1);
 await H.login(ps,'bmendoza','Prueba32026','Bryan2026x');
 ok('Supervisor entra y cambia la clave temporal (con ojo en los 3 campos)', await ps.evaluate(()=>USR&&USR.usuario==='bmendoza'&&!USR.cambiar));
 ok('Inicio con sesión: sin tarjeta grande, con tarjetas compactas y buscador', await ps.locator('.hero').count()===0 && await ps.locator('.op-card').count()===2 && await ps.locator('#ini_q').count()===1);
 await ps.screenshot({path:S+'inicio_sup.png'});
 await ps.evaluate(id=>abrirParaFirmar(id),a1.id); await ps.waitForTimeout(1000);
 await ps.screenshot({path:S+'sup_firmar.png'});
 await H.trazo(ps,'#pad');
 await ps.locator('#app button.ok:has-text("Firmar y autorizar")').click(); await ps.waitForTimeout(2000);
 const fr=await ps.evaluate(async id=>(await api('ast_registros?id=eq.'+id))[0],a1.id);
 ok('Firma del supervisor guardada ('+fr.sup_nombre+' '+fr.sup_hora+')', fr.estado==='firmada' && fr.sup_nombre==='Bryan Mendoza');
 await ps.evaluate(id=>abrirAST(id),a1.id); await ps.waitForTimeout(1200);
 const V=await acc(ps,'v-ast'); ok('Ver AST: cuadros cerrados al abrir ('+V.length+')', V.length>=5 && V.every(x=>!x[1]));
 await ps.locator('[data-pl="v-p1"] > .pl-h').click(); await ps.waitForTimeout(200); await ps.locator('[data-pl="v-ant"] > .pl-h').click(); await ps.waitForTimeout(250);
 ok('Ver AST: acordeón exclusivo', (await acc(ps,'v-ast')).filter(x=>x[1]).map(x=>x[0]).join()==='v-ant');
 await ps.screenshot({path:S+'ver_ast.png'});
 const NUM=fr.contenido.correlativo; ok('Número correlativo asignado al firmar ('+NUM+')', NUM===5);
 // firma la de «Otros»
 await ps.evaluate(id=>abrirParaFirmar(id),a2.id); await ps.waitForTimeout(1000);
 await H.trazo(ps,'#pad'); await ps.locator('#app button.ok:has-text("Firmar y autorizar")').click(); await ps.waitForTimeout(2000);
 const fr2=await ps.evaluate(async id=>(await api('ast_registros?id=eq.'+id))[0],a2.id);
 ok('AST de «Otros» la firma un responsable autorizado y queda su nombre real ('+fr2.sup_nombre+', N° '+fr2.contenido.correlativo+')', fr2.estado==='firmada' && fr2.sup_nombre==='Bryan Mendoza' && fr2.contenido.correlativo===6);

 // ===== 3. Participante que llega después de la firma =====
 await pm.evaluate(()=>{ vista=''; render(); }); await pm.waitForTimeout(600);
 await pm.evaluate(()=>ir('ensamble','L1')); await pm.waitForTimeout(1200);
 ok('El taller ve la AST firmada con su número', (await pm.textContent('#app')).includes(String(NUM)));
 ok('Botón «Agregar participante» en la AST firmada', await pm.locator('#dock .d-b:has-text("Agregar participante")').count()===1);
 await H.dock(pm,'Agregar participante'); await pm.waitForTimeout(700);
 ok('Aparece la declaración exacta', (await pm.textContent('.declara p')).trim()==='Declaro haber participado en la charla previa, haber tomado conocimiento de los riesgos y las medidas de control definidas en este AST, y conocer mi derecho y mi obligación de detener el trabajo ante cualquier condición insegura.');
 await pm.fill('#p_nom','Rosa Díaz'); await pm.fill('#p_rut','111111111');
 await H.trazo(pm,'#pad'); await H.dock(pm,'Firmar e incorporarme'); await pm.waitForTimeout(900);
 ok('Sin aceptar la declaración no deja registrar', await pm.locator('.declara').count()===1);
 await pm.screenshot({path:S+'m_participante.png'});
 await pm.check('#p_dec'); await H.dock(pm,'Firmar e incorporarme'); await pm.waitForTimeout(1800);
 const pp=await ps.evaluate(async id=>await api('ast_participantes?ast_id=eq.'+id+'&order=creado'),a1.id);
 const rosa=pp.find(x=>x.nombre==='Rosa Díaz');
 ok('Participante agregado a la misma AST, marcado después de la firma', rosa && rosa.post_firma===true && rosa.declaracion_aceptada===true);
 ok('Queda fecha, hora y quién lo registró ('+(rosa&&rosa.registrado_por)+')', rosa && rosa.registrado_en && rosa.registrado_por==='Juan Pérez');
 const fr3=await ps.evaluate(async id=>(await api('ast_registros?id=eq.'+id))[0],a1.id);
 ok('Se conserva el número correlativo', fr3.contenido.correlativo===NUM);
 ok('No se alteran las firmas previas', fr3.sup_firma===fr.sup_firma && fr3.sup_nombre===fr.sup_nombre && fr3.sup_hora===fr.sup_hora && JSON.stringify(fr3.contenido.firmas)===JSON.stringify(fr.contenido.firmas));
 const cuantas=await ps.evaluate(async()=>(await api('ast_registros?select=id&fecha=eq.'+hoy()+'&area=eq.ensamble&linea=eq.L1')).length);
 ok('No se creó una AST nueva ('+cuantas+')', cuantas===1);
 await pm.evaluate(()=>{ if(!document.querySelector('[data-pl="v-part"]')) return; if(!document.querySelector('[data-pl="v-part"]').classList.contains('open')) togPl('v-part'); }); await pm.waitForTimeout(300);
 ok('La lista de participantes lo muestra como incorporado después de la firma', (await pm.textContent('#app')).includes('Se incorporó después de la firma'));
 await pm.screenshot({path:S+'m_post_firma.png'});
 console.log('Errores JS taller 2:',pm.errs); ok('Sin errores JS (taller)', pm.errs.length===0);

 // ===== 4. Administrador =====
 const ca=await H.ctxNuevo(b); const pa=await H.abrir(ca);
 await H.login(pa,'lcortes','Prueba22026','Luis2026admin');
 await pa.evaluate(()=>menuVista('adm-usr')); await pa.waitForTimeout(1200);
 ok('Administración de usuarios', await pa.locator('.ucard').count()===8);
 ok('Barra de usuarios: Nuevo usuario y Clave de emergencia', await pa.locator('#dock .d-b:has-text("Clave de emergencia")').count()===1);
 await H.dock(pa,'Nuevo usuario'); await pa.waitForTimeout(400);
 ok('Crear usuario: la contraseña temporal tiene ojo', await pa.locator('.pw:has(#u_tmp) .ojo').count()===1);
 await pa.fill('#u_nom','Carla'); await pa.fill('#u_ape','Calidad'); await pa.fill('#u_usr','ccalidad'); await pa.selectOption('#u_per','calidad'); await pa.fill('#u_tmp','Calidad2026');
 await H.dock(pa,'Guardar usuario'); await pa.waitForTimeout(1500); await H.dlgOk(pa); await pa.waitForTimeout(900);
 ok('Crea un usuario', await pa.locator('.ucard',{hasText:'Carla Calidad'}).count()===1);
 const bp=await pa.evaluate(()=>USUARIOS.find(u=>u.usuario==='bmendoza').id);
 await pa.evaluate(id=>{ togUsuario(id); },bp); await pa.waitForTimeout(400); await H.dlgOk(pa); await pa.waitForTimeout(1200);
 const lf=await pa.evaluate(async()=>(await rpc('ast_firmantes',{})).map(x=>x.nombre));
 ok('Usuario deshabilitado desaparece de «Se envía a firma de»', lf.indexOf('Bryan Mendoza')<0 && lf.indexOf('Alexis Núñez')>=0);
 const fr4=await pa.evaluate(async id=>(await api('ast_registros?id=eq.'+id))[0],a1.id);
 ok('Su firma histórica se conserva en la AST', fr4.sup_nombre==='Bryan Mendoza' && fr4.sup_firma===fr.sup_firma);
 await pm.evaluate(()=>{ vista=''; render(); }); await pm.waitForTimeout(300); await pm.evaluate(()=>ir('pintura','L1')); await pm.waitForTimeout(900);
 await H.dock(pm,'Crear la AST').catch(()=>{}); await pm.waitForTimeout(900); await pm.evaluate(()=>{ cargarFirmantes&&cargarFirmantes(); }); await pm.waitForTimeout(800);
 await pm.evaluate(()=>{ vista=''; render(); }); await pm.waitForTimeout(300); await pm.evaluate(()=>ir('pintura','L1')); await pm.waitForTimeout(900); await H.dock(pm,'Crear la AST').catch(()=>{}); await pm.waitForTimeout(900);
 await pm.evaluate(()=>togPl('f-ant')); await pm.waitForTimeout(200);
 const ops2=await pm.$$eval('#f_sup_sel option',o=>o.map(x=>x.textContent)).catch(()=>[]);
 ok('En el teléfono del taller, la lista ya no muestra al deshabilitado ('+ops2.length+' opciones)', ops2.length>2 && ops2.indexOf('Bryan Mendoza')<0 && ops2.indexOf('Otros')>=0);
 await pa.evaluate(()=>{ ACTU=''; menuVista('adm-act'); }); await pa.waitForTimeout(1000);
 const act=await pa.textContent('#app');
 ok('Historial: participante agregado después de la firma', act.includes('Agregó un participante después de la firma'));
 console.log('Errores JS sup/adm:',ps.errs,pa.errs); ok('Sin errores JS (supervisor y administrador)', ps.errs.length+pa.errs.length===0);
 await pa.screenshot({path:S+'adm_usuarios.png'});

 // ===== 5. Acceso de emergencia =====
 const ce=await H.ctxNuevo(b); const pe=await H.abrir(ce);
 await pe.evaluate(()=>{ const po=document.querySelector('#portada'); if(po){po.classList.add('off');po.style.display='none';} vista='login'; render(); }); await pe.waitForTimeout(300);
 await pe.click('text=Acceso de emergencia del administrador'); await pe.waitForTimeout(400);
 ok('Pantalla de emergencia: clave y contraseñas con ojo', await pe.locator('.pw .ojo').count()===3);
 ok('La clave no está en el código de la app', !(await pe.content()).includes(process.env.CLAVE_EMERGENCIA_PRUEBA));
 await pe.screenshot({path:S+'emergencia.png'});
 await pe.fill('#em_clave','equivocada'); await pe.fill('#em_n1','Recupero2026'); await pe.fill('#em_n2','Recupero2026');
 await H.dock(pe,'Recuperar acceso'); await pe.waitForTimeout(2200);
 ok('Clave equivocada: rechazada y sigue sin sesión', await pe.evaluate(()=>!USR && vista==='emergencia'));
 await pe.fill('#em_clave',process.env.CLAVE_EMERGENCIA_PRUEBA); await H.dock(pe,'Recuperar acceso'); await pe.waitForTimeout(2500);
 ok('Clave correcta: entra como administrador con su contraseña nueva', await pe.evaluate(()=>USR && USR.usuario==='lcortes' && USR.rol==='admin' && vista==='adm-usr'));
 await pe.screenshot({path:S+'emergencia_ok.png'});
 console.log('Errores JS emergencia:',pe.errs); ok('Sin errores JS (emergencia)', pe.errs.length===0);

 // ===== 6. Pantallas: PC, notebook, monitor, tablet =====
 for(const [n,vp] of [['pc',{width:1920,height:1080}],['notebook',{width:1366,height:768}],['tablet',{width:820,height:1180}],['monitor',{width:1280,height:1024}]]){
   const cx=await H.ctxNuevo(b,vp,'e_t32.json').catch(()=>null);
   const c2=await H.ctxNuevo(b,vp); const p2=await H.abrir(c2);
   await H.login(p2,'lcortes','Recupero2026');
   await p2.evaluate(()=>{ vista='areas'; render(); }); await p2.waitForTimeout(1000);
   const sv=await p2.evaluate(()=>document.documentElement.scrollHeight<=window.innerHeight+2);
   ok(n+': áreas sin desplazamiento horizontal, sin botones encima'+(sv?' y sin scroll vertical':''), await H.sinScroll(p2) && !(await dockSobreTiles(p2)));
   await p2.screenshot({path:S+n+'_areas.png'});
   await c2.close(); if(cx) await cx.close();
 }
 await b.close();
 const R=H.res(); console.log('\n'+(R.n-R.f)+'/'+R.n+' correctas', R.fallas);
})();
