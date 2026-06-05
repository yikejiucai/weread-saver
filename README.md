# WeReadScreenSaver

macOS 极简封面墙屏保原型。

## What it does

- 全屏展示微信读书书架封面墙
- 直接读取 Chrome 里已登录的微信读书页面
- 默认会在读不到浏览器数据时回退到本地样例数据
- 预留本地缓存位，避免临时离线时空白
- 数据层统一为 `ShelfItem`

## Run

> 需要 macOS 和 Swift 工具链。

```bash
cd <repo-root>
swift run
```

## Build saver bundle

```bash
cd <repo-root>
bash scripts/package-saver.sh
```

安装到系统屏保目录：

```bash
bash scripts/install-saver.sh
```

## Chrome login bridge

应用会直接通过 AppleScript 读取 Chrome 前台窗口里已登录的微信读书页面，并从页面 DOM 提取书架封面、书名和作者。  
如果读不到浏览器内容，会回退到缓存文件：

`~/Library/Application Support/WeReadScreenSaver/shelf-cache.json`

格式使用 `ShelfPayload`，示例：

```json
{
  "source": "Chrome Bridge",
  "fetchedAt": "2026-06-05T10:00:00Z",
  "items": []
}
```

如果 Chrome 没打开微信读书页面，或者 Apple Events / Chrome 的脚本权限未放行，应用会回退到本地样例数据。
