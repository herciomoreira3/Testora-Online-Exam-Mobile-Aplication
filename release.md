# Testora v2.0.0+2

Release foun ba aplikasaun mobile **Testora**, ho melhoria boot ba jestaun admin, materia, ezame, perfil, seguransa login, notifikasaun push, no relatoriu akademiku.

## Ficheiru Release

- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`
- Plataforma: Android
- Versi aplikasaun: `2.0.0+2`

## Mudansa Prinsipal

- Admin agora labele troka uzuariu sai `admin` husi pajina jestaun uzuariu.
- Konta admin taka ona iha jestaun papel, no tab administrador hasai husi lista uzuariu.
- Uzuariu foun bele rejeita; se rejeita, asesu taka, papel hamoos, no konta rejeita bele hamoos husi database.
- Papel estudante ka mestre labele troka bainhira uzuariu sei assign hela ba materia; admin tenke hasai uluk husi materia.
- Admin bele hasai estudante husi materia, hanesan funsaun hasai mestre ne'ebe iha ona.
- Perfil la halo tan error provider bainhira hili materia.
- Login/logout entre role estudante, mestre, no admin agora reset provider sesaun atu evita error permisau role tuan.
- Uzuariu ne'ebe seidauk aprova ka rejeita labele login ba Testora.
- Page ezame admin no mestre agora respeita status `done`: mestre haree deit rezultadu, admin haree deit tombol hamoos.
- Timer ezame estudante agora tuir sisa tempu real husi jadwal ezame; se estudante tama tarde, timer komesa husi tempu ne'ebe hela.
- Se estudante sai husi ezame liu husi tombol `X`, resposta ne'ebe hatan ona entrega otomatikamente no ezame remata.
- Imajen iha tela ezame agora cache no timer la rebuild tela pergunta tomak, hodi evita kedip-kedip no scroll fila ba kraik.
- OneSignal atualiza ho App API Key foun no header REST foun, atu push notification bele funsiona fali.
- Export PDF relatoriu admin agora iha kop akademiku ho logo/monogram Testora, data, resumo filtru, no tabela relatoriu ne'ebe formal.
- Page perfil Tetun atualiza label `Manajementu Konta` no `Lingua`.
- Tab ezame admin iha dark mode agora usa label mutin atu bele haree di'ak.
- Lista ezame estudante no istoria usa ezame publika deit, hodi evita dadus admin/mestre tama ba vista estudante.

## Funsaun Administrador

- Jere uzuariu ho regra seguransa foun: admin taka, rejeita uzuariu foun, hamoos uzuariu rejeita, no bloqueia troka papel bainhira seidauk hasai husi materia.
- Jere materia ho assign mestre, assign estudante, hasai mestre, no hasai estudante.
- Jere ezame ho tab `Hein Publika` no `Publika ona`, inklui suporta dark mode ne'ebe klaru.
- Hamoos ezame ne'ebe remata husi page admin.
- Export relatoriu ba PDF ho format akademiku Testora.

## Funsaun Mestre

- Ezame ne'ebe remata hatudu deit aksaun `Haree Rezultadu`.
- Rezultadu no lista estudante tuir materia ne'ebe mestre assign ona.
- Push alert kontinua ba publika ezame, reminder, no ezame hahu ona.

## Funsaun Estudante

- Timer ezame tuir sisa tempu jadwal, la komesa sempre husi durasaun kompletu.
- Sai husi ezame entrega resposta ne'ebe iha ona, depois estudante labele tama fali ezame ne'e.
- Ujian ho imajen la kedip-kedip, no scroll pergunta hela stabil.
- Lista ezame hatudu ezame publika no disponivel deit.

## Seguransa no Firestore

- Firestore rules atualiza atu uzuariu labele self-change papel ka status aktivu.
- Client labele assign papel admin.
- Role admin taka husi update biasa.
- Delete uzuariu permit deit ba uzuariu rejeita, inactive, no la iha papel.

## Nota Instalasaun

Download APK husi GitHub Release, depois instala iha device Android. Se Android husu permisau instalasaun husi fonte liur, ativa permisau ne'e ba browser ka file manager ne'ebe uza atu loke APK.

## Nota Importante

- Aplikasaun presiza koneksaun internet atu asesu Firebase no OneSignal.
- Uzuariu foun tenke admin aprova, assign papel, no assign materia molok bele uza Testora.
- Push notification sei liga ba device ne'ebe uzuariu login ba aplikasaun.
