# Pruebas de seguridad con solicitudes DIRECTAS a la API (como haría alguien que manipula el navegador)
import json, urllib.request, urllib.error, datetime, concurrent.futures, secrets
B='http://127.0.0.1:8770'; R=[]
def ok(t,v): R.append((t,bool(v))); print(('OK    ' if v else 'FALLA ')+t)
def req(m,path,body=None,tok=None,disp=None,prefer='return=representation'):
    h={'Content-Type':'application/json','apikey':'sb_publishable_x','Authorization':'Bearer '+(tok or 'sb_publishable_x'),'Prefer':prefer}
    if disp: h['x-ast-dispositivo']=disp
    r=urllib.request.Request(B+path,data=json.dumps(body).encode() if body is not None else None,method=m,headers=h)
    try:
        with urllib.request.urlopen(r) as x: t=x.read().decode(); return x.status,(json.loads(t) if t else None)
    except urllib.error.HTTPError as e:
        t=e.read().decode(); 
        try: return e.code,json.loads(t)
        except: return e.code,t
def login(u,c):
    s,d=req('POST','/auth/v1/token?grant_type=password',{'email':u+'@ast-sman.local','password':c}); return d.get('access_token') if s==200 else None
def rpc(f,args,tok=None,disp=None): return req('POST','/rest/v1/rpc/'+f,args,tok,disp)
hoy=datetime.date.today().isoformat(); hace30=(datetime.date.today()-datetime.timedelta(days=30)).isoformat()
D1='disp_'+secrets.token_hex(12); D2='disp_'+secrets.token_hex(12)

print('\n— Taller sin cuenta —')
s,d=req('GET','/rest/v1/ast_registros?select=id'); ok('Sin dispositivo registrado no ve ninguna AST', s==200 and d==[])
s,d=rpc('ast_registrar_dispositivo',{'p_id':D1,'p_nombre':'Juan Pérez','p_rut':'12.345.678-5','p_cargo':'Mecánico','p_agente':'prueba'})
ok('Registra su dispositivo', s==200 and d['nuevo'])
s,d=req('GET','/rest/v1/ast_registros?select=id,fecha',disp=D1); ids=[x['id'] for x in d]
ok('Ve solo las AST del día (%s)'%ids, ids==['hoy1'])
s,d=req('GET','/rest/v1/ast_registros?select=id&fecha=lt.'+hoy,disp=D1); ok('Consulta directa al historial devuelve vacío', d==[])
s,d=req('GET','/rest/v1/ast_registros?select=id&id=eq.h3',disp=D1); ok('Pedir una AST histórica por su id devuelve vacío', d==[])
s,d=req('GET','/rest/v1/ast_participantes?select=id',disp=D1); ok('Participantes: solo los de AST del día', [x['id'] for x in d]==['p2'])
s,d=req('GET','/rest/v1/ast_correlativos?select=*',disp=D1); ok('No ve los números del historial', d==[])
s,d=req('POST','/rest/v1/ast_registros',{'id':'t1','fecha':hoy,'area':'ensamble','linea':'L4','estado':'pendiente','contenido':{'descripcion':'x','supId':''}},disp=D1)
ok('Crea una AST del día', s==201)
s,d=req('POST','/rest/v1/ast_registros',{'id':'t2','fecha':hace30,'area':'ensamble','linea':'L4','estado':'borrador'},disp=D1); ok('No puede crear AST con fecha antigua', s>=400)
s,d=req('POST','/rest/v1/ast_registros',{'id':'t3','fecha':hoy,'area':'ensamble','linea':'L5','estado':'firmada','sup_firma':'x','sup_nombre':'Yo'},disp=D1); ok('No puede crear una AST ya firmada', s>=400)
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.hoy1',{'sup_firma':'data:falsa','sup_nombre':'Supervisor falso','estado':'firmada'},disp=D1); ok('No puede firmar (aunque mande la firma directo)', s>=400)
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.hoy1',{'contenido':{'descripcion':'cambiada'}},disp=D1); ok('No puede modificar una AST enviada a firma', s>=400)
s,d=req('DELETE','/rest/v1/ast_registros?id=eq.t1',disp=D1); ok('No puede eliminar AST', s>=400 or d==[])
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.h3',{'estado':'borrador'},disp=D1); ok('No puede tocar una AST histórica', s>=400 or d==[])
s,d=req('GET','/rest/v1/ast_perfiles?select=*',disp=D1); ok('No ve las cuentas de usuarios', s>=400 or d==[])
s,d=req('GET','/rest/v1/ast_accesos?select=*',disp=D1); ok('No ve la auditoría', s>=400 or d==[])
s,d=req('GET','/rest/v1/ast_firmas?select=*',disp=D1); ok('No ve las firmas registradas', s>=400 or d==[])
s,d=req('GET','/rest/v1/ast_config?select=id',disp=D1); ok('De la configuración solo ve la general', [x['id'] for x in d]==['main'])
s,d=req('PATCH','/rest/v1/ast_config?id=eq.main',{'datos':{}},disp=D1); ok('No puede cambiar la configuración', s>=400 or d==[])
s,d=rpc('ast_admin_crear_usuario',{'p_usuario':'hacker','p_nombre':'H','p_apellido':'X','p_rut':'','p_cargo':'','p_rol':'admin','p_clave':'Clave12345','p_orden':1},disp=D1)
ok('No puede crear un administrador', s>=400)
s,d=rpc('ast_crear_cuenta',{'p_usuario':'hacker','p_nombre':'H','p_apellido':'X','p_rut':'','p_cargo':'','p_rol':'admin','p_clave':'Clave12345','p_orden':1,'p_por':'x'},disp=D1)
ok('La función interna de creación no se puede llamar', s>=400)
s,d=req('POST','/rest/v1/ast_correlativos',{'ast_id':'t1','numero':999},disp=D1); ok('No puede inventar un número oficial', s>=400)
s,d=rpc('ast_firmantes',{},disp=D1); ok('Lista de firmantes: 8 nombres en orden', s==200 and [x['nombre'] for x in d][:3]==['Alexis Núñez','Luis Cortés','Bryan Mendoza'])

print('\n— Cuentas —')
adm=login('lcortes','Prueba22026'); sup=login('bmendoza','Prueba32026'); sup2=login('rwilliams','Prueba42026')
ok('Ingreso con usuario y contraseña', adm and sup and sup2)
ok('Contraseña equivocada no entra', login('bmendoza','otra')==None)
s,d=rpc('ast_mi_perfil',{'p_ingreso':True},sup,D2); ok('Perfil y permisos vienen de la base (%s)'%(d and d['rol']), d['rol']=='supervisor' and d['niveles']['usuarios']==0)
s,d=req('PATCH','/rest/v1/ast_perfiles?usuario=eq.bmendoza',{'rol':'admin'},sup,D2); ok('Un supervisor no puede cambiarse el rol', s>=400 or d==[])
s,d=rpc('ast_admin_editar_usuario',{'p_id':d and None or '00000000-0000-0000-0000-000000000000','p_nombre':'a','p_apellido':'b','p_rut':'','p_cargo':'','p_rol':'admin','p_permisos':{},'p_orden':1},sup,D2)
ok('Un supervisor no puede usar las funciones de administración', s>=400)
s,d=req('GET','/rest/v1/ast_registros?select=id',tok=sup,disp=D2); ok('Supervisor ve el historial (%d)'%len(d), len(d)>=6)
# asignar t1 a bmendoza y probar que otro no firma
bid=rpc('ast_mi_perfil',{},sup,D2)[1]['id']
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'contenido':{'descripcion':'x','supId':bid}},sup,D2)
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'sup_firma':'data:img','estado':'firmada','contenido':{'descripcion':'x','supId':bid}},sup2,D2)
ok('Otro supervisor no puede firmar una AST asignada a Bryan', s>=400)
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'estado':'borrador','contenido':{'descripcion':'x','supId':bid,'devolucion':{'detalle':'x'}}},sup2,D2)
ok('Otro supervisor no puede devolver una AST asignada a Bryan', s>=400)
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'sup_firma':'data:img','sup_nombre':'Nombre inventado','estado':'firmada','contenido':{'descripcion':'x','supId':bid,'firmas':[{'metodo':'firma registrada de la cuenta'}]}},sup,D2)
ok('Bryan firma su AST', s==200)
f=d[0]; ok('El nombre del firmante lo pone la base, no el navegador (%s)'%f['sup_nombre'], f['sup_nombre']=='Bryan Mendoza')
ok('La base asigna el número oficial (%s)'%f['contenido'].get('correlativo'), f['contenido'].get('correlativo',0)>4)
ok('Firma con fecha, hora y cuenta registradas por la base', f['contenido']['firmas'][-1]['usuario']=='bmendoza' and f['contenido']['firmas'][-1]['ts'])
num=f['contenido']['correlativo']
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'responsable':'Otro'},adm,D2); ok('Ni el administrador puede modificar una AST firmada', s>=400)
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'sup_firma':None},adm,D2); ok('Ni el administrador puede quitar una firma', s>=400)
s,d=req('DELETE','/rest/v1/ast_registros?id=eq.t1',tok=adm,disp=D2); ok('Ni el administrador puede eliminar una AST', s>=400 or d==[])
c=dict(f['contenido']); c['notas']=[{'t':'Nota 1'}]
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'contenido':c},adm,D2); ok('Se puede agregar una nota de corrección', s==200)
c['notas']=[{'t':'Nota cambiada'}]
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1',{'contenido':c},adm,D2); ok('Una nota ya escrita no se puede cambiar', s>=400)
# versión
s,d=req('POST','/rest/v1/ast_registros',{'id':'t1v2','fecha':hoy,'area':'ensamble','linea':'L4','estado':'pendiente','contenido':{'versionBase':'t1','versionDe':'t1','versionNum':2,'supId':bid}},disp=D1)
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.t1v2',{'sup_firma':'data:img','estado':'firmada','contenido':{'versionBase':'t1','versionDe':'t1','versionNum':2,'supId':bid}},sup,D2)
ok('Nueva versión firmada: mismo número, Rev.1', s==200 and d[0]['contenido']['correlativo']==num and d[0]['contenido']['rev']==1)

print('\n— Número oficial con firmas simultáneas —')
ids=['par%02d'%i for i in range(20)]
for i in ids: req('POST','/rest/v1/ast_registros',{'id':i,'fecha':hoy,'area':'ensamble','linea':'L1','estado':'pendiente','contenido':{}},disp=D1)
def firma(i): return req('PATCH','/rest/v1/ast_registros?id=eq.'+i,{'sup_firma':'data:img','estado':'firmada','contenido':{}},sup,D2)[1][0]['contenido']['correlativo']
with concurrent.futures.ThreadPoolExecutor(10) as ex: nums=list(ex.map(firma,ids))
ok('20 firmas al mismo tiempo: 20 números distintos y seguidos', len(set(nums))==20 and max(nums)-min(nums)==19)

print('\n— Desactivar cuentas y bloquear dispositivos —')
uid2=rpc('ast_mi_perfil',{},sup2,D2)[1]['id']
s,d=rpc('ast_admin_activar',{'p_id':uid2,'p_activo':False},adm,D2); ok('Administrador deshabilita a Richard', s in (200,204))
s,d=req('GET','/rest/v1/ast_registros?select=id',tok=sup2,disp=D2); ok('Con la sesión que ya tenía abierta no ve nada', s>=400 or d==[])
ok('Ya no puede iniciar sesión', login('rwilliams','Prueba42026')==None)
s,d=rpc('ast_firmantes',{},disp=D1); ok('Deja de aparecer en «Se envía a firma de»', 'Richard Williams' not in [x['nombre'] for x in d])
s,d=req('GET','/rest/v1/ast_registros?select=id&id=eq.h3',tok=adm,disp=D2); ok('Sus firmas anteriores siguen en el historial', len(d)==1 and d[0]['id']=='h3')
s,d=rpc('ast_admin_dispositivo',{'p_id':D1,'p_revocar':True},adm,D2); ok('Administrador bloquea el teléfono de Juan', s in (200,204))
s,d=req('GET','/rest/v1/ast_registros?select=id',disp=D1); ok('El teléfono bloqueado ya no ve AST', d==[])
s,d=req('POST','/rest/v1/ast_registros',{'id':'t9','fecha':hoy,'area':'ensamble','linea':'L4','estado':'borrador'},disp=D1); ok('Ni puede crear AST', s>=400)
s,d=rpc('ast_admin_activar',{'p_id':rpc('ast_mi_perfil',{},adm,D2)[1]['id'],'p_activo':False},adm,D2); ok('El administrador no se puede deshabilitar a sí mismo', s>=400)

print('\n— Perfiles nuevos —')
s,cal=rpc('ast_admin_crear_usuario',{'p_usuario':'ccalidad','p_nombre':'Carla','p_apellido':'Calidad','p_rut':'','p_cargo':'','p_rol':'calidad','p_clave':'Calidad2026','p_orden':20},adm,D2)
s2,tal=rpc('ast_admin_crear_usuario',{'p_usuario':'ttaller','p_nombre':'Tomás','p_apellido':'Taller','p_rut':'','p_cargo':'','p_rol':'taller','p_clave':'Taller2026x','p_orden':99},adm,D2)
ok('Administrador crea cuentas de Calidad y de Personal de taller', s==200 and s2==200)
tc=login('ccalidad','Calidad2026'); tt=login('ttaller','Taller2026x'); D3='disp_'+secrets.token_hex(12)
rpc('ast_registrar_dispositivo',{'p_id':D3,'p_nombre':'','p_rut':'','p_cargo':'','p_agente':'x'},tt)
s,d=req('GET','/rest/v1/ast_registros?select=id&fecha=lt.'+hoy,tok=tt,disp=D3); ok('Personal de taller con cuenta tampoco ve el historial', d==[])
c=req('GET','/rest/v1/ast_registros?select=contenido&id=eq.h3',tok=tc,disp=D2)[1][0]['contenido']; c['notas']=[{'t':'x'}]
s,d=req('PATCH','/rest/v1/ast_registros?id=eq.h3',{'contenido':c},tc,D2); ok('Calidad no puede agregar notas (solo lectura del historial)', s>=400 or d==[])
s,d=req('GET','/rest/v1/ast_accesos?select=accion&order=id.desc&limit=200',tok=adm,disp=D2); acc=[x['accion'] for x in d]
ok('La auditoría registra firmas, accesos y bloqueos', all(any(a.startswith(k) for a in acc) for k in ['Firmó y aprobó','Inició sesión','Bloqueó un dispositivo','Deshabilitó un usuario','Creó un usuario','Registró un dispositivo']))
print('\n%d/%d correctas'%(sum(1 for r in R if r[1]),len(R))); [print('  FALLA:',t) for t,v in R if not v]
