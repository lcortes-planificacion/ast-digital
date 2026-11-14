const H=require('./h33.js'); const {ok}=H;
const S=H.SH+'33_';
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
 ok('Inicio con sesión: tarjetas compactas y resumen de hoy, sin la lista larga', await ps.locator('.hero').count()===0 && await ps.locator('.op-card').count()===2 && await ps.locator('.hoy-k').count()===4 && await ps.locator('#ini_lista').count()===0);
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
 await pm.check('#p_dec'); await pm.selectOption('#p_mot',{label:'Llegó después de la charla'}); await H.dock(pm,'Firmar e incorporarme'); await pm.waitForTimeout(1800);
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

 // ===== 7. Conexión con la nube =====
 const {execSync}=require('child_process');
 const sql=q=>execSync("python3 -c \"import psycopg,os;c=psycopg.connect('host=127.0.0.1 port=54322 user=postgres dbname=postgres',autocommit=True);r=c.execute(os.environ['Q']);print(r.fetchall() if r.description else '')\"",{env:Object.assign({},process.env,{Q:q})}).toString().trim();
 const cc=await H.ctxNuevo(b,{width:1366,height:768}); const pc=await H.abrir(cc);
 await H.login(pc,'lcortes','Recupero2026');
 const pedidos=[]; pc.on('request',r=>{ const u=decodeURIComponent(r.url()); if(r.method()==='GET' && /\/rest\/v1\/ast_(registros|participantes)\?/.test(u)) pedidos.push(u); });
 let sinError=true;
 for(const v of ['stats','historico','revision','personal','ran','registradas']){
   await pc.evaluate(v=>{ DSH_CACHE.key=''; menuVista(v); },v); await pc.waitForTimeout(1600);
   const err=await pc.locator('#app .msg.e').filter({hasText:/No se pud|Sin conexión/}).count(); if(err){ sinError=false; console.log('  error en',v); }
 }
 ok('Dashboard, Archivo histórico, AST registradas, RAN TALLER, Revisión y Personal cargan sin error', sinError);
 const pesadas=pedidos.filter(u=>/ast_registros\?/.test(u) && !/select=/.test(u) && !/id=eq\./.test(u));
 ok('Ninguna lista baja las AST completas con las imágenes de firma ('+pedidos.length+' consultas revisadas)', pesadas.length===0);
 ok('Tampoco baja las firmas de los participantes en las listas', pedidos.filter(u=>/ast_participantes\?/.test(u) && /ast_id=in\./.test(u) && !/select=/.test(u)).length===0);
 ok('Indicador de estado: «Conectado»', (await pc.textContent('#nubeChip')).includes('Conectado'));
 // nube lenta: 9 segundos por consulta (antes se cortaba a los 7)
 const lento=async r=>{ await new Promise(z=>setTimeout(z,9000)); await r.fallback(); };
 await pc.route('**/rest/v1/ast_registros?*',lento);
 await pc.evaluate(()=>{ DSH_CACHE.key=''; menuVista('stats'); }); await pc.waitForTimeout(2500);
 ok('Mientras espera, el indicador dice «Sincronizando»', (await pc.textContent('#nubeChip')).includes('Sincronizando'));
 await pc.waitForTimeout(10000);
 ok('Con la nube lenta (9 s por consulta) el dashboard igual carga', await pc.locator('.kpi1').count()>3 && await pc.locator('#app .msg.e').filter({hasText:'No se pudieron'}).count()===0);
 await pc.unroute('**/rest/v1/ast_registros?*',lento);
 // sin conexión
 const corte=r=>r.abort('internetdisconnected');
 await pc.route('**/wlxhephhhlhufgwfmwfm.supabase.co/**',corte);
 await pc.evaluate(()=>menuVista('registradas')); await pc.waitForTimeout(2500);
 ok('Sin conexión: «AST registradas» se ve con los datos guardados en el equipo', await pc.locator('#aviso_cache').count()===1 && await pc.locator('#ini_lista > *').count()>0);
 ok('El aviso dice cuándo se guardaron los datos', /Guardados el \d\d-\d\d-\d{4}/.test(await pc.textContent('#aviso_cache')));
 ok('Indicador «Error de conexión»', (await pc.textContent('#nubeChip')).includes('Error de conexión'));
 ok('Aviso claro con Reintentar y Detalle', await pc.locator('#alerta').isVisible() && (await pc.textContent('#alerta')).includes('Reintentar') && (await pc.textContent('#alerta')).includes('No se pudo llegar a Supabase'));
 ok('El aviso no tapa la barra de botones', await pc.evaluate(()=>{ const a=document.querySelector('#alerta').getBoundingClientRect(), d=document.querySelector('#dock');
   if(!d||!d.offsetHeight) return true; const r=d.getBoundingClientRect(); return a.bottom<=r.top+1; }));
 await pc.screenshot({path:S+'sin_conexion.png'});
 await pc.evaluate(()=>{ DSH_CACHE.key=''; menuVista('stats'); }); await pc.waitForTimeout(2500);
 ok('El dashboard también se ve sin conexión, con los datos guardados', await pc.locator('.kpi1').count()>3 && await pc.locator('#aviso_cache').count()===1);
 await pc.evaluate(()=>menuVista('historico')); await pc.waitForTimeout(2000);
 ok('El archivo histórico también', await pc.locator('#app .msg.e').filter({hasText:'No se pudo'}).count()===0 && await pc.locator('#aviso_cache').count()===1);
 await pc.locator('#nubeChip').click(); await pc.waitForTimeout(300);
 const det=await pc.textContent('.ovl .dlg'); ok('El detalle explica el problema y muestra las últimas consultas', det.includes('Problema:') && det.includes('Últimas consultas'));
 await pc.locator('.ovl .dlg button.sec').click(); await pc.waitForTimeout(200);
 await pc.unroute('**/wlxhephhhlhufgwfmwfm.supabase.co/**',corte);
 await pc.locator('#alerta button',{hasText:'Reintentar'}).click(); await pc.waitForTimeout(2500);
 ok('Al volver la red, «Reintentar» reconecta: indicador «Conectado» y sin aviso', (await pc.textContent('#nubeChip')).includes('Conectado') && !(await pc.locator('#alerta').isVisible()) && await pc.locator('#aviso_cache').count()===0);
 await pc.route('**/wlxhephhhlhufgwfmwfm.supabase.co/**',corte);
 await pc.evaluate(()=>menuVista('registradas')); await pc.waitForTimeout(2000);
 await pc.unroute('**/wlxhephhhlhufgwfmwfm.supabase.co/**',corte);
 await pc.waitForTimeout(17000);
 ok('También se reconecta sola (prueba cada 15 segundos)', (await pc.textContent('#nubeChip')).includes('Conectado'));

 // ===== 8. Menú lateral =====
 await pc.evaluate(()=>menuVista('')); await pc.waitForTimeout(800);
 await pc.evaluate(()=>abrirMenu(true)); await pc.waitForTimeout(300);
 let items=await pc.$$eval('#lateral .lat-b',x=>x.map(e=>e.textContent.replace(/\d+$/,'').trim()));
 ok('Menú en orden de uso: '+items.join(' · '), items.slice(0,9).join('|')==='Inicio|Nueva AST|Firmas pendientes|AST registradas|Archivo histórico|RAN TALLER|Dashboard|Revisión de AST|Personal registrado');
 const latTxt=await pc.textContent('#lateral');
 ok('Sin «AST guardadas» (repetía «AST registradas») ni «Acciones de esta pantalla» (repetía la barra de botones)', !latTxt.includes('AST guardadas') && !latTxt.includes('Acciones de esta pantalla'));
 ok('Administración plegada: no muestra sus opciones hasta tocarla', !latTxt.includes('Papelera de AST'));
 await pc.screenshot({path:S+'menu.png'});
 await pc.locator('#lateral .lat-tog').click(); await pc.waitForTimeout(250);
 items=await pc.$$eval('#lateral .lat-b',x=>x.map(e=>e.textContent.replace(/\d+$/,'').trim()));
 ok('Al tocarla aparecen Usuarios y accesos, Papelera y Configuración', ['Usuarios y accesos','Papelera de AST','Configuración'].every(t=>items.indexOf(t)>=0));
 ok('Menú del administrador: '+items.length+' opciones en vez de 24', items.length<=14);
 await pc.locator('#lateral .lat-b',{hasText:'Configuración'}).click(); await pc.waitForTimeout(500);
 ok('Configuración reúne sus 8 pantallas en una sola', await pc.locator('.cfg-t').count()===8);
 await pc.screenshot({path:S+'configuracion.png'});
 await pc.locator('.cfg-t',{hasText:'Ajustes generales'}).click(); await pc.waitForTimeout(600);
 await pc.locator('#nav .volver').click(); await pc.waitForTimeout(500);
 ok('Desde un ajuste, «Volver» regresa a Configuración', await pc.evaluate(()=>vista==='adm-config'));
 await pc.evaluate(()=>menuVista('archivo')); await pc.waitForTimeout(800);
 ok('El acceso antiguo a «AST guardadas» abre «AST registradas»', (await pc.textContent('#titulo'))==='AST registradas');

 // ===== 9. Volver por el camino real =====
 await pc.setViewportSize({width:1366,height:520});
 await pc.evaluate(()=>menuVista('')); await pc.waitForTimeout(800);
 await pc.evaluate(()=>menuVista('registradas')); await pc.waitForTimeout(1200);
 await pc.selectOption('.sec-t select',{value:'30'}); await pc.waitForTimeout(1300);
 await pc.evaluate(()=>window.scrollTo(0,260)); await pc.waitForTimeout(300);
 const y0=await pc.evaluate(()=>window.scrollY);
 const idV=await pc.evaluate(()=>{ const x=INI.data.find(z=>z.fecha!==hoy()); return x&&x.id; });
 await pc.evaluate(id=>abrirAST(id),idV); await pc.waitForTimeout(1500);
 ok('Se abre el detalle de una AST desde «AST registradas»', await pc.evaluate(()=>archivoAbierto && !!ast));
 await pc.locator('#nav .volver').click(); await pc.waitForTimeout(1800);
 ok('Volver: regresa a «AST registradas» con el filtro de 30 días y la misma posición ('+y0+' px)', await pc.evaluate(y=>vista==='registradas' && INI.dias===30 && Math.abs(window.scrollY-y)<60 && document.querySelector('.sec-t select').value==='30',y0));
 await pc.locator('#nav .volver').click(); await pc.waitForTimeout(900);
 ok('Volver otra vez: Inicio', await pc.evaluate(()=>!vista && !AREA));
 await pc.setViewportSize({width:1366,height:768});
 await pc.evaluate(()=>menuVista('areas')); await pc.waitForTimeout(900);
 await pc.evaluate(()=>ir('ensamble')); await pc.waitForTimeout(900);
 await pc.evaluate(()=>ir('ensamble','L1')); await pc.waitForTimeout(1300);
 await H.dock(pc,'Agregar participante'); await pc.waitForTimeout(600);
 const ruta=[];
 ruta.push(await pc.evaluate(()=>vista));
 for(let i=0;i<4;i++){ await pc.locator('#nav .volver').click(); await pc.waitForTimeout(1300); ruta.push(await pc.evaluate(()=>(vista||'-')+'/'+(AREA||'-')+'/'+(LIN||'-'))); }
 ok('Participantes → Detalle → Línea → Áreas → Inicio ('+ruta.join(' → ')+')', ruta.join('|')==='registro|-/ensamble/L1|-/ensamble/-|areas/-/-|-/-/-');
 await pc.evaluate(()=>menuVista('registradas')); await pc.waitForTimeout(900);
 await pc.evaluate(()=>menuVista('stats')); await pc.waitForTimeout(1200);
 await pc.goBack(); await pc.waitForTimeout(1200);
 ok('El botón «atrás» del navegador o del teléfono hace lo mismo que Volver', await pc.evaluate(()=>vista==='registradas'));
 ok('Ninguna pantalla repite «Volver» o «Inicio» en la barra de abajo', await pc.locator('#dock .d-b',{hasText:/^(Volver|Inicio)$/}).count()===0);

 // ===== 10. Papelera =====
 await pc.evaluate(()=>ir('ensamble','L2')); await pc.waitForTimeout(1300);
 ok('El administrador ve «Eliminar» en la AST', await pc.locator('#adm_ast button',{hasText:'Eliminar'}).count()===1);
 await pc.locator('#adm_ast button',{hasText:'Eliminar'}).click(); await pc.waitForTimeout(300);
 await pc.locator('.ovl .dlg button').last().click(); await pc.waitForTimeout(500);
 ok('Sin motivo no se elimina', await pc.evaluate(id=>!!ast && ast.id===id,a2.id));
 await pc.locator('#adm_ast button',{hasText:'Eliminar'}).click(); await pc.waitForTimeout(300);
 await pc.fill('#dlg_txt','Duplicada por error'); await pc.locator('.ovl .dlg button').last().click(); await pc.waitForTimeout(1500);
 await pc.evaluate(()=>{ INI.dias=1; menuVista('registradas'); }); await pc.waitForTimeout(1300);
 ok('La AST eliminada ya no aparece en «AST registradas»', await pc.evaluate(id=>!INI.data.some(x=>x.id===id),a2.id));
 await pc.evaluate(()=>menuVista('papelera')); await pc.waitForTimeout(1200);
 const papT=await pc.textContent('#app');
 ok('Queda en la papelera con su número, el motivo y quién la eliminó', papT.includes('N° 6') && papT.includes('Duplicada por error') && papT.includes('Luis Cortés'));
 await pc.screenshot({path:S+'papelera.png'});
 ok('En la base sigue todo: la AST, su firma y su número', sql("select (select count(*) from ast_registros where id='"+a2.id+"' and sup_firma is not null),(select numero from ast_correlativos where ast_id='"+a2.id+"')")==="[(1, 6)]");
 await pc.locator('.astc.pap button',{hasText:'Recuperar'}).click(); await pc.waitForTimeout(300); await H.dlgOk(pc); await pc.waitForTimeout(1300);
 await pc.evaluate(()=>{ INI.dias=1; menuVista('registradas'); }); await pc.waitForTimeout(1300);
 ok('Al recuperarla vuelve a «AST registradas» con su número', await pc.evaluate(id=>INI.data.some(x=>x.id===id && x.contenido.correlativo===6),a2.id));
 await pm.evaluate(()=>{ vista=''; ir('ensamble','L1'); }); await pm.waitForTimeout(1300);
 ok('El taller no ve la opción de eliminar', await pm.locator('#adm_ast').count()===0);

 // ===== 11. Motivo de incorporación =====
 await H.dock(pm,'Agregar participante'); await pm.waitForTimeout(600);
 await pm.fill('#p_nom','Pablo Tarde'); await pm.fill('#p_rut','222222222'); await pm.check('#p_dec'); await H.trazo(pm,'#pad');
 await H.dock(pm,'Firmar e incorporarme'); await pm.waitForTimeout(800);
 ok('Sin motivo de incorporación no deja firmar', await pm.locator('#p_mot').count()===1);
 await pm.selectOption('#p_mot',{label:'Se sumó para apoyar la tarea'});
 await H.dock(pm,'Firmar e incorporarme'); await pm.waitForTimeout(1800);
 ok('El motivo queda guardado', sql("select motivo, post_firma from ast_participantes where nombre='Pablo Tarde'")==="[('Se sumó para apoyar la tarea', True)]");
 await pm.evaluate(()=>{ if(!document.querySelector('[data-pl="v-part"]').classList.contains('open')) togPl('v-part'); }); await pm.waitForTimeout(300);
 ok('Y se ve en la lista de participantes', (await pm.textContent('#app')).includes('motivo: Se sumó para apoyar la tarea'));
 ok('Las firmas anteriores siguen iguales', sql("select sup_nombre, contenido->>'correlativo' from ast_registros where id='"+a1.id+"'")==="[('Bryan Mendoza', '5')]");

 // ===== 12. Claves temporales y perfiles =====
 await pc.evaluate(()=>menuVista('adm-usr')); await pc.waitForTimeout(1500);
 ok('Usuarios: cuántas cuentas tienen clave temporal', (await pc.textContent('#app')).includes('Con clave temporal'));
 ok('Cada cuenta con clave temporal muestra creación y vencimiento', await pc.locator('.clave-t',{hasText:/creada .* vence /}).count()>=1);
 ok('La pantalla no muestra ninguna contraseña', !(await pc.textContent('#app')).match(/Prueba\d2026|Calidad2026/));
 const cid=await pc.evaluate(()=>USUARIOS.find(u=>u.usuario==='ccalidad').id);
 await pc.evaluate(id=>{ resetClave(id); },cid); await pc.waitForTimeout(300); await H.dlgOk(pc); await pc.waitForTimeout(1200);
 const tmp=(await pc.textContent('#cu_txt')).trim();
 ok('«Generar clave temporal» la muestra una sola vez, con botón Copiar ('+tmp.length+' caracteres)', tmp.length>=8 && await pc.locator('#cu_cp').count()===1);
 await pc.screenshot({path:S+'clave_una_vez.png'});
 await pc.locator('#cu_ok').click(); await pc.waitForTimeout(1200);
 ok('Al cerrar, la clave ya no aparece en ninguna parte', !(await pc.content()).includes(tmp));
 ok('La base guardó la fecha de creación y el vencimiento (7 días)', sql("select extract(day from clave_temporal_vence-clave_temporal_en)::int from ast_perfiles where usuario='ccalidad'")==='[(7,)]');
 await pc.evaluate(()=>menuVista('adm-matriz')); await pc.waitForTimeout(1000);
 const mt=await pc.textContent('#app');
 ok('Matriz de permisos con Administrador, Supervisor, Planificador, Usuario estándar y Visitante', ['Administrador','Supervisor','Planificador','Usuario estándar (taller)','Visitante'].every(t=>mt.includes(t)));
 await pc.evaluate(()=>{ menuVista('adm-usr'); }); await pc.waitForTimeout(1000);
 await pc.evaluate(()=>editarUsuario(null)); await pc.waitForTimeout(400);
 await pc.fill('#u_nom','Pía'); await pc.fill('#u_ape','Planificación'); await pc.fill('#u_usr','pplan'); await pc.selectOption('#u_per','planificador');
 await H.dock(pc,'Guardar usuario'); await pc.waitForTimeout(1500);
 ok('Crear usuario Planificador: la clave temporal se muestra una vez', await pc.locator('.clave-una').count()===1);
 await pc.locator('#cu_ok').click(); await pc.waitForTimeout(1300);
 ok('La cuenta queda en la sección Planificador', (await pc.textContent('#app')).includes('Pía Planificación') && await pc.locator('.sec-t',{hasText:'Planificador'}).count()===1);
 sql("update ast_perfiles set clave_temporal_vence=now()-interval '1 day' where usuario='ccalidad'");
 const cv=await H.ctxNuevo(b,{width:390,height:844}); const pv=await H.abrir(cv);
 await H.login(pv,'ccalidad',tmp);
 ok('Clave temporal vencida: avisa y no deja entrar', (await pv.textContent('#titulo'))==='Clave temporal vencida' && await pv.evaluate(()=>!document.querySelector('#k_new')));
 await pv.screenshot({path:S+'m_clave_vencida.png'});
 console.log('Errores JS 3.3:',pc.errs,pv.errs); ok('Sin errores JS en las pruebas nuevas', pc.errs.length+pv.errs.length===0);
 await cv.close(); await cc.close();

 // ===== 13. Teléfono: encabezado y sin desbordes =====
 const cm2=await H.ctxNuevo(b,{width:390,height:844}); const pm2=await H.abrir(cm2);
 await H.login(pm2,'lcortes','Recupero2026');
 let okScroll=true;
 for(const v of ['','registradas','historico','stats','papelera','adm-usr','adm-config']){
   await pm2.evaluate(v=>menuVista(v),v); await pm2.waitForTimeout(1300);
   if(!(await H.sinScroll(pm2))){ okScroll=false; console.log('  scroll horizontal en',v); }
   if(v==='registradas') await pm2.screenshot({path:S+'m_registradas.png'});
 }
 ok('Teléfono: ninguna pantalla se sale de lado', okScroll);
 ok('Teléfono: el indicador de conexión cabe arriba sin tapar el título', await pm2.evaluate(()=>{ const c=document.querySelector('#nubeChip').getBoundingClientRect(), t=document.querySelector('#titulo').getBoundingClientRect(); return c.right<=window.innerWidth && (c.bottom<=t.top || c.left>=t.right); }));
 await cm2.close();
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
