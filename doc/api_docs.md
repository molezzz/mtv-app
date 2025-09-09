# MoonTV API 文档

这是对 MoonTV 项目后端 API 的说明文档。所有 API 都需要通过 Cookie 进行身份认证。

## 认证 (Authentication)

### 1. 登录
- **Endpoint**: `POST /api/login`
- **描述**: 用户登录。根据部署模式（localstorage 或数据库），验证密码或用户名/密码。成功后返回一个 httpOnly 的 `auth` cookie。
- **请求体**:
  ```json
  {
    "username": "user1", // 数据库模式需要
    "password": "your_password"
  }
  ```

### 2. 注册
- **Endpoint**: `POST /api/register`
- **描述**: 用户注册。仅在数据库模式且后台允许注册时可用。
- **请求体**:
  ```json
  {
    "username": "new_user",
    "password": "your_password"
  }
  ```

### 3. 登出
- **Endpoint**: `POST /api/logout`
- **描述**: 清除认证 cookie，实现用户登出。
- **请求体**: (无)

### 4. 修改密码
- **Endpoint**: `POST /api/change-password`
- **描述**: 已登录的普通用户修改自己的密码。站长无法通过此接口修改密码。
- **请求体**:
  ```json
  {
    "newPassword": "new_secure_password"
  }
  ```

## 内容 (Content)

### 1. 搜索视频
- **Endpoint**: `GET /api/search?q={query}`
- **描述**: 根据关键字在所有已启用的视频源中搜索视频。
- **查询参数**:
  - `q`: 搜索关键字。

### 2. 从指定源精确搜索
- **Endpoint**: `GET /api/search/one?q={query}&resourceId={resourceId}`
- **描述**: 在指定的视频源中精确匹配视频标题。
- **查询参数**:
  - `q`: 搜索关键字（通常是视频标题）。
  - `resourceId`: 视频源的 `key`。

### 3. 获取视频详情
- **Endpoint**: `GET /api/detail?source={source}&id={id}`
- **描述**: 从指定视频源获取视频的详细信息（包括剧集列表）。
- **查询参数**:
  - `source`: 视频源的 `key`。
  - `id`: 视频的 ID。

### 4. 获取可用视频源
- **Endpoint**: `GET /api/search/resources`
- **描述**: 获取所有已启用的视频源列表。

### 5. 豆瓣数据
- **Endpoint**: `GET /api/douban?type={type}&tag={tag}&pageSize={size}&pageStart={start}`
- **描述**: 获取豆瓣分类排行数据。
- **查询参数**:
  - `type`: `movie` 或 `tv`。
  - `tag`: 豆瓣标签，如 "热门", "最新", "top250"。
  - `pageSize`: 每页数量。
  - `pageStart`: 起始位置。

### 6. 豆瓣自定义分类数据
- **Endpoint**: `GET /api/douban/categories?kind={kind}&category={category}&type={type}&limit={limit}&start={start}`
- **描述**: 获取豆瓣自定义筛选的分类数据。
- **查询参数**:
  - `kind`: `movie` 或 `tv`。
  - `category`: 分类，如 "movie", "tv"。
  - `type`: 类型，如 "hot_gaia", "now_playing"。
  - `limit`: 每页数量。
  - `start`: 起始位置。

### 7. 图片代理
- **Endpoint**: `GET /api/image-proxy?url={imageUrl}`
- **描述**: 代理获取图片，主要用于解决豆瓣图片的防盗链问题。
- **查询参数**:
  - `url`: 原始图片 URL。

## 用户数据 (User Data)

### 1. 播放记录
- **Endpoint**:
  - `GET /api/playrecords`: 获取所有播放记录。
  - `POST /api/playrecords`: 添加或更新一条播放记录。
  - `DELETE /api/playrecords?key={key}`: 删除指定记录。
  - `DELETE /api/playrecords`: 清空所有记录。
- **描述**: 管理用户的视频播放记录。
- **POST 请求体**:
  ```json
  {
    "key": "source+id",
    "record": { ...PlayRecordObject }
  }
  ```

### 2. 收藏
- **Endpoint**:
  - `GET /api/favorites`: 获取所有收藏。
  - `GET /api/favorites?key={key}`: 获取单条收藏状态。
  - `POST /api/favorites`: 添加或更新一条收藏。
  - `DELETE /api/favorites?key={key}`: 删除指定收藏。
  - `DELETE /api/favorites`: 清空所有收藏。
- **描述**: 管理用户的收藏列表。
- **POST 请求体**:
  ```json
  {
    "key": "source+id",
    "favorite": { ...FavoriteObject }
  }
  ```

### 3. 搜索历史
- **Endpoint**:
  - `GET /api/searchhistory`: 获取搜索历史。
  - `POST /api/searchhistory`: 添加一条搜索历史。
  - `DELETE /api/searchhistory?keyword={kw}`: 删除指定历史。
  - `DELETE /api/searchhistory`: 清空所有历史。
- **描述**: 管理用户的搜索历史。
- **POST 请求体**:
  ```json
  {
    "keyword": "搜索词"
  }
  ```

### 4. 片头片尾设置
- **Endpoint**:
  - `GET /api/skipconfigs`: 获取所有跳过设置。
  - `GET /api/skipconfigs?source={s}&id={id}`: 获取单个视频的跳过设置。
  - `POST /api/skipconfigs`: 添加或更新一个跳过设置。
  - `DELETE /api/skipconfigs?key={key}`: 删除一个跳过设置。
- **描述**: 管理用户对特定视频的片头/片尾跳过时间设置。
- **POST 请求体**:
  ```json
  {
    "key": "source+id",
    "config": { "enable": true, "intro_time": 85, "outro_time": 90 }
  }
  ```

## 管理 (Admin)

**注意**: 以下 API 均需要管理员或站长权限。

### 1. 获取管理配置
- **Endpoint**: `GET /api/admin/config`
- **描述**: 获取完整的站点管理配置信息。

### 2. 重置配置
- **Endpoint**: `GET /api/admin/reset`
- **描述**: **[仅站长]** 将所有配置重置为默认值。

### 3. 站点设置管理
- **Endpoint**: `POST /api/admin/site`
- **描述**: 更新站点基本设置，如网站名称、公告等。
- **请求体**:
  ```json
  {
    "SiteName": "New Site Name",
    "Announcement": "New announcement",
    // ... 其他站点设置
  }
  ```

### 4. 用户管理
- **Endpoint**: `POST /api/admin/user`
- **描述**: 对用户进行管理操作，如添加、封禁、设为/取消管理员等。
- **请求体**:
  ```json
  {
    "action": "ban", // 'add', 'ban', 'unban', 'setAdmin', 'cancelAdmin', 'deleteUser', 'setAllowRegister'
    "targetUsername": "user_to_manage",
    "targetPassword": "password_for_new_user", // 仅 'add' 时需要
    "allowRegister": true // 仅 'setAllowRegister' 时需要
  }
  ```

### 5. 视频源管理
- **Endpoint**: `POST /api/admin/source`
- **描述**: 管理视频源，如添加、禁用、排序等。
- **请求体**:
  ```json
  {
    "action": "add", // 'add', 'disable', 'enable', 'delete', 'sort'
    "key": "new-source-key",
    "name": "New Source Name",
    "api": "https://.../api.php/provide/vod/",
    "order": ["source1", "source2"] // 'sort' 时需要
  }
  ```

### 6. 自定义分类管理
- **Endpoint**: `POST /api/admin/category`
- **描述**: 管理自定义的豆瓣分类，如添加、禁用、排序等。
- **请求体**:
  ```json
  {
    "action": "add", // 'add', 'disable', 'enable', 'delete', 'sort'
    "name": "My Category",
    "type": "movie",
    "query": "some_query_string",
    "order": ["query1:movie", "query2:tv"] // 'sort' 时需要
  }
  ```

## 其他 (Miscellaneous)

### 1. 获取服务器配置
- **Endpoint**: `GET /api/server-config`
- **描述**: 获取一些公开的服务器端配置，如站点名称和存储类型。

### 2. 定时任务触发
- **Endpoint**: `GET /api/cron`
- **描述**: 手动触发定时任务，用于刷新用户播放记录和收藏中的视频信息（如总集数）。
