import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class UpdateHttpServer {
  HttpServer? _server;
  final _router = Router();
  String? _lastReceivedContent;
  bool _contentReady = false;

  Future<String> start({int port = 18888}) async {
    _router.post('/upload', _handleUpload);
    _router.get('/status', _handleStatus);
    _router.get('/', _handlePage);
    _router.options('/upload', _handleOptions);
    _server = await shelf_io.serve(_router.call, InternetAddress.anyIPv4, port);
    return 'http://${await _getLocalIp()}:${_server!.port}';
  }

  Future<void> stop() async { await _server?.close(force: true); _server = null; }

  Future<String?> waitForContent({Duration timeout = const Duration(minutes: 5)}) async {
    final deadline = DateTime.now().add(timeout);
    while (!_contentReady && DateTime.now().isBefore(deadline)) { await Future.delayed(const Duration(milliseconds: 500)); }
    _contentReady = false;
    return _lastReceivedContent;
  }

  Future<Response> _handleUpload(Request request) async {
    try {
      _lastReceivedContent = await request.readAsString();
      _contentReady = true;
      return Response.ok('{"status":"ok"}', headers: {..._corsHeaders, 'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: '{"status":"error"}', headers: {..._corsHeaders, 'Content-Type': 'application/json'});
    }
  }

  Response _handleStatus(Request request) {
    return Response.ok('{"ready":$_contentReady}', headers: {..._corsHeaders, 'Content-Type': 'application/json'});
  }

  Response _handlePage(Request request) {
    return Response.ok(_uploadPage, headers: {'Content-Type': 'text/html; charset=utf-8', 'Access-Control-Allow-Origin': '*'});
  }

  Response _handleOptions(Request request) {
    return Response.ok('', headers: _corsHeaders);
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list();
    for (final i in interfaces) {
      for (final a in i.addresses) { if (a.type == InternetAddressType.IPv4 && !a.isLoopback) return a.address; }
    }
    return '192.168.1.1';
  }

  static const _corsHeaders = {'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS', 'Access-Control-Allow-Headers': 'Content-Type'};
  static const _uploadPage = '<!DOCTYPE html>\n<html lang="zh-CN">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n<title>更新信号源 - 想看就看</title>\n<style>\n* { box-sizing: border-box; margin: 0; padding: 0; }\nbody { font-family: -apple-system, sans-serif; background: #0a0a0a; color: #eee; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 20px; }\n.container { max-width: 480px; width: 100%; }\nh1 { font-size: 24px; text-align: center; margin-bottom: 8px; }\n.sub { text-align: center; color: #888; font-size: 14px; margin-bottom: 24px; }\n.section { background: #1a1a1a; border-radius: 8px; padding: 20px; margin-bottom: 16px; }\n.section h2 { font-size: 16px; margin-bottom: 12px; color: #ccc; }\ntextarea { width: 100%; min-height: 120px; background: #111; border: 1px solid #333; border-radius: 6px; padding: 12px; color: #0f0; font-family: monospace; font-size: 13px; resize: vertical; }\ninput[type=text] { width: 100%; background: #111; border: 1px solid #333; border-radius: 6px; padding: 12px; color: #eee; font-size: 14px; margin-bottom: 12px; }\nbutton { width: 100%; padding: 14px; background: #e53935; color: white; border: none; border-radius: 6px; font-size: 16px; font-weight: 600; cursor: pointer; }\nbutton:active { background: #c62828; }\n.status { text-align: center; margin-top: 12px; font-size: 14px; }\n.status.success { color: #4caf50; }\n.status.error { color: #f44336; }\n</style>\n</head>\n<body>\n<div class="container">\n<h1>想看就看</h1>\n<p class="sub">信号源更新</p>\n<div class="section"><h2>粘贴 M3U 链接</h2><input type="text" id="urlInput" placeholder="https://example.com/tv.m3u"></div>\n<div class="section"><h2>直接粘贴 M3U 内容</h2><textarea id="contentInput" placeholder="#EXTM3U&#10;#EXTINF:-1,CCTV-1&#10;http://..."></textarea></div>\n<button onclick="submitUpdate()">更新信号源</button>\n<div id="status" class="status"></div>\n</div>\n<script>\nasync function submitUpdate(){const u=document.getElementById("urlInput").value.trim(),c=document.getElementById("contentInput").value.trim(),s=document.getElementById("status");if(!u&&!c){s.className="status error";s.textContent="请填入M3U链接或粘贴M3U内容";return}s.textContent="正在上传...";s.className="status";try{const b=u||c,r=await fetch("/upload",{method:"POST",headers:{"Content-Type":"text/plain; charset=utf-8"},body:b}),j=await r.json();if(j.status==="ok"){s.className="status success";s.textContent="信号源已更新!电视正在刷新频道列表..."}else{s.className="status error";s.textContent="更新失败:"+j.message}}catch(e){s.className="status error";s.textContent="连接失败:"+e.message}}\n</script>\n</body></html>';
}
