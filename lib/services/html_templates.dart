// Javier: Este archivo contiene la plantilla HTML maestra del StreamDeck.
// Excepcionalmente supera las 300 líneas porque es un bloque de texto gigante HTML.

String buildMasterOverlayHtml(
  Map<String, String> customLayers, {
  String subTitle = 'COMENZANDO PRONTO',
  String poweredBy = 'DIRECTO GESTIONADO POR APLIARTETTS',
}) {
  final customIframes = customLayers.entries.map((e) {
    return '<iframe id="layer-${e.key}" class="layer" src="${e.value}"></iframe>';
  }).join('\\n');

  return '''<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ApliArteTts - Master Overlay</title>
    <style>
        /* =========================================
           VARIABLES Y RESET (ApliArte)
           ========================================= */
        :root {
            --color-primary: #5bc0f8;
            --color-secondary: #1565c0;
            --color-bg-dark: #050510;
            --glass-bg: rgba(10, 10, 25, 0.6);
            --glass-border: rgba(255, 255, 255, 0.1);
            --transition-speed: 0.8s;
        }

        * {
            margin: 0; padding: 0; box-sizing: border-box;
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
        }

        body {
            width: 1920px; height: 1080px;
            overflow: hidden;
            background-color: transparent; /* Transparente para OBS */
            color: white;
            position: relative;
        }

        /* ── Capas genéricas de alertas ──────────────── */
        .layer {
            position: absolute; top: 0; left: 0;
            width: 1920px; height: 1080px;
            border: none;
            transition: opacity 0.5s ease;
            pointer-events: auto;
            z-index: 1000; /* Alertas siempre muy arriba */
        }
        .layer.hidden { opacity: 0; pointer-events: none; }

        /* ── Chat TTS bubbles ─────────────────────────────── */
        #chat-wrap {
            position: absolute; bottom: 24px; left: 24px;
            width: 580px; display: flex; flex-direction: column; gap: 8px;
            pointer-events: none; z-index: 9999;
            transition: opacity 0.5s ease;
        }
        #chat-wrap.hidden { opacity: 0; }
        .msg {
            background: rgba(0,0,0,0.80);
            border-left: 4px solid #9147ff; border-radius: 10px;
            padding: 9px 14px; color: #fff;
            animation: fadeIn 0.3s ease; backdrop-filter: blur(6px);
        }
        .msg.out { animation: fadeOut 0.35s ease forwards; }
        .user {
            font-weight: 700; font-size: 0.78em; color: #bf94ff;
            text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 3px;
        }
        .text { font-size: 1.05em; line-height: 1.4; }
        .original { font-size: 0.72em; color: rgba(255,255,255,0.42); margin-top: 3px; font-style: italic; }
        @keyframes fadeIn { from { opacity:0; transform:translateY(12px); } to { opacity:1; transform:translateY(0); } }
        @keyframes fadeOut { from { opacity:1; } to { opacity:0; transform:translateY(-8px); } }

        /* =========================================
           FONDO DINÁMICO DE TUS DISEÑOS
           ========================================= */
        .background-layer {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: radial-gradient(circle at 50% 50%, #1a1a2e 0%, var(--color-bg-dark) 100%);
            z-index: -2;
            transition: opacity var(--transition-speed) ease;
        }
        .ambient-light {
            position: absolute; border-radius: 50%; filter: blur(100px);
            opacity: 0.4; animation: float 10s infinite alternate ease-in-out;
            z-index: -1; transition: all var(--transition-speed) ease;
        }
        .light-1 { top: -10%; left: -10%; width: 600px; height: 600px; background: var(--color-primary); }
        .light-2 { bottom: -10%; right: -10%; width: 800px; height: 800px; background: var(--color-secondary); animation-delay: -5s; }
        @keyframes float { 0% { transform: translate(0, 0) scale(1); } 100% { transform: translate(50px, 50px) scale(1.1); } }

        .glass-panel {
            background: var(--glass-bg); backdrop-filter: blur(12px);
            border: 1px solid var(--glass-border); border-radius: 16px;
            box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.5);
            position: absolute; transition: all var(--transition-speed) cubic-bezier(0.25, 1, 0.5, 1);
        }
        
        .cam-frame {
            position: absolute; border-radius: 16px;
            border: 2px solid var(--color-primary);
            box-shadow: 0 0 20px rgba(0, 240, 255, 0.2), inset 0 0 10px rgba(0, 240, 255, 0.1);
        }

        /* 🟢 EL TRUCO MAGNÍFICO: PERFORAR EL FONDO HASTA OBS */
        .cam-frame::after, .dev-screen::after {
            content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0;
            background: black; border-radius: 14px;
            mix-blend-mode: destination-out;
            z-index: -1;
        }

        .logo-text {
            font-weight: 900; text-transform: uppercase; letter-spacing: 4px;
            background: linear-gradient(45deg, var(--color-primary), var(--color-secondary));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            text-shadow: 0 0 20px rgba(0, 240, 255, 0.2);
        }

        /* ── ESCENAS AISLADAS (CADA UNA TIENE SU FONDO) ────────────────────────────────── */
        .scene {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: radial-gradient(circle at 50% 50%, #1a1a2e 0%, var(--color-bg-dark) 100%);
            opacity: 0; pointer-events: none; transition: opacity var(--transition-speed) ease;
            isolation: isolate; overflow: hidden;
        }
        .scene.active { opacity: 1; pointer-events: auto; }

        /* Luces de ambiente integradas en la escena */
        .scene::before, .scene::after {
            content: ''; position: absolute; border-radius: 50%; filter: blur(100px);
            opacity: 0.4; animation: float 10s infinite alternate ease-in-out;
            z-index: -2; pointer-events: none;
        }
        .scene::before { top: -10%; left: -10%; width: 600px; height: 600px; background: var(--color-primary); }
        .scene::after { bottom: -10%; right: -10%; width: 800px; height: 800px; background: var(--color-secondary); animation-delay: -5s; }
        @keyframes float { 0% { transform: translate(0, 0) scale(1); } 100% { transform: translate(50px, 50px) scale(1.1); } }

        /* INICIO */
        #scene-start { display: flex; flex-direction: column; justify-content: center; align-items: center; }
        #scene-start .main-logo { font-size: 120px; margin-bottom: 20px; animation: pulse 3s infinite alternate; }
        #scene-start .subtitle { font-size: 32px; font-weight: 300; letter-spacing: 10px; color: rgba(255,255,255,0.8); text-transform: uppercase; }
        #countdown {
            font-size: 80px; font-weight: bold; font-family: monospace; margin-top: 20px;
            background: linear-gradient(45deg, var(--color-primary), var(--color-secondary));
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            text-shadow: 0 0 20px rgba(91, 192, 248, 0.3);
        }
        .social-inicio { display: flex; gap: 40px; margin-top: 40px; font-size: 24px; font-weight: bold; letter-spacing: 2px; }
        .powered-by { position: absolute; bottom: 40px; font-size: 18px; color: rgba(255,255,255,0.5); font-style: italic; letter-spacing: 2px; text-transform: uppercase; }

        /* CHARLA */
        .chatting-cam { top: 50px; left: 50px; width: 1350px; height: 760px; }
        .chatting-chatbox { top: 50px; right: 50px; width: 420px; height: 980px; display: flex; flex-direction: column; padding: 20px; }
        .chatting-bottom { bottom: 50px; left: 50px; width: 1350px; height: 170px; display: flex; align-items: center; padding: 0 40px; justify-content: space-between; }

        /* JUEGO */
        .gaming-cam { bottom: 40px; right: 40px; width: 320px; height: 180px; }
        .gaming-topbar {
            top: 0; left: 50%; transform: translateX(-50%); width: 800px; height: 50px;
            border-top-left-radius: 0; border-top-right-radius: 0;
            display: flex; justify-content: space-around; align-items: center; font-size: 14px; font-weight: bold;
        }

        /* BRB */
        #scene-brb { display: flex; flex-direction: column; justify-content: center; align-items: center; }
        #scene-brb .brb-text { font-size: 80px; margin-bottom: 20px; }
        .loader { width: 200px; height: 4px; background: rgba(255,255,255,0.1); position: relative; overflow: hidden; border-radius: 2px; }
        .loader::after {
            content: ''; position: absolute; top: 0; left: 0; height: 100%; width: 50%;
            background: var(--color-secondary); animation: load 1.5s infinite ease-in-out alternate;
        }
        @keyframes load { 0% { transform: translateX(-100%); } 100% { transform: translateX(200%); } }
        @keyframes pulse { 0% { filter: drop-shadow(0 0 10px rgba(0,240,255,0.2)); transform: scale(0.98); } 100% { filter: drop-shadow(0 0 30px rgba(0,240,255,0.6)); transform: scale(1.02); } }

        /* DEV */
        .dev-screen { top: 40px; left: 40px; width: 1460px; height: 820px; border: 2px solid var(--color-primary); box-shadow: 0 0 20px rgba(91, 192, 248, 0.2); position: absolute; border-radius: 12px; }
        .dev-cam { top: 40px; right: 40px; width: 340px; height: 191px; }
        .dev-chat { top: 250px; right: 40px; width: 340px; height: 790px; display: flex; flex-direction: column; padding: 15px; }
        .dev-info { bottom: 40px; left: 40px; width: 1460px; height: 160px; display: flex; align-items: center; justify-content: space-between; padding: 0 50px; }
        .dev-badge {
            background: rgba(21, 101, 192, 0.8); border: 1px solid var(--color-primary);
            padding: 10px 25px; border-radius: 30px; font-size: 22px; font-weight: bold;
            display: flex; align-items: center; gap: 10px; color: #fff; box-shadow: 0 0 15px rgba(91,192,248,0.2);
        }
        .placeholder-text { color: rgba(255,255,255,0.5); text-align: center; width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-style: italic; }
        .social-bar { display: flex; gap: 20px; }
        .social-item { display: flex; align-items: center; gap: 8px; font-size: 18px; }
        .social-icon { color: var(--color-primary); font-weight: bold; }
    </style>
</head>
<body>

    <!-- ESCENA 1: INICIO -->
    <div id="scene-start" class="scene active">
        <div class="logo-text main-logo">APLIARTE</div>
        <div id="streamSubtitle" class="subtitle">\${subTitle}</div>
        <div id="countdown">03:00</div>
        
        <div class="social-inicio">
            <div class="social-item"><span class="social-icon" style="color: #FF0000;">▶</span> YOUTUBE: APLIARTE</div>
            <div class="social-item"><span class="social-icon" style="color: var(--color-secondary);">★</span> STREAMELEMENTS</div>
        </div>

        <div class="powered-by">\${poweredBy}</div>
    </div>

    <!-- ESCENA 2: CHARLA -->
    <div id="scene-chat" class="scene">
        <!-- MARCO TOTALMENTE TRANSPARENTE EN EL CENTRO -->
        <div class="cam-frame chatting-cam"></div>
        <!-- CAJAS TIPO CRISTAL EN LOS BORDES -->
        <div class="glass-panel chatting-chatbox">
            <h3 style="text-align: center; margin-bottom: 15px; color: var(--color-primary);">CHAT EN VIVO</h3>
            <div class="placeholder-text">Chat de OBS</div>
        </div>
        <div class="glass-panel chatting-bottom">
            <div class="logo-text" style="font-size: 40px;">APLIARTE.COM</div>
            <div class="social-bar">
                <div class="social-item"><span class="social-icon">▶</span> Último Suscriptor: -</div>
                <div class="social-item"><span class="social-icon">♥</span> Último Seguidor: -</div>
            </div>
        </div>
    </div>

    <!-- ESCENA 3: JUEGO -->
    <div id="scene-game" class="scene">
        <div class="glass-panel gaming-topbar">
            <span style="color: var(--color-primary)">ÚLTIMO SEGUIDOR: -</span>
            <span>|</span>
            <span style="color: var(--color-secondary)">TOP DONACIÓN: -</span>
        </div>
        <!-- MARCO TRANSPARENTE PARA LA CÁMARA JUEGO -->
        <div class="cam-frame gaming-cam"></div>
    </div>

    <!-- ESCENA 4: VUELVO ENSEGUIDA (BRB) -->
    <div id="scene-brb" class="scene">
        <div class="logo-text brb-text">EN SEGUIDA Vuelvo</div>
        <div class="loader"></div>
        <div class="powered-by">DIRECTO GESTIONADO POR APLIARTETTS</div>
    </div>

    <!-- ESCENA 5: DESARROLLO -->
    <div id="scene-dev" class="scene">
        <div class="dev-screen"></div>
        <!-- MARCO DE CÁMARA TRANSPARENTE -->
        <div class="cam-frame dev-cam"></div>
        <div class="glass-panel dev-chat">
            <h3 style="text-align: center; margin-bottom: 15px; color: var(--color-primary);">CHAT</h3>
            <div class="placeholder-text" style="font-size: 14px;">Chat OBS</div>
        </div>
        <div class="glass-panel dev-info">
            <div class="dev-badge">👨‍💻 MODO DESARROLLADOR</div>
            <div class="logo-text" style="font-size:30px;">TTS APLIARTE ENABLED</div>
        </div>
    </div>

    <!-- ── CAPAS IFRAME DINÁMICAS (Configuradas por el usuario) ── -->
    $customIframes
    
    <div id="chat-wrap"></div>

    <!-- ── LÓGICA WEBSOCKET APLIARTETTS ── -->
    <script>
        // -- Escenas --
        function switchScene(sceneId) {
            document.querySelectorAll('.scene').forEach(el => el.classList.remove('active'));
            var target = document.getElementById(sceneId);
            if (target) target.classList.add('active');
        }

        // -- Temporizador --
        let timerInterval;
        function setTimer(minutes) {
            clearInterval(timerInterval);
            let timer = minutes * 60;
            const display = document.getElementById('countdown');
            display.textContent = '0' + minutes + ':00';
            timerInterval = setInterval(function () {
                timer--;
                if (timer < 0) return;
                let mins = parseInt(timer / 60, 10);
                let secs = parseInt(timer % 60, 10);
                mins = mins < 10 ? "0" + mins : mins;
                secs = secs < 10 ? "0" + secs : secs;
                display.textContent = mins + ":" + secs;
                if (timer <= 0) {
                    clearInterval(timerInterval);
                    display.textContent = "¡VAMOS A JUGAR!";
                }
            }, 1000);
        }

        // -- Chat TTS --
        var MAX = 4, DURATION = 8000;
        var chat = document.getElementById('chat-wrap');

        function setLayer(id, visible) {
            var el = document.getElementById('layer-' + id) || (id === 'chat' ? chat : null);
            if (!el) return;
            if (visible) el.classList.remove('hidden');
            else el.classList.add('hidden');
        }

        function showMsg(d) {
            var div = document.createElement('div');
            div.className = 'msg';
            var showOrig = d.original && d.original !== d.text;
            div.innerHTML = '<div class="user">' + esc(d.user) + '</div>' +
                '<div class="text">' + esc(d.text) + '</div>' +
                (showOrig ? '<div class="original">' + esc(d.original) + '</div>' : '');
            chat.appendChild(div);
            var msgs = chat.querySelectorAll('.msg:not(.out)');
            if (msgs.length > MAX) {
                msgs[0].classList.add('out');
                (function(el) { setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, 350); })(msgs[0]);
            }
            setTimeout(function() {
                div.classList.add('out');
                setTimeout(function() { if (div.parentNode) div.parentNode.removeChild(div); }, 350);
            }, DURATION);
        }

        function esc(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }

        function updateStreamInfo(d) {
            var elSub = document.getElementById('streamSubtitle');
            if(elSub && d.subtitle) elSub.textContent = d.subtitle;
            
            // This expects ALL .powered-by to change.
            document.querySelectorAll('.powered-by').forEach(e => {
                if(d.poweredBy) e.textContent = d.poweredBy;
            });
        }

        // -- WebSocket --
        function connect() {
            var ws = new WebSocket('ws://' + location.host + '/ws');
            ws.onmessage = function(e) {
                try {
                    var d = JSON.parse(e.data);
                    // Ocultar capa genérica
                    if (d.type === 'scene') setLayer(d.scene, d.visible);
                    else if (d.type === 'message') showMsg(d);
                    else if (d.type === 'stream_scene') switchScene(d.scene);
                    else if (d.type === 'timer') setTimer(d.minutes);
                    else if (d.type === 'stream_info') updateStreamInfo(d);
                } catch(x) {}
            };
            ws.onclose = function() { setTimeout(connect, 3000); };
        }

        connect();
        
        // Arranca con la escena de 3 minutos
        setTimer(3);
    </script>
</body>
</html>''';
}
