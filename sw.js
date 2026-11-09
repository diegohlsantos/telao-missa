/* Telão Missa — guarda o sistema e a missa no aparelho para o telão seguir sem internet.
   Páginas: rede primeiro, cópia guardada se cair.
   Bibliotecas e fontes: cópia guardada, atualiza por trás.
   Dados do Supabase (leituras, missa, acervo, imagens): rede primeiro, cópia guardada se cair. */
const V = "tm-v1";
const ESTATICO = V + "-estatico", DADOS = "tm-dados";

self.addEventListener("install", e => { self.skipWaiting(); });
self.addEventListener("activate", e => {
  e.waitUntil((async () => {
    for (const k of await caches.keys()) if (k.startsWith("tm-v") && !k.startsWith(V)) await caches.delete(k);
    await self.clients.claim();
  })());
});

function ehDadoSupabase(u){
  return u.hostname.endsWith(".supabase.co") && (u.pathname.startsWith("/rest/v1/") || u.pathname.startsWith("/functions/v1/liturgia") || u.pathname.startsWith("/storage/v1/object/public/"));
}
function ehBiblioteca(u){
  return ["cdn.jsdelivr.net","cdnjs.cloudflare.com","fonts.googleapis.com","fonts.gstatic.com"].includes(u.hostname);
}

async function redePrimeiro(req, nome){
  const cache = await caches.open(nome);
  try {
    const r = await fetch(req);
    if (r && (r.ok || r.type === "opaque")) cache.put(req, r.clone()).catch(()=>{});
    return r;
  } catch (err) {
    const c = await cache.match(req, {ignoreVary: true}) || (req.mode === "navigate" ? await cache.match(req, {ignoreSearch: true}) : null);
    if (c) return c;
    throw err;
  }
}
async function guardadoPrimeiro(req){
  const cache = await caches.open(ESTATICO);
  const c = await cache.match(req);
  const rede = fetch(req).then(r => { if (r && (r.ok || r.type === "opaque")) cache.put(req, r.clone()).catch(()=>{}); return r; }).catch(() => null);
  return c || (await rede) || Response.error();
}

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const u = new URL(req.url);
  if (u.origin === location.origin){
    if (u.pathname.endsWith("/sw.js")) return;
    e.respondWith(redePrimeiro(req, ESTATICO));
  } else if (ehBiblioteca(u)) {
    e.respondWith(guardadoPrimeiro(req));
  } else if (ehDadoSupabase(u)) {
    e.respondWith(redePrimeiro(req, DADOS));
  }
});

self.addEventListener("message", e => {
  if (e.data === "limpar-dados") caches.delete(DADOS);
});
