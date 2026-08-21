// نگاشت کدهای هواشناسی WMO به آیکون و توضیح فارسی
const WMO = {
  0:  {icon:"☀️", day:"آفتابی", night:"صاف"},
  1:  {icon:"🌤️", day:"عمدتاً آفتابی", night:"عمدتاً صاف"},
  2:  {icon:"⛅", day:"نیمه‌ابری", night:"نیمه‌ابری"},
  3:  {icon:"☁️", day:"ابری", night:"ابری"},
  45: {icon:"🌫️", day:"مه‌آلود", night:"مه‌آلود"},
  48: {icon:"🌫️", day:"مه یخی", night:"مه یخی"},
  51: {icon:"🌦️", day:"نم‌نم باران سبک", night:"نم‌نم باران سبک"},
  53: {icon:"🌦️", day:"نم‌نم باران", night:"نم‌نم باران"},
  55: {icon:"🌧️", day:"نم‌نم باران شدید", night:"نم‌نم باران شدید"},
  56: {icon:"🌧️", day:"باران یخ‌زده سبک", night:"باران یخ‌زده سبک"},
  57: {icon:"🌧️", day:"باران یخ‌زده", night:"باران یخ‌زده"},
  61: {icon:"🌧️", day:"بارش پراکنده", night:"بارش پراکنده"},
  63: {icon:"🌧️", day:"بارانی", night:"بارانی"},
  65: {icon:"🌧️", day:"باران شدید", night:"باران شدید"},
  66: {icon:"🌧️", day:"باران یخ‌زده سبک", night:"باران یخ‌زده سبک"},
  67: {icon:"🌧️", day:"باران یخ‌زده شدید", night:"باران یخ‌زده شدید"},
  71: {icon:"🌨️", day:"برف سبک", night:"برف سبک"},
  73: {icon:"🌨️", day:"برفی", night:"برفی"},
  75: {icon:"❄️", day:"برف شدید", night:"برف شدید"},
  77: {icon:"🌨️", day:"دانه‌های برف", night:"دانه‌های برف"},
  80: {icon:"🌦️", day:"رگبار سبک", night:"رگبار سبک"},
  81: {icon:"🌧️", day:"رگبار", night:"رگبار"},
  82: {icon:"⛈️", day:"رگبار شدید", night:"رگبار شدید"},
  85: {icon:"🌨️", day:"رگبار برف سبک", night:"رگبار برف سبک"},
  86: {icon:"❄️", day:"رگبار برف شدید", night:"رگبار برف شدید"},
  95: {icon:"⛈️", day:"رعد و برق", night:"رعد و برق"},
  96: {icon:"⛈️", day:"رعد و برق با تگرگ سبک", night:"رعد و برق با تگرگ سبک"},
  99: {icon:"⛈️", day:"رعد و برق با تگرگ شدید", night:"رعد و برق با تگرگ شدید"}
};

function wmoInfo(code, isDay=1){
  const e = WMO[code] || WMO[3];
  return {icon:e.icon, text: isDay ? e.day : e.night};
}

const WEEKDAYS_FA = ["یکشنبه","دوشنبه","سه‌شنبه","چهارشنبه","پنجشنبه","جمعه","شنبه"];

// تبدیل ساده میلادی به شمسی (بدون کتابخانه خارجی)
function toJalali(gy, gm, gd){
  const g_d_m = [0,31,59,90,120,151,181,212,243,273,304,334];
  let jy = (gy <= 1600) ? 0 : 979;
  gy -= (gy <= 1600) ? 621 : 1600;
  let gy2 = (gm > 2) ? (gy + 1) : gy;
  let days = (365*gy) + (parseInt((gy2+3)/4)) - parseInt((gy2+99)/100) + parseInt((gy2+399)/400) - 80 + gd + g_d_m[gm-1];
  jy += 33*parseInt(days/12053);
  days %= 12053;
  jy += 4*parseInt(days/1461);
  days %= 1461;
  if (days > 365){
    jy += parseInt((days-1)/365);
    days = (days-1)%365;
  }
  let jm = (days < 186) ? 1+parseInt(days/31) : 7+parseInt((days-186)/30);
  let jd = 1 + ((days < 186) ? (days%31) : ((days-186)%30));
  return [jy, jm, jd];
}
const JALALI_MONTHS = ["فروردین","اردیبهشت","خرداد","تیر","مرداد","شهریور","مهر","آبان","آذر","دی","بهمن","اسفند"];
const FA_DIGITS = ["۰","۱","۲","۳","۴","۵","۶","۷","۸","۹"];
function toFaDigits(str){
  return String(str).replace(/[0-9]/g, d => FA_DIGITS[d]);
}
function faDateLong(date){
  const [jy,jm,jd] = toJalali(date.getFullYear(), date.getMonth()+1, date.getDate());
  const weekday = WEEKDAYS_FA[date.getDay()];
  return `${weekday} ${toFaDigits(jd)} ${JALALI_MONTHS[jm-1]} ${toFaDigits(jy)}`;
}
function faDateShort(date){
  const [,jm,jd] = toJalali(date.getFullYear(), date.getMonth()+1, date.getDate());
  return {weekday: WEEKDAYS_FA[date.getDay()], label: `${toFaDigits(jd)} ${JALALI_MONTHS[jm-1]}`};
}
