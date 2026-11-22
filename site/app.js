(() => {
  "use strict";

  const STORAGE_KEY = "pks_lang";
  const RELEASE_API = "https://api.github.com/repos/pksofttech/pks_factory_simulator/releases/latest";

  const TRANSLATIONS = {
    th: {
      "nav.features": "ฟีเจอร์",
      "nav.web": "เล่นบนเว็บ",
      "nav.examples": "โปรเจกต์ตัวอย่าง",
      "nav.controls": "การควบคุม",
      "nav.download": "ดาวน์โหลด",
      "nav.playCta": "เล่นบนเว็บ",

      "hero.title": "จำลองสายพานโรงงาน 3 มิติ และระบบอัตโนมัติ PLC แบบครบวงจร",
      "hero.subtitle":
        "ออกแบบสายการผลิต 3 มิติ เชื่อมต่อเซนเซอร์และแอคชูเอเตอร์ เขียนโปรแกรม Internal Ladder PLC หรือเชื่อมต่อ Modbus TCP ภายนอก พร้อม NPC อัตโนมัติ เล่นได้ทันทีทั้งบนเว็บเบราว์เซอร์และ PC",
      "hero.ctaWeb": "ทดลองเล่นบนเว็บทันที",
      "hero.ctaDownload": "ดาวน์โหลด PC (Windows / Linux)",

      "web.eyebrow": "LIVE WEBGL SANDBOX",
      "web.title": "ทดลองใช้งาน Simulator บนเว็บเบราว์เซอร์",
      "web.desc":
        "คลิกเปิดใช้งานเพื่อโหลดตัวจำลอง 3 มิติ (WebAssembly) เฉพาะเมื่อคุณต้องการ เพื่อความรวดเร็วในการเปิดหน้าเว็บ",
      "web.btnLaunch": "เปิด Simulator",
      "web.btnStop": "หยุดการทำงาน",
      "web.btnFullscreen": "เต็มหน้าจอ",
      "web.btnNewTab": "เปิดแท็บใหม่",
      "web.placeholderTitle": "พร้อมจำลองสายพาน 3D บนเบราว์เซอร์",
      "web.placeholderDesc":
        "รองรับทั้งเมาส์คีย์บอร์ดบนคอมพิวเตอร์ และระบบสัมผัส (Touch) บนมือถือ/แท็บเล็ต",
      "web.btnLaunchBig": "Launch Web Simulator",
      "web.note":
        "หมายเหตุ: เวอร์ชันเว็บทำงานในโหมด Internal Ladder PLC และ Manual บนเบราว์เซอร์ Desktop & Mobile สำหรับการเชื่อมต่อ Modbus TCP Server/Client กรุณาดาวน์โหลดเวอร์ชัน PC (Windows / Linux) ด้านล่าง",

      "features.eyebrow": "CAPABILITIES",
      "features.title": "ความสามารถหลักของระบบ",
      "features.subtitle":
        "เครื่องมือครบชุดสำหรับการเรียนรู้ ออกแบบ ทดสอบตรรกะ PLC และจำลองกระบวนการผลิตจริง",
      "features.f1.title": "อุปกรณ์อุตสาหกรรม 3 มิติ",
      "features.f1.desc":
        "สายพาน 9m/3m, โต๊ะหมุน 90°, ตัวปล่อยกล่อง (Emitter), ตัวเก็บกล่อง (Remover), ถังคัดแยก (Reject Bin), แขนดัน (Pusher), ตัวกั้น (Stopper), ปั๊มน้ำ, ถังน้ำ และโซลินอยด์วาล์ว",
      "features.f2.title": "เซนเซอร์อัจฉริยะและ Vision NG",
      "features.f2.desc":
        "VisionSensor ตรวจสอบชิ้นงานดี/เสีย (OK/NG), RGB Sensor แยกสี, Photo Sensor ตรวจจับตำแหน่ง และม่านแสงนิรภัย Light Curtain",
      "features.f3.title": "ระบบ PLC คู่ (Ladder & Modbus)",
      "features.f3.desc":
        "รองรับ Internal Ladder PLC ในตัว (รูปแบบ IEC และ Mitsubishi FX3U) รวมถึง Modbus TCP Server/Client สำหรับเวอร์ชัน Desktop PC",
      "features.f4.title": "ตู้ควบคุม 3D/2D และไฟสัญญาณ",
      "features.f4.desc":
        "ตู้คอนโทรลพร้อมปุ่มกด สวิตช์เลือกโหมด ปุ่มฉุกเฉิน E-STOP ตัวปรับค่า Potentiometer มิเตอร์วัดค่า DPM และไฟ Stack Light 3 สี",
      "features.f5.title": "NPC โรงงานเดินตรวจอัตโนมัติ",
      "features.f5.desc":
        "ทีม NPC 5 บทบาท: Operator, Supervisor, Safety, Maintenance และ QC Inspector เดินหลบสิ่งกีดขวาง ตรวจสอบเครื่องจักร และตอบสนองต่อแจ้งเตือน",
      "features.f6.title": "รองรับทั้ง PC และ Mobile Touch",
      "features.f6.desc":
        "ควบคุมกล้องด้วยการสัมผัส 1 นิ้วหมุน/ลาก, 2 นิ้วถ่างซูมและเลื่อนฉาก พร้อมปุ่มกล้องลัดบนหน้าจอและ UI ที่ปรับขนาดอัตโนมัติ",

      "compare.eyebrow": "PLATFORM MATRIX",
      "compare.title": "เปรียบเทียบเวอร์ชัน Web กับ Desktop PC",
      "compare.colFeature": "ความสามารถ",
      "compare.colWeb": "Web Version (Browser)",
      "compare.colDesktop": "Desktop PC (Windows / Linux)",
      "compare.r1": "เล่นได้ทันทีไม่ต้องติดตั้ง (Instant Play)",
      "compare.r2": "Internal Ladder PLC (IEC / FX3U)",
      "compare.r3": "Modbus TCP Server/Client (External PLC / OpenPLC / FX3U)",
      "compare.r4": "บันทึกและโหลดโปรเจกต์ (.pksfac)",
      "compare.r5": "ระบบสัมผัสหน้าจอมือถือ (Mobile Touch Controls)",
      "compare.yes": "รองรับ",
      "compare.portable": "ดาวน์โหลดไฟล์พกพา",
      "compare.browserLimit": "ข้อจำกัดเบราว์เซอร์",
      "compare.fullSupport": "รองรับเต็มรูปแบบ",
      "compare.desktopInput": "เมาส์ & คีย์บอร์ด",

      "examples.eyebrow": "READY-TO-RUN SCENES",
      "examples.title": "โปรเจกต์ตัวอย่าง (.pksfac)",
      "examples.subtitle":
        "เปิดทดลองซีนตัวอย่างได้ในตัวจำลอง หรือดาวน์โหลดไฟล์ต้นฉบับจาก GitHub ไปศึกษาต่อ",
      "examples.e1.title": "สายพานคัดแยกชิ้นงาน Vision NG",
      "examples.e1.desc":
        "ใช้ VisionSensor ตรวจจับชิ้นงานเสีย ร่วมกับ DivertPusher เพื่อผลักชิ้นงานลง RejectBin โดยอัตโนมัติ",
      "examples.e2.title": "ระบบควบคุมระดับน้ำอัตโนมัติ",
      "examples.e2.desc":
        "จำลอง WaterTank พร้อมเซนเซอร์ระดับ L/M/H เชื่อมต่อ FeedPump, OutletValve และ CoolingFan ด้วยอินเตอร์ล็อก",
      "examples.e3.title": "สายพานคลังสินค้าเลี้ยว 90° และนิรภัย",
      "examples.e3.desc":
        "ไลน์ลำเลียง L-Turn 90 องศา พร้อมม่านแสงนิรภัย SafetyCurtain ตัดการทำงานฉุกเฉินเมื่อมีผู้ผ่านเข้าพื้นที่",
      "examples.openWeb": "เปิดใน Web Simulator",
      "examples.viewFile": "ดูไฟล์บน GitHub",

      "controls.eyebrow": "INPUT & NAVIGATION",
      "controls.title": "คู่มือการควบคุม",
      "controls.tabDesktop": "Desktop (Mouse & Keyboard)",
      "controls.tabMobile": "Mobile Touch",
      "controls.colAction": "คำสั่ง / การกระทำ",
      "controls.colInput": "ปุ่ม / การควบคุม",
      "controls.d1": "หมุนมุมกล้องรอบฉาก (Orbit)",
      "controls.d2": "เลื่อนมุมกล้อง (Pan)",
      "controls.d3": "ซูมเข้า / ออก (Zoom)",
      "controls.d4": "รีเซ็ตมุมกล้อง (Reset Camera)",
      "controls.d5": "เปิด / ปิดเต็มหน้าจอ (Fullscreen)",
      "controls.d6": "หมุนวัตถุ 90° (ในโหมด Edit)",
      "controls.d7": "ลบวัตถุที่เลือก (ในโหมด Edit)",
      "controls.d8": "ย้อนกลับ / ทำซ้ำ (Undo / Redo)",
      "controls.m1": "เลือกอุปกรณ์ หรือวางชิ้นส่วน",
      "controls.m1Input": "แตะ 1 ครั้ง (Tap)",
      "controls.m2": "หมุนมุมกล้อง / ลากย้ายวัตถุที่เลือกในโหมด Edit",
      "controls.m2Input": "ลาก 1 นิ้ว (1-finger Drag)",
      "controls.m3": "ซูมเข้า / ออก",
      "controls.m3Input": "จีบ / ถ่าง 2 นิ้ว (Pinch Zoom)",
      "controls.m4": "เลื่อนตำแหน่งกล้อง (Pan)",
      "controls.m4Input": "ลากพร้อมกัน 2 นิ้ว (2-finger Drag Pan)",
      "controls.m5": "แถบควบคุมกล้องด่วนบนหน้าจอ",

      "download.eyebrow": "GET PKS FACTORY SIMULATOR",
      "download.title": "เล่นออนไลน์หรือดาวน์โหลดลงเครื่อง PC",
      "download.subtitle":
        "เลือกใช้งานบนเว็บได้ทันที หรือดาวน์โหลดเวอร์ชัน Desktop เพื่อเชื่อมต่อ Modbus TCP เต็มรูปแบบ",
      "download.webDesc":
        "เล่นผ่าน WebGL ได้ทันที ไม่ต้องติดตั้ง รองรับ Internal Ladder PLC และระบบสัมผัสบนมือถือ",
      "download.webMeta": "WebAssembly • Instant Launch",
      "download.webCta": "เล่นบนเว็บ",
      "download.winDesc":
        "ประสิทธิภาพสูงสุดบน Desktop พร้อม Modbus TCP Server/Client สำหรับเชื่อมต่อ PLC จริงหรือ OpenPLC",
      "download.winCta": "ดาวน์โหลด Windows",
      "download.linuxDesc":
        "รันบน Linux 64-bit พร้อมรองรับ Modbus TCP Server/Client และการจำลองโรงงานเต็มรูปแบบ",
      "download.linuxCta": "ดาวน์โหลด Linux"
    },
    en: {
      "nav.features": "Features",
      "nav.web": "Live Web",
      "nav.examples": "Examples",
      "nav.controls": "Controls",
      "nav.download": "Download",
      "nav.playCta": "Play on Web",

      "hero.title": "3D Industrial Factory & PLC Automation Sandbox",
      "hero.subtitle":
        "Design 3D conveyor lines, wire smart sensors and actuators, program the built-in Internal Ladder PLC or external Modbus TCP, and watch autonomous factory NPCs in action on Web & PC.",
      "hero.ctaWeb": "Play on Web Now",
      "hero.ctaDownload": "Download PC (Windows / Linux)",

      "web.eyebrow": "LIVE WEBGL SANDBOX",
      "web.title": "Live Web Simulator Runner",
      "web.desc":
        "Click Launch to load the 3D WebAssembly engine on demand so the landing page stays ultra-fast.",
      "web.btnLaunch": "Launch / Start",
      "web.btnStop": "Stop",
      "web.btnFullscreen": "Fullscreen",
      "web.btnNewTab": "Open Full Tab",
      "web.placeholderTitle": "Ready to Launch 3D Factory Sandbox",
      "web.placeholderDesc":
        "Supports both Desktop mouse/keyboard and Mobile Touch controls directly in your browser.",
      "web.btnLaunchBig": "Launch Web Simulator",
      "web.note":
        "Note: The Web version runs Internal Ladder PLC and Manual modes on Desktop & Mobile browsers. For Modbus TCP Server/Client, use the PC (Windows / Linux) download below.",

      "features.eyebrow": "CAPABILITIES",
      "features.title": "Core Simulation Features",
      "features.subtitle":
        "Everything you need to learn, prototype, test PLC logic, and simulate automated production cells.",
      "features.f1.title": "3D Industrial Equipment",
      "features.f1.desc":
        "9m/3m Conveyors, 90° Turn Table, Box Emitter, Box Remover, Reject Bin, Pneumatic Pusher, Stopper, Pump, Water Tank, and Solenoid Valve.",
      "features.f2.title": "Smart Sensors & Vision NG Inspection",
      "features.f2.desc":
        "VisionSensor OK/NG defect inspection, RGB color sorting sensor, Photo Sensor detection, and Light Curtain safety interlock.",
      "features.f3.title": "Dual PLC Engine (Ladder & Modbus)",
      "features.f3.desc":
        "Built-in IEC / Mitsubishi FX3U Ladder PLC plus Desktop Modbus TCP Server/Client for connecting external controllers.",
      "features.f4.title": "3D/2D Control Cabinet & Stack Light",
      "features.f4.desc":
        "Interactive control panel with push buttons, selector switches, E-STOP, Potentiometer, DPM meter, and 3-color Stack Light.",
      "features.f5.title": "Autonomous Factory NPCs",
      "features.f5.desc":
        "Five factory roles — Operator, Supervisor, Safety, Maintenance, and QC Inspector — with obstacle avoidance and alert response.",
      "features.f6.title": "Desktop & Mobile Web Touch Ready",
      "features.f6.desc":
        "1-finger orbit/drag, 2-finger pinch-zoom and pan, quick on-screen camera controls, and a responsive interface.",

      "compare.eyebrow": "PLATFORM MATRIX",
      "compare.title": "Web vs Desktop PC Comparison",
      "compare.colFeature": "Capability",
      "compare.colWeb": "Web Version (Browser)",
      "compare.colDesktop": "Desktop PC (Windows / Linux)",
      "compare.r1": "Instant Play (No Install)",
      "compare.r2": "Internal Ladder PLC (IEC / FX3U)",
      "compare.r3": "Modbus TCP Server/Client (External PLC / OpenPLC / FX3U)",
      "compare.r4": ".pksfac Project Save / Load",
      "compare.r5": "Mobile Touch Controls",
      "compare.yes": "Supported",
      "compare.portable": "Portable Download",
      "compare.browserLimit": "Browser Sandbox Limit",
      "compare.fullSupport": "Full Support",
      "compare.desktopInput": "Mouse & Keyboard",

      "examples.eyebrow": "READY-TO-RUN SCENES",
      "examples.title": "Example Projects (.pksfac)",
      "examples.subtitle":
        "Launch pre-built factory scenarios in the simulator or inspect the project files on GitHub.",
      "examples.e1.title": "Vision NG Conveyor Sorting Line",
      "examples.e1.desc":
        "Uses VisionSensor defect detection paired with DivertPusher to automatically route NG boxes into RejectBin.",
      "examples.e2.title": "Water Tank Level Control",
      "examples.e2.desc":
        "Simulates a WaterTank with L/M/H level sensors interlocked with FeedPump, OutletValve, and CoolingFan.",
      "examples.e3.title": "90° L-Turn Warehouse Line",
      "examples.e3.desc":
        "90-degree L-Turn material handling line protected by a SafetyCurtain emergency interlock.",
      "examples.openWeb": "Open in Web Simulator",
      "examples.viewFile": "View on GitHub",

      "controls.eyebrow": "INPUT & NAVIGATION",
      "controls.title": "Controls Guide",
      "controls.tabDesktop": "Desktop (Mouse & Keyboard)",
      "controls.tabMobile": "Mobile Touch",
      "controls.colAction": "Action",
      "controls.colInput": "Input / Shortcut",
      "controls.d1": "Orbit Camera",
      "controls.d2": "Pan Camera",
      "controls.d3": "Zoom In / Out",
      "controls.d4": "Reset Camera",
      "controls.d5": "Toggle Fullscreen",
      "controls.d6": "Rotate Object 90° (Edit Mode)",
      "controls.d7": "Delete Selected Object (Edit Mode)",
      "controls.d8": "Undo / Redo (Edit Mode)",
      "controls.m1": "Select Equipment or Place Object",
      "controls.m1Input": "Single Tap",
      "controls.m2": "Orbit Camera / Move Selected in Edit Mode",
      "controls.m2Input": "1-finger Drag",
      "controls.m3": "Zoom In / Out",
      "controls.m3Input": "2-finger Pinch Zoom",
      "controls.m4": "Pan Camera",
      "controls.m4Input": "2-finger Drag Pan",
      "controls.m5": "On-screen Quick Camera Bar",

      "download.eyebrow": "GET PKS FACTORY SIMULATOR",
      "download.title": "Play Online or Download for PC",
      "download.subtitle":
        "Launch directly in your browser or grab the native Desktop build for full Modbus TCP support.",
      "download.webDesc":
        "Instant WebGL play with zero installation, supporting Internal Ladder PLC and Mobile Touch.",
      "download.webMeta": "WebAssembly • Instant Launch",
      "download.webCta": "Play on Web",
      "download.winDesc":
        "Full native Desktop performance with Modbus TCP Server/Client for real PLCs or OpenPLC.",
      "download.winCta": "Download Windows",
      "download.linuxDesc":
        "Native Linux 64-bit build with Modbus TCP Server/Client and complete factory simulation.",
      "download.linuxCta": "Download Linux"
    }
  };

  let currentLang = localStorage.getItem(STORAGE_KEY) || "th";
  if (currentLang !== "th" && currentLang !== "en") {
    currentLang = "th";
  }

  function applyLanguage(lang) {
    currentLang = lang;
    localStorage.setItem(STORAGE_KEY, lang);
    document.documentElement.lang = lang;

    const dict = TRANSLATIONS[lang];
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (key && Object.prototype.hasOwnProperty.call(dict, key)) {
        el.textContent = dict[key];
      }
    });

    const toggle = document.getElementById("langToggle");
    if (toggle) {
      toggle.textContent = lang === "th" ? "EN" : "TH";
      toggle.setAttribute(
        "aria-label",
        lang === "th" ? "Switch language to English" : "สลับภาษาเป็นภาษาไทย"
      );
    }
  }

  function setupNavigation() {
    const langToggle = document.getElementById("langToggle");
    if (langToggle) {
      langToggle.addEventListener("click", () => {
        applyLanguage(currentLang === "th" ? "en" : "th");
      });
    }

    const menuToggle = document.getElementById("menuToggle");
    const navMenu = document.getElementById("navMenu");
    if (menuToggle && navMenu) {
      menuToggle.addEventListener("click", () => {
        const isOpen = navMenu.classList.toggle("open");
        menuToggle.setAttribute("aria-expanded", String(isOpen));
      });

      navMenu.querySelectorAll("a").forEach((link) => {
        link.addEventListener("click", () => {
          navMenu.classList.remove("open");
          menuToggle.setAttribute("aria-expanded", "false");
        });
      });
    }
  }

  function setupControlTabs() {
    const tabButtons = document.querySelectorAll(".tab-btn[data-tab]");
    const panelDesktop = document.getElementById("panelDesktop");
    const panelMobile = document.getElementById("panelMobile");

    tabButtons.forEach((btn) => {
      btn.addEventListener("click", () => {
        const target = btn.getAttribute("data-tab");
        tabButtons.forEach((b) => {
          const active = b === btn;
          b.classList.toggle("active", active);
          b.setAttribute("aria-selected", String(active));
        });

        if (panelDesktop && panelMobile) {
          const showDesktop = target === "desktop";
          panelDesktop.classList.toggle("active", showDesktop);
          panelDesktop.hidden = !showDesktop;
          panelMobile.classList.toggle("active", !showDesktop);
          panelMobile.hidden = showDesktop;
        }
      });
    });
  }

  function setupWebRunner() {
    const stage = document.getElementById("webStage");
    const frame = document.getElementById("webPlayerFrame");
    const placeholder = document.getElementById("webPlaceholder");
    const launchBtn = document.getElementById("launchWebBtn");
    const launchHeroBtn = document.getElementById("launchWebHeroBtn");
    const stopBtn = document.getElementById("stopWebBtn");
    const fullscreenBtn = document.getElementById("fullscreenWebBtn");
    const statusDot = document.getElementById("webStatusDot");
    const statusText = document.getElementById("webStatusText");

    if (!stage || !frame || !placeholder) {
      return;
    }

    function isRunning() {
      return Boolean(document.getElementById("simIframe"));
    }

    function launchSimulator() {
      if (isRunning()) {
        return;
      }
      const iframe = document.createElement("iframe");
      iframe.id = "simIframe";
      iframe.src = "./play/";
      iframe.title = "PKS Factory Simulator WebGL";
      iframe.allow = "fullscreen; autoplay";
      iframe.setAttribute("allowfullscreen", "");

      placeholder.classList.add("hidden");
      stage.appendChild(iframe);

      if (stopBtn) stopBtn.classList.remove("hidden");
      if (launchBtn) launchBtn.classList.add("hidden");
      if (statusDot) statusDot.classList.add("running");
      if (statusText) statusText.textContent = "WebGL Running — ./play/";
    }

    function stopSimulator() {
      const iframe = document.getElementById("simIframe");
      if (iframe) {
        iframe.remove();
      }
      placeholder.classList.remove("hidden");
      if (stopBtn) stopBtn.classList.add("hidden");
      if (launchBtn) launchBtn.classList.remove("hidden");
      if (statusDot) statusDot.classList.remove("running");
      if (statusText) statusText.textContent = "WebGL Sandbox — ./play/";
    }

    if (launchBtn) launchBtn.addEventListener("click", launchSimulator);
    if (launchHeroBtn) launchHeroBtn.addEventListener("click", launchSimulator);
    if (stopBtn) stopBtn.addEventListener("click", stopSimulator);

    if (fullscreenBtn) {
      fullscreenBtn.addEventListener("click", () => {
        if (!isRunning()) {
          launchSimulator();
        }
        if (document.fullscreenElement) {
          document.exitFullscreen().catch(() => {});
        } else if (frame.requestFullscreen) {
          frame.requestFullscreen().catch(() => {});
        }
      });
    }
  }

  function formatSizeMB(bytes) {
    if (!Number.isFinite(bytes) || bytes <= 0) {
      return "";
    }
    const mb = bytes / (1024 * 1024);
    return `${mb.toFixed(1)} MB`;
  }

  async function fetchLatestRelease() {
    const winBtn = document.getElementById("dlWindowsBtn");
    const winMeta = document.getElementById("dlWindowsMeta");
    const linuxBtn = document.getElementById("dlLinuxBtn");
    const linuxMeta = document.getElementById("dlLinuxMeta");

    if (!winBtn || !linuxBtn) {
      return;
    }

    try {
      const response = await fetch(RELEASE_API, {
        headers: { Accept: "application/vnd.github+json" }
      });
      if (!response.ok) {
        return;
      }

      const data = await response.json();
      const assets = Array.isArray(data.assets) ? data.assets : [];
      const tag = data.tag_name || "";

      const winAsset = assets.find((asset) => {
        const name = (asset.name || "").toLowerCase();
        return name.includes("win") || name.includes("windows") || name.endsWith(".exe");
      });

      const linuxAsset = assets.find((asset) => {
        const name = (asset.name || "").toLowerCase();
        return (
          name.includes("linux") ||
          name.endsWith(".x86_64") ||
          name.endsWith(".appimage") ||
          name.endsWith(".tar.gz")
        );
      });

      if (winAsset && winAsset.browser_download_url) {
        winBtn.href = winAsset.browser_download_url;
        if (winMeta) {
          const size = formatSizeMB(winAsset.size);
          winMeta.textContent = [tag, winAsset.name, size].filter(Boolean).join(" • ");
        }
      }

      if (linuxAsset && linuxAsset.browser_download_url) {
        linuxBtn.href = linuxAsset.browser_download_url;
        if (linuxMeta) {
          const size = formatSizeMB(linuxAsset.size);
          linuxMeta.textContent = [tag, linuxAsset.name, size].filter(Boolean).join(" • ");
        }
      }
    } catch (_err) {
      // Silently keep default GitHub Releases fallback links
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    applyLanguage(currentLang);
    setupNavigation();
    setupControlTabs();
    setupWebRunner();
    fetchLatestRelease();
  });
})();
