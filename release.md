# Testora v2.0.0+2

Release foun ba aplikasaun mobile **Testora**, ho melhoria boot ba jestaun admin, materia, ezame, perfil, login, notifikasaun push, relatoriu akademiku, no esperiensia estudante durante ezame.

## Ficheiru Release

- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`
- Plataforma: Android
- Versi aplikasaun: `2.0.0+2`

## Mudansa Prinsipal

- Admin labele troka uzuariu sai `admin` husi pajina jestaun uzuariu.
- Konta admin taka ona iha jestaun papel, no tab administrador hasai husi lista uzuariu.
- Uzuariu foun ka uzuariu non-admin ne'ebe la assign ba materia bele rejeita; se rejeita, asesu taka, papel hamoos, no konta rejeita bele hamoos husi database.
- Uzuariu ho papel estudante ka mestre labele login se seidauk assign ba materia.
- Papel estudante ka mestre labele troka bainhira uzuariu sei assign hela ba materia; admin tenke hasai uluk husi materia.
- Admin bele hasai estudante husi materia, hanesan funsaun hasai mestre ne'ebe iha ona.
- Materia ne'ebe sei iha mestre ka estudante assign ona labele hamoos; tombol hamoos la mosu no repository mos bloqueia delete.
- Perfil la halo tan error provider bainhira hili materia.
- Logout husi perfil la hatudu tan flash "Akontese sala" molok fila ba login.
- Login/logout entre role estudante, mestre, no admin agora reset provider sesaun atu evita error permisau role tuan.
- Uzuariu ne'ebe seidauk aprova ka rejeita labele login ba Testora.
- Page login agora hasai link `Haluha password?` tanba la presiza iha workflow atual.
- Page ezame admin no mestre agora respeita status `done`: mestre haree deit rezultadu, admin haree deit tombol hamoos.
- Timer ezame estudante agora tuir sisa tempu real husi jadwal ezame; se estudante tama tarde, timer komesa husi tempu ne'ebe hela.
- Se estudante sai husi ezame liu husi tombol `X`, resposta ne'ebe hatan ona entrega otomatikamente no ezame remata.
- Durante ezame, estudante agora bele uza tombol `Skip` atu hatama pergunta ba ikus, depois pergunta ne'e mosu fali bainhira pergunta seluk remata. Tombol `Skip` nonaktif se pergunta ida deit ka estudante iha pergunta ikus.
- Imajen iha tela ezame agora cache no timer la rebuild tela pergunta tomak, hodi evita kedip-kedip no scroll fila ba kraik.
- OneSignal atualiza ho App API Key foun, header REST foun, retry external ID, no binding `external_id` ne'ebe klaru bainhira user login.
- Push notification sei simu liu husi OneSignal external ID bainhira user login ona no seidauk logout, inklui bainhira aplikasaun taka ka la dijalankan.
- Push notification agora tuir alert ne'ebe iha iha page role ida-idak: admin simu pending publish, mestre no estudante simu publish/reminder/start ne'ebe relevante.
- Export PDF relatoriu admin agora iha kop akademiku Testora ho logo/monogram no tabela relatoriu formal; filter section iha kraik kop hasai ona.
- Page perfil Tetun atualiza label `Manajementu Konta` no `Lingua`.
- Label `Ujian` ajusta ba `Ezame` iha Tetun no `Exam` iha English.
- Tab ezame admin iha dark mode agora uza label mutin atu bele haree di'ak.
- Lista ezame estudante no istoria uza ezame publika deit, hodi evita dadus admin/mestre tama ba vista estudante.

## Funsaun Administrador

- Jere uzuariu ho regra seguransa foun: admin taka, rejeita uzuariu ne'ebe la assign ba materia, hamoos uzuariu rejeita, no bloqueia troka papel bainhira seidauk hasai husi materia.
- Jere materia ho assign mestre, assign estudante, hasai mestre, no hasai estudante.
- Materia ho mestre ka estudante ativo la hatudu tombol hamoos, atu evita dadus materia hamoos bainhira sei uza hela.
- Jere ezame ho tab `Hein Publika` no `Publika ona`, inklui suporta dark mode ne'ebe klaru.
- Hamoos ezame ne'ebe remata husi page admin.
- Export relatoriu ba PDF ho format akademiku Testora, kop formal, no tabela langsung depois kop.

## Funsaun Mestre

- Ezame ne'ebe remata hatudu deit aksaun `Haree Rezultadu`.
- Rezultadu no lista estudante tuir materia ne'ebe mestre assign ona.
- Bainhira mestre haruka ezame ba admin, admin deit mak simu alert/push pending publish.
- Mestre simu push publish, reminder, no ezame hahu ona bainhira admin publika ezame relevante.

## Funsaun Estudante

- Timer ezame tuir sisa tempu jadwal, la komesa sempre husi durasaun kompletu.
- Sai husi ezame entrega resposta ne'ebe iha ona, depois estudante labele tama fali ezame ne'e.
- Ezame ho imajen la kedip-kedip, no scroll pergunta hela stabil.
- Tombol `Skip` ajuda estudante la gasta tempu iha pergunta ne'ebe difisil; pergunta ne'ebe skip sei fila fali iha ikus.
- Lista ezame hatudu ezame publika no disponivel deit.

## Notifikasaun Push

- User ne'ebe login ona no seidauk logout sei hela ligadu ba OneSignal external ID, atu push bele tama mesmu aplikasaun taka.
- Se user logout, OneSignal session mos logout atu push la tama ba konta ne'ebe la ativo iha device.
- Login unread alert reminder kontinua, no routing push la uza subscription tuan ne'ebe bele nyangkut ba akun seluk.
- Push publish/reminder/start la tama ba admin se alert ne'e la iha iha page admin.

## Seguransa no Firestore

- Firestore rules atualiza atu uzuariu labele self-change papel ka status aktivu.
- Client labele assign papel admin.
- Role admin taka husi update biasa.
- Delete uzuariu permit deit ba uzuariu rejeita, inactive, no la iha papel.
- Admin bele rejeita non-admin deit bainhira uzuariu ne'e la assign ona ba materia.
- Hamoos materia bloqueia bainhira materia sei iha mestre ka estudante assign ona.

## Nota Instalasaun

Download APK husi GitHub Release, depois instala iha device Android. Se Android husu permisau instalasaun husi fonte liur, ativa permisau ne'e ba browser ka file manager ne'ebe uza atu loke APK.

## Nota Importante

- Aplikasaun presiza koneksaun internet atu asesu Firebase no OneSignal.
- Uzuariu foun tenke admin aprova, assign papel, no assign materia molok bele uza Testora.
- Push notification sei liga ba device ne'ebe uzuariu login ba aplikasaun.
- Depois update kode, build no instala APK foun atu fitur sira bele funsiona iha device.
