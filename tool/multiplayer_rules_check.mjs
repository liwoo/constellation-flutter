// Replays the multiplayer backend's writes against the Realtime Database
// emulator, as different players, and checks database.rules.json allows or
// denies each one.
//
//   firebase emulators:start --only auth,database --project demo-constellation
//   curl -X PUT -H "Authorization: Bearer owner" --data-binary @database.rules.json \
//     "http://127.0.0.1:9000/.settings/rules.json?ns=demo-constellation"
//   node tool/multiplayer_rules_check.mjs
//
// (Older firebase-tools don't load the rules into the demo namespace on
// their own - hence the curl.) Ports: DATABASE_EMULATOR_PORT, AUTH_EMULATOR_PORT.
const DB = `http://127.0.0.1:${process.env.DATABASE_EMULATOR_PORT ?? 9000}`;
const NS = 'demo-constellation';
const AUTH = `http://127.0.0.1:${process.env.AUTH_EMULATOR_PORT ?? 9099}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`;

async function signUp() {
  const r = await fetch(AUTH, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ returnSecureToken: true }) });
  const j = await r.json();
  return { uid: j.localId, token: j.idToken };
}

async function req(who, method, path, body) {
  const url = `${DB}/${path}.json?ns=${NS}` + (who ? `&auth=${who.token}` : '');
  const r = await fetch(url, { method, headers: { 'content-type': 'application/json' }, body: body === undefined ? undefined : JSON.stringify(body) });
  return r.status;
}

let failures = 0;
async function expectOk(label, p) { const s = await p; const ok = s === 200; if (!ok) failures++; console.log(`${ok ? 'PASS' : 'FAIL'}  allowed  ${label} (${s})`); }
async function expectDenied(label, p) { const s = await p; const ok = s === 401 || s === 403 || s === 400; if (!ok) failures++; console.log(`${ok ? 'PASS' : 'FAIL'}  denied   ${label} (${s})`); }

const ana = await signUp(), ben = await signUp(), cy = await signUp();
const code = 'R' + Math.floor(Math.random() * 1e6);
const room = `rooms/${code}`;
const now = Date.now();

// Opening a room (FirebaseMatchBackend.createRoom transaction)
await expectDenied('open a room as someone else', req(ana, 'PUT', room, { hostId: ben.uid, createdAt: now, state: { status: 'lobby' }, players: { [ana.uid]: { name: 'Ana', joinedAt: now, online: true } } }));
await expectOk('open a room as its host', req(ana, 'PUT', room, { hostId: ana.uid, createdAt: now, state: { status: 'lobby' }, players: { [ana.uid]: { name: 'Ana', joinedAt: now, online: true } } }));
await expectDenied('overwrite an existing room', req(ben, 'PUT', room, { hostId: ben.uid, createdAt: now, state: { status: 'lobby' } }));
await expectDenied('read without signing in', req(null, 'GET', room));
await expectOk('read the room', req(ben, 'GET', room));

// Joining (joinRoom: set own seat with a server timestamp)
await expectOk('take a seat', req(ben, 'PUT', `${room}/players/${ben.uid}`, { name: 'Ben', joinedAt: { '.sv': 'timestamp' }, online: true }));
await expectDenied('sit someone else down', req(ben, 'PUT', `${room}/players/${cy.uid}`, { name: 'Cy', joinedAt: now, online: true }));
await expectDenied('rename another player', req(ben, 'PATCH', `${room}/players/${ana.uid}`, { name: 'Loser' }));
await expectDenied('a 15-letter name', req(cy, 'PUT', `${room}/players/${cy.uid}`, { name: 'x'.repeat(15), joinedAt: now, online: true }));
await expectDenied('a seat in a room that does not exist', req(cy, 'PUT', `rooms/NOPE${code}/players/${cy.uid}`, { name: 'Cy', joinedAt: now, online: true }));
await expectOk('rejoin: update own name/online', req(ben, 'PATCH', `${room}/players/${ben.uid}`, { name: 'Benny', online: true }));
await expectOk('go offline (presence onDisconnect)', req(ben, 'PUT', `${room}/players/${ben.uid}/online`, false));
await expectOk('come back online', req(ben, 'PUT', `${room}/players/${ben.uid}/online`, true));

// Starting (startMatch: multi-path update at the room)
await expectDenied('start a match from outside the table', req(cy, 'PATCH', room, { setup: { seed: 1, rounds: [] }, answers: null, state: { status: 'playing', round: 0, startsAt: now, endsAt: now + 1 } }));
await expectOk('start the match', req(ana, 'PATCH', room, { setup: { seed: 1, rounds: [{ letter: 'C', categories: ['A', 'B', 'C', 'D', 'E'] }] }, answers: null, state: { status: 'playing', round: 0, startsAt: now, endsAt: now + 180000 } }));
await expectDenied('a new seat once the match started', req(cy, 'PUT', `${room}/players/${cy.uid}`, { name: 'Cy', joinedAt: now, online: true }));

// Answers (submitAnswer)
await expectOk('record own answer', req(ben, 'PUT', `${room}/answers/r0/${ben.uid}/c0`, { word: 'CAT', points: 5, at: { '.sv': 'timestamp' } }));
await expectDenied('backdate an answer', req(ben, 'PUT', `${room}/answers/r0/${ben.uid}/c1`, { word: 'COW', points: 5, at: 1 }));
await expectDenied('answer for someone else', req(ben, 'PUT', `${room}/answers/r0/${ana.uid}/c0`, { word: 'CAT', points: 5, at: { '.sv': 'timestamp' } }));
await expectDenied('answer from outside the table', req(cy, 'PUT', `${room}/answers/r0/${cy.uid}/c0`, { word: 'CAT', points: 5, at: { '.sv': 'timestamp' } }));
await expectDenied('wipe the answers mid-match... with data', req(ben, 'PUT', `${room}/answers`, { r0: {} , x: 1}));

// Ending a round (endRound transaction on state)
await expectOk('end the round', req(ben, 'PUT', `${room}/state`, { status: 'finished', round: 0, startsAt: now, endsAt: now + 180000, ends: { r0: { by: ben.uid, at: now + 1000 } } }));
await expectDenied('a made-up status', req(ben, 'PATCH', `${room}/state`, { status: 'hacked' }));

// Rematch (backToLobby)
await expectOk('back to the lobby', req(ana, 'PATCH', room, { setup: null, answers: null, state: { status: 'lobby' } }));
await expectDenied('junk at the room root', req(ana, 'PATCH', room, { junk: 1 }));

// Leaving (leaveRoom)
await expectDenied('close a room with players in it', req(ana, 'DELETE', room));
await expectOk('give up own seat (Ben)', req(ben, 'DELETE', `${room}/players/${ben.uid}`));
await expectOk('give up own seat (Ana)', req(ana, 'DELETE', `${room}/players/${ana.uid}`));
await expectOk('last one out closes the room', req(ana, 'DELETE', room));

console.log(failures ? `\n${failures} rule check(s) failed` : '\nAll rule checks passed');
process.exit(failures ? 1 : 0);
