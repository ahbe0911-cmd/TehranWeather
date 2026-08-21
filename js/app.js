/* ===========================================================
   اپلیکیشن هواشناسی صفی‌آباد
   منبع داده: Open-Meteo (رایگان، بدون کلید)
   =========================================================== */

// موقعیت پیش‌فرض: صفی‌آباد، بخش کوهسارات، شهرستان مینودشت، استان گلستان
// (بر اساس لینک نقشه ارسال‌شده توسط کاربر)
const DEFAULT_LOCATION = {
  name: "صفی‌آباد",
  region: "مینودشت، گلستان",
  lat: 37.32,
  lon: 55.15
};

const state = {
  location: loadJSON("wx_location", DEFAULT_LOCATION),
  units: loadJSON("wx_units", {temp:"c", wind:"kmh"}),
  theme: localStorage.getItem("wx_theme") || "auto",
  reminders: loadJSON("wx_reminders", {chatr:true, plant:false}),
  data: null,
  aqi: null
};

function loadJSON(key, fallback){
  try{ const v = localStorage.getItem(key); return v ? JSON.parse(v) : fallback; }
  catch(e){ return fallback; }
}
function saveJSON(key, val){ localStorage.setItem(key, JSON.stringify(val)); }

// ---------------------------------------------------------------
// عناصر DOM
// ---------------------------------------------------------------
const $ = sel => document.querySelector(sel);
const els = {
  cityName: $("#cityName"), cityDate: $("#cityDate"),
  digitalTime: $("#digitalTime"), clockFace: $("#clockFace"),
  curTemp: $("#curTemp"), curHumidity: $("#curHumidity"),
  hourlyStrip: $("#hourlyStrip"), mapStrip: $("#mapStrip"),
  statFeels: $("#statFeels"), statWind: $("#statWind"),
  statHum: $("#statHum"), statPressure: $("#statPressure"),
  dailyList: $("#dailyList"), dailySummary: $("#dailySummary"),
  dPressure:$("#dPressure"), dUv:$("#dUv"), dWindDir:$("#dWindDir"),
  dSunrise:$("#dSunrise"), dSunset:$("#dSunset"), dVisibility:$("#dVisibility"),
  dAqi:$("#dAqi"), dFeels:$("#dFeels"), dDewpoint:$("#dDewpoint"),
  alertsList:$("#alertsList"), alertDot:$("#alertDot"),
  toast:$("#toast")
};

function showToast(msg){
  els.toast.textContent = msg;
  els.toast.classList.add("show");
  setTimeout(()=>els.toast.classList.remove("show"), 2200);
}

// ---------------------------------------------------------------
// ناوبری بین صفحات
// ---------------------------------------------------------------
document.querySelectorAll(".navbtn").forEach(btn=>{
  btn.addEventListener("click", ()=>{
    document.querySelectorAll(".navbtn").forEach(b=>b.classList.remove("active"));
    btn.classList.add("active");
    document.querySelectorAll(".view").forEach(v=>v.classList.remove("active"));
    $("#view-"+btn.dataset.view).classList.add("active");
    if(btn.dataset.view === "map") setTimeout(initMapIfNeeded, 50);
  });
});

$("#alertsBtn").addEventListener("click", ()=> $("#view-alerts").classList.add("open"));
$("#closeAlertsBtn").addEventListener("click", ()=> $("#view-alerts").classList.remove("open"));
$("#menuBtn").addEventListener("click", ()=> $("#view-settings").classList.add("open"));
$("#closeSettingsBtn").addEventListener("click", ()=> $("#view-settings").classList.remove("open"));

// ---------------------------------------------------------------
// ساعت آنالوگ (SVG)
// ---------------------------------------------------------------
function buildClockFace(){
  const svg = els.clockFace;
  const cx=110, cy=110, r=100;
  let html = `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="rgba(120,140,160,.25)" stroke-width="2"/>`;
  for(let i=0;i<12;i++){
    const ang = i*30*Math.PI/180;
    const x1 = cx + (r-8)*Math.sin(ang), y1 = cy - (r-8)*Math.cos(ang);
    const x2 = cx + (r-16)*Math.sin(ang), y2 = cy - (r-16)*Math.cos(ang);
    html += `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="rgba(120,140,160,.35)" stroke-width="2"/>`;
  }
  const faNums = ["۱۲","۱","۲","۳","۴","۵","۶","۷","۸","۹","۱۰","۱۱"];
  for(let i=0;i<12;i++){
    const ang = i*30*Math.PI/180;
    const x = cx + (r-30)*Math.sin(ang), y = cy - (r-30)*Math.cos(ang) + 5;
    html += `<text x="${x}" y="${y}" text-anchor="middle" font-size="15" fill="var(--text-main)" font-family="Vazirmatn">${faNums[i]}</text>`;
  }
  html += `<line id="hourHand" x1="${cx}" y1="${cy}" x2="${cx}" y2="${cy-45}" stroke="#e05a5a" stroke-width="5" stroke-linecap="round"/>`;
  html += `<line id="minHand" x1="${cx}" y1="${cy}" x2="${cx}" y2="${cy-70}" stroke="#2f8fe6" stroke-width="4" stroke-linecap="round"/>`;
  html += `<line id="secHand" x1="${cx}" y1="${cy}" x2="${cx}" y2="${cy-78}" stroke="#f0a020" stroke-width="2" stroke-linecap="round"/>`;
  html += `<circle cx="${cx}" cy="${cy}" r="5" fill="var(--text-main)"/>`;
  html += `<text x="${cx}" y="${cy+55}" text-anchor="middle" font-size="10" fill="var(--text-sub)" font-family="Vazirmatn">${state.location.name}</text>`;
  svg.innerHTML = html;
}
function tickClock(){
  const now = new Date();
  const h = now.getHours()%12, m = now.getMinutes(), s = now.getSeconds();
  const cx=110, cy=110;
  const hourAngle = (h+m/60)*30, minAngle = m*6, secAngle = s*6;
  const set = (id, len, ang) => {
    const el = $("#"+id); if(!el) return;
    const rad = ang*Math.PI/180;
    el.setAttribute("x2", cx + len*Math.sin(rad));
    el.setAttribute("y2", cy - len*Math.cos(rad));
  };
  set("hourHand",45,hourAngle); set("minHand",70,minAngle); set("secHand",78,secAngle);
  els.digitalTime.textContent = toFaDigits(now.toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"})) + " " + (now.getHours()<12?"صبح":"عصر");
  els.cityDate.textContent = faDateLong(now);
}
buildClockFace();
setInterval(tickClock, 1000);
tickClock();

// ---------------------------------------------------------------
// دریافت داده آب‌وهوا از Open-Meteo
// ---------------------------------------------------------------
async function fetchWeather(){
  const {lat, lon} = state.location;
  els.cityName.textContent = state.location.name;
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` +
    `&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,is_day,dew_point_2m` +
    `&hourly=temperature_2m,precipitation_probability,precipitation,weather_code` +
    `&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,wind_speed_10m_max,uv_index_max,sunrise,sunset` +
    `&timezone=auto&forecast_days=8&visibility=true`;
  try{
    const res = await fetch(url);
    const data = await res.json();
    state.data = data;
    renderAll();
  }catch(e){
    showToast("خطا در دریافت اطلاعات آب‌وهوا. اتصال اینترنت را بررسی کنید.");
  }

  // کیفیت هوا
  try{
    const aq = await fetch(`https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${lat}&longitude=${lon}&current=us_aqi,pm2_5&timezone=auto`);
    state.aqi = await aq.json();
    renderAqi();
  }catch(e){ /* اختیاری - نادیده گرفتن خطا */ }
}

function convTemp(c){
  return state.units.temp === "f" ? Math.round(c*9/5+32) : Math.round(c);
}
function tempUnitLabel(){ return state.units.temp === "f" ? "°F" : "°C"; }
function convWind(kmh){
  if(state.units.wind === "ms") return (kmh/3.6).toFixed(1)+" m/s";
  if(state.units.wind === "mph") return Math.round(kmh*0.621)+" mph";
  return Math.round(kmh)+" km/h";
}
function windDirLabel(deg){
  const dirs = ["شمالی","شمال‌شرقی","شرقی","جنوب‌شرقی","جنوبی","جنوب‌غربی","غربی","شمال‌غربی"];
  return dirs[Math.round(deg/45)%8];
}

function renderAll(){
  if(!state.data) return;
  const d = state.data;
  const cur = d.current;

  // --- کارت ساعتی ---
  els.curTemp.textContent = toFaDigits(convTemp(cur.temperature_2m)) + tempUnitLabel().replace("°","°");
  els.curHumidity.textContent = toFaDigits(Math.round(cur.relative_humidity_2m)) + "%";
  els.statFeels.textContent = toFaDigits(convTemp(cur.apparent_temperature)) + "°";
  els.statWind.textContent = toFaDigits(convWind(cur.wind_speed_10m).split(" ")[0]) + (state.units.wind==="kmh"?" کیلومتر/ساعت":"");
  els.statHum.textContent = toFaDigits(Math.round(cur.relative_humidity_2m)) + "%";
  els.statPressure.textContent = toFaDigits(Math.round(cur.surface_pressure)) + " hPa";

  // نوار ساعتی بارش
  const nowIdx = d.hourly.time.findIndex(t => new Date(t) >= new Date(d.current.time)) || 0;
  let hourlyHtml = "";
  for(let i=Math.max(nowIdx,0); i<Math.min(nowIdx+9, d.hourly.time.length); i++){
    const t = new Date(d.hourly.time[i]);
    const info = wmoInfo(d.hourly.weather_code[i], cur.is_day);
    hourlyHtml += `<div class="hour-item">
      <div>${toFaDigits(t.getHours())}</div>
      <div class="hi">${info.icon}</div>
      <div class="hp">${toFaDigits(d.hourly.precipitation_probability[i]||0)}%</div>
    </div>`;
  }
  els.hourlyStrip.innerHTML = hourlyHtml;
  els.mapStrip.innerHTML = hourlyHtml;

  // --- روزانه ---
  let dailyHtml = "";
  for(let i=0;i<d.daily.time.length;i++){
    const date = new Date(d.daily.time[i]);
    const {weekday,label} = faDateShort(date);
    const info = wmoInfo(d.daily.weather_code[i], 1);
    dailyHtml += `<div class="daily-row">
      <div class="daily-day">${i===0?"امروز":weekday}<small>${label}</small></div>
      <div class="daily-icon">${info.icon}</div>
      <div class="daily-desc">${info.text}</div>
      <div class="daily-temps"><span>${toFaDigits(convTemp(d.daily.temperature_2m_max[i]))}°</span><span class="lo">${toFaDigits(convTemp(d.daily.temperature_2m_min[i]))}°</span></div>
    </div>`;
  }
  els.dailyList.innerHTML = dailyHtml;

  // خلاصه وضعیت هفته
  const rainyDays = d.daily.precipitation_probability_max.filter(p=>p>=50).length;
  const maxTemp = Math.max(...d.daily.temperature_2m_max);
  const minTemp = Math.min(...d.daily.temperature_2m_min);
  els.dailySummary.textContent = rainyDays > 0
    ? `طی روزهای آینده، احتمال بارش باران در ${toFaDigits(rainyDays)} روز وجود دارد. دمای هوا بین ${toFaDigits(convTemp(minTemp))}° تا ${toFaDigits(convTemp(maxTemp))}° در نوسان خواهد بود.`
    : `هوای پیش‌رو عمدتاً پایدار پیش‌بینی می‌شود. دمای هوا بین ${toFaDigits(convTemp(minTemp))}° تا ${toFaDigits(convTemp(maxTemp))}° در نوسان خواهد بود.`;

  // --- جزئیات ---
  els.dPressure.textContent = toFaDigits(Math.round(cur.surface_pressure)) + " hPa";
  els.dUv.textContent = toFaDigits(Math.round(d.daily.uv_index_max[0]));
  els.dWindDir.textContent = windDirLabel(cur.wind_direction_10m);
  els.dSunrise.textContent = toFaDigits(new Date(d.daily.sunrise[0]).toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"}));
  els.dSunset.textContent = toFaDigits(new Date(d.daily.sunset[0]).toLocaleTimeString("en-GB",{hour:"2-digit",minute:"2-digit"}));
  els.dVisibility.textContent = "—";
  els.dFeels.textContent = toFaDigits(convTemp(cur.apparent_temperature)) + "°";
  els.dDewpoint.textContent = toFaDigits(convTemp(cur.dew_point_2m)) + "°";

  buildClockFace();
  renderAlerts();
}

function renderAqi(){
  if(!state.aqi || !state.aqi.current) return;
  const aqi = Math.round(state.aqi.current.us_aqi);
  let label = "خوب";
  if(aqi>150) label="ناسالم"; else if(aqi>100) label="نسبتاً ناسالم"; else if(aqi>50) label="متوسط";
  els.dAqi.innerHTML = toFaDigits(aqi) + `<br><small style="font-size:10px">${label}</small>`;
}

// ---------------------------------------------------------------
// هشدارهای هوشمند (بر پایه آستانه‌های بارش/باد)
// ---------------------------------------------------------------
function renderAlerts(){
  const d = state.data;
  if(!d) return;
  const alerts = [];
  const maxPrecipProb = Math.max(...d.daily.precipitation_probability_max.slice(0,3));
  const maxWind = Math.max(...d.daily.wind_speed_10m_max.slice(0,3));

  if(maxPrecipProb >= 70){
    const idx = d.daily.precipitation_probability_max.findIndex(p=>p===maxPrecipProb);
    const {weekday,label} = faDateShort(new Date(d.daily.time[idx]));
    alerts.push({level:"danger", icon:"🌧️", title:"هشدار بارش شدید",
      text:`احتمال بارش شدید باران و رعدوبرق در روز ${weekday} ${label}`, tag:"سطح هشدار: قرمز"});
  } else if(maxPrecipProb >= 50){
    alerts.push({level:"warn", icon:"🌦️", title:"احتمال بارش",
      text:`احتمال بارش پراکنده باران طی روزهای آینده`, tag:"سطح هشدار: زرد"});
  }
  if(maxWind >= 40){
    const idx = d.daily.wind_speed_10m_max.findIndex(w=>w===maxWind);
    const {weekday,label} = faDateShort(new Date(d.daily.time[idx]));
    alerts.push({level: maxWind>=60?"danger":"warn", icon:"💨", title:"باد شدید",
      text:`وزش باد با سرعت تا ${toFaDigits(Math.round(maxWind))} کیلومتر بر ساعت در روز ${weekday} ${label}`,
      tag: maxWind>=60 ? "سطح هشدار: قرمز" : "سطح هشدار: زرد"});
  }
  const maxUv = Math.max(...d.daily.uv_index_max.slice(0,3));
  if(maxUv >= 8){
    alerts.push({level:"warn", icon:"🔆", title:"شاخص UV بالا", text:"در ساعات میانی روز از قرارگیری طولانی زیر نور مستقیم آفتاب خودداری کنید.", tag:"سطح هشدار: زرد"});
  }

  els.alertDot.hidden = alerts.length === 0;
  if(alerts.length === 0){
    els.alertsList.innerHTML = `<div class="no-alerts"><span class="big">✅</span>در حال حاضر هشدار فعالی برای ${state.location.name} ثبت نشده است.</div>`;
    return;
  }
  els.alertsList.innerHTML = alerts.map(a => `
    <div class="alert-card ${a.level}">
      <span class="ai">${a.icon}</span>
      <div><h4>${a.title}</h4><p>${a.text}</p><span class="alert-level">${a.tag}</span></div>
    </div>`).join("");
}

// ---------------------------------------------------------------
// نقشه و رادار (Leaflet + RainViewer)
// ---------------------------------------------------------------
let map, radarLayer;
function initMapIfNeeded(){
  if(map) { map.invalidateSize(); return; }
  map = L.map('radarMap', {zoomControl:false, attributionControl:false}).setView([state.location.lat, state.location.lon], 8);
  L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {maxZoom:12}).addTo(map);
  L.marker([state.location.lat, state.location.lon]).addTo(map).bindPopup(state.location.name);
  L.control.zoom({position:'bottomleft'}).addTo(map);

  fetch('https://api.rainviewer.com/public/weather-maps.json')
    .then(r=>r.json())
    .then(json=>{
      const frame = json.radar && json.radar.past ? json.radar.past.slice(-1)[0] : null;
      if(!frame) return;
      radarLayer = L.tileLayer(`${json.host}${frame.path}/256/{z}/{x}/{y}/4/1_1.png`, {opacity:0.55, maxZoom:12}).addTo(map);
    }).catch(()=>{});
}

// ---------------------------------------------------------------
// جستجوی شهر / موقعیت (تنظیمات)
// ---------------------------------------------------------------
let searchTimer;
$("#citySearchInput").addEventListener("input", e=>{
  clearTimeout(searchTimer);
  const q = e.target.value.trim();
  if(q.length < 2){ $("#citySearchResults").innerHTML=""; return; }
  searchTimer = setTimeout(()=>searchCity(q), 350);
});
async function searchCity(q){
  try{
    const res = await fetch(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(q)}&count=6&language=fa&format=json`);
    const json = await res.json();
    const results = json.results || [];
    $("#citySearchResults").innerHTML = results.map(r=>
      `<div class="result-item" data-lat="${r.latitude}" data-lon="${r.longitude}" data-name="${r.name}" data-region="${r.admin1||r.country||''}">
        ${r.name} <small style="color:var(--text-sub)">— ${r.admin1||r.country||''}</small>
      </div>`).join("") || `<div class="result-item">نتیجه‌ای یافت نشد</div>`;
    document.querySelectorAll("#citySearchResults .result-item[data-lat]").forEach(item=>{
      item.addEventListener("click", ()=>{
        state.location = {name:item.dataset.name, region:item.dataset.region, lat:parseFloat(item.dataset.lat), lon:parseFloat(item.dataset.lon)};
        saveJSON("wx_location", state.location);
        $("#citySearchInput").value = ""; $("#citySearchResults").innerHTML = "";
        map = null; // اجبار به بازسازی نقشه با موقعیت جدید
        showToast(`موقعیت به «${state.location.name}» تغییر کرد`);
        fetchWeather();
      });
    });
  }catch(e){ showToast("خطا در جستجوی موقعیت"); }
}

$("#useMyLocationBtn").addEventListener("click", ()=>{
  if(!navigator.geolocation){ showToast("مرورگر شما مکان‌یابی را پشتیبانی نمی‌کند"); return; }
  showToast("در حال یافتن موقعیت شما…");
  navigator.geolocation.getCurrentPosition(async pos=>{
    const {latitude, longitude} = pos.coords;
    let name = "موقعیت من";
    try{
      const r = await fetch(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=fa`);
      const j = await r.json();
      name = j.city || j.locality || name;
    }catch(e){}
    state.location = {name, region:"", lat:latitude, lon:longitude};
    saveJSON("wx_location", state.location);
    map = null;
    showToast(`موقعیت به «${name}» تغییر کرد`);
    fetchWeather();
  }, ()=> showToast("دسترسی به موقعیت مکانی ممکن نشد"));
});

// ---------------------------------------------------------------
// تنظیمات واحد / تم / یادآوری
// ---------------------------------------------------------------
$("#unitTemp").value = state.units.temp;
$("#unitWind").value = state.units.wind;
$("#themeSelect").value = state.theme;
$("#remChatr").checked = state.reminders.chatr;
$("#remPlant").checked = state.reminders.plant;
applyTheme(state.theme);

$("#unitTemp").addEventListener("change", e=>{ state.units.temp = e.target.value; saveJSON("wx_units", state.units); renderAll(); });
$("#unitWind").addEventListener("change", e=>{ state.units.wind = e.target.value; saveJSON("wx_units", state.units); renderAll(); });
$("#themeSelect").addEventListener("change", e=>{ state.theme = e.target.value; localStorage.setItem("wx_theme", state.theme); applyTheme(state.theme); });
$("#remChatr").addEventListener("change", e=>{ state.reminders.chatr = e.target.checked; saveJSON("wx_reminders", state.reminders); });
$("#remPlant").addEventListener("change", e=>{ state.reminders.plant = e.target.checked; saveJSON("wx_reminders", state.reminders); });

function applyTheme(t){
  document.body.classList.remove("theme-auto","theme-light","theme-dark");
  document.body.classList.add("theme-"+t);
}

// ---------------------------------------------------------------
// شروع برنامه
// ---------------------------------------------------------------
fetchWeather();
setInterval(fetchWeather, 15*60*1000); // به‌روزرسانی هر ۱۵ دقیقه
