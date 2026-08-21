const CACHE = "weather-app-v1";
const APP_SHELL = [
  "./",
  "./index.html",
  "./css/style.css",
  "./js/app.js",
  "./js/weathercodes.js",
  "./manifest.json",
  "./icons/icon.svg",
  "./icons/icon-192.png",
  "./icons/icon-512.png"
];

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(APP_SHELL)).then(()=>self.skipWaiting())
  );
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))
  );
  self.clients.claim();
});

// شبکه-اول برای درخواست‌های API آب‌وهوا، کش-اول برای فایل‌های ثابت برنامه
self.addEventListener("fetch", event => {
  const url = event.request.url;
  const isApi = url.includes("open-meteo.com") || url.includes("rainviewer.com") || url.includes("bigdatacloud.net");
  if (isApi) {
    event.respondWith(fetch(event.request).catch(()=>caches.match(event.request)));
    return;
  }
  event.respondWith(
    caches.match(event.request).then(cached => cached || fetch(event.request))
  );
});
