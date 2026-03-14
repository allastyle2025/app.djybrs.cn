# SSE 实时通知系统 API 接口文档

## 基础信息

- **基础URL**: `http://your-domain/api/notifications`
- **协议**: HTTP/HTTPS
- **技术**: Server-Sent Events (SSE)

---

## 技术概述

### 什么是 SSE (Server-Sent Events)

SSE 是一种服务器向客户端推送数据的技术，相比 WebSocket 更轻量级，适用于服务器主动向客户端推送消息的场景。

### 主要特点

1. **单向通信**: 服务器向客户端推送数据
2. **自动重连**: 浏览器原生支持断线重连
3. **简单易用**: 基于 HTTP 协议，无需额外协议
4. **轻量级**: 相比 WebSocket 实现更简单

---

## 数据模型

### NotificationData 通知数据对象

| 字段名 | 类型 | 说明 |
|--------|------|------|
| type | String | 通知类型（volunteer_application, room_checkin） |
| title | String | 通知标题 |
| message | String | 通知消息内容 |
| applicationId | Long | 义工申请ID（义工申请通知） |
| checkInId | Long | 入住登记ID（入住登记通知） |
| timestamp | long | 时间戳（毫秒） |

---

## API 接口列表

### 1. 建立 SSE 连接

**请求**
- **Method**: GET
- **URL**: `/api/notifications/subscribe`
- **Content-Type**: `text/event-stream`

**说明**: 前端使用 EventSource 连接此接口，建立实时通知连接。

**响应事件格式**

```
event: connect
data: 连接成功

event: notification
data: 消息内容

event: volunteer_application
data: {"type":"volunteer_application","title":"新的义工申请","message":"申请人: 张三","applicationId":123,"timestamp":1700000000000}

event: room_checkin
data: {"type":"room_checkin","title":"新的入住登记","message":"入住人: 李四","checkInId":456,"timestamp":1700000000000}
```

**前端使用示例**

```javascript
// 创建 SSE 连接
const eventSource = new EventSource('http://your-domain/api/notifications/subscribe');

// 监听连接成功事件
eventSource.addEventListener('connect', (event) => {
  console.log('SSE 连接成功:', event.data);
});

// 监听普通通知事件
eventSource.addEventListener('notification', (event) => {
  console.log('收到通知:', event.data);
});

// 监听义工申请通知
eventSource.addEventListener('volunteer_application', (event) => {
  const data = JSON.parse(event.data);
  console.log('义工申请:', data.title, data.message);
});

// 监听入住登记通知
eventSource.addEventListener('room_checkin', (event) => {
  const data = JSON.parse(event.data);
  console.log('入住登记:', data.title, data.message);
});

// 监听错误事件
eventSource.onerror = (error) => {
  console.error('SSE 连接错误:', error);
};

// 关闭连接
// eventSource.close();
```

**React Hooks 使用示例**

```jsx
import { useEffect, useState } from 'react';

function useSSE(url) {
  const [notifications, setNotifications] = useState([]);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const eventSource = new EventSource(url);

    eventSource.addEventListener('connect', () => {
      setConnected(true);
    });

    eventSource.addEventListener('notification', (event) => {
      setNotifications(prev => [...prev, {
        type: 'notification',
        message: event.data,
        timestamp: Date.now()
      }]);
    });

    eventSource.addEventListener('volunteer_application', (event) => {
      const data = JSON.parse(event.data);
      setNotifications(prev => [...prev, {
        type: 'volunteer_application',
        data: data,
        timestamp: Date.now()
      }]);
    });

    eventSource.addEventListener('room_checkin', (event) => {
      const data = JSON.parse(event.data);
      setNotifications(prev => [...prev, {
        type: 'room_checkin',
        data: data,
        timestamp: Date.now()
      }]);
    });

    eventSource.onerror = () => {
      setConnected(false);
    };

    return () => {
      eventSource.close();
    };
  }, [url]);

  return { notifications, connected };
}

// 使用示例
function AdminDashboard() {
  const { notifications, connected } = useSSE('/api/notifications/subscribe');

  return (
    <div>
      <div>连接状态: {connected ? '已连接' : '未连接'}</div>
      <ul>
        {notifications.map((n, i) => (
          <li key={i}>{n.data?.title || n.message}</li>
        ))}
      </ul>
    </div>
  );
}
```

---

### 2. 获取当前连接数

**请求**
- **Method**: GET
- **URL**: `/api/notifications/connection-count`

**说明**: 获取当前 SSE 连接的客户端数量，用于调试和监控。

**响应示例**

```json
{
  "code": 200,
  "message": "success",
  "data": 5
}
```

---

### 3. 发送测试通知

**请求**
- **Method**: POST
- **URL**: `/api/notifications/test`

**查询参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| message | String | 是 | 测试消息内容 |

**请求示例**

```
POST /api/notifications/test?message=这是一条测试通知
```

**响应示例**

```json
{
  "code": 200,
  "message": "success",
  "data": "通知已发送"
}
```

---

## 服务端实现

### NotificationService 核心方法

| 方法名 | 参数 | 说明 |
|--------|------|------|
| subscribe() | 无 | 建立 SSE 连接，返回 SseEmitter |
| sendNotification(message) | message: String | 发送普通通知给所有客户端 |
| sendNotificationWithData(eventName, message, data) | eventName: String, message: String, data: Object | 发送带数据的通知 |
| notifyNewVolunteerApplication(applicationId, applicantName) | applicationId: Long, applicantName: String | 发送义工申请通知 |
| notifyNewRoomCheckIn(checkInId, guestName) | checkInId: Long, guestName: String | 发送入住登记通知 |
| getConnectionCount() | 无 | 获取当前连接数 |

### 使用示例（在业务代码中调用）

```java
@Service
@RequiredArgsConstructor
public class VolunteerApplicationService {
    
    private final NotificationService notificationService;
    
    public void submitApplication(VolunteerApplication application) {
        // 保存申请...
        
        // 发送通知
        notificationService.notifyNewVolunteerApplication(
            application.getId(), 
            application.getName()
        );
    }
}
```

```java
@Service
@RequiredArgsConstructor
public class RoomCheckInService {
    
    private final NotificationService notificationService;
    
    public RoomCheckIn checkIn(RoomCheckIn checkIn, String idCard) {
        // 办理入住...
        
        // 发送通知
        notificationService.notifyNewRoomCheckIn(
            checkIn.getId(), 
            checkIn.getCname()
        );
        
        return checkIn;
    }
}
```

---

## 连接管理

### 连接生命周期

1. **建立连接**: 客户端调用 `/subscribe` 接口
2. **保持连接**: 服务器保持长连接，等待事件
3. **发送消息**: 服务器主动推送消息
4. **断开连接**: 客户端断开或超时

### 连接超时设置

```java
// 超时时间设置为0表示不超时
SseEmitter emitter = new SseEmitter(0L);

// 或者设置30分钟超时
SseEmitter emitter = new SseEmitter(30 * 60 * 1000L);
```

### 断线重连

浏览器原生支持断线重连，无需额外处理。当连接断开时，浏览器会自动尝试重新连接。

---

## 注意事项

1. **跨域问题**: 确保 CORS 配置正确，允许跨域请求
2. **连接数限制**: 注意服务器最大连接数限制
3. **内存管理**: 及时清理断开的连接，避免内存泄漏
4. **浏览器兼容**: SSE 不支持 IE 浏览器，需要使用 polyfill 或 WebSocket 替代
5. **代理配置**: 如果使用 Nginx 等代理，需要配置缓冲区禁用

### Nginx 配置示例

```nginx
location /api/notifications/subscribe {
    proxy_pass http://backend;
    proxy_http_version 1.1;
    proxy_set_header Connection '';
    proxy_buffering off;
    proxy_cache off;
    proxy_read_timeout 86400s;
}
```

---

## 浏览器兼容性

| 浏览器 | 支持情况 |
|--------|----------|
| Chrome | 完全支持 |
| Firefox | 完全支持 |
| Safari | 完全支持 |
| Edge | 完全支持 |
| IE | 不支持 |

---

## 错误处理

### 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 连接超时 | 网络问题或服务器超时 | 检查网络，调整超时时间 |
| 连接失败 | CORS 问题 | 配置 CORS 允许跨域 |
| 消息丢失 | 连接断开 | 实现消息确认机制 |

### 错误日志

```
SSE 客户端连接: client_1, 当前连接数: 1
SSE 客户端错误: client_1, 错误: Connection reset by peer
SSE 客户端完成: client_1, 当前连接数: 0
```

---

## 性能优化

1. **连接池管理**: 使用 ConcurrentHashMap 管理连接
2. **异步发送**: 使用异步方式发送消息
3. **消息压缩**: 对大数据进行压缩
4. **心跳检测**: 定期发送心跳消息保持连接

---

## 更新日志

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2025-03-14 | 初始版本，支持义工申请和入住登记通知 |
