# 跨客户端与页面 E2E 入口

本页维护可复用脚本、参数及各脚本的输入边界。运行前先按[测试总入口](../../docs/testing/README.md)准备隔离环境，单元/契约命令分别见[桌面测试](../../frontend/TESTING.md)和[移动测试](../../mobile/TESTING.md)；下列页面夹具、合成媒体和真实原生流程不可混记。

## 本机工具与设备

新部署与发布链路使用 [open-source-readiness.mjs](open-source-readiness.mjs)：从生产 Dockerfile 构建隔离服务，验证基础注册、管理鉴权、发布校验、Tauri 真实签名和浏览器下载，支持 local / MinIO。命令及验收边界见[发布指南](../../docs/releases.md#本地部署-e2e)。

真实设备和服务端测试使用自己的专用环境，脚本不默认连接维护者的设备或部署。历史报告与截图不随源码分发。

| 配置 | 用途与默认行为 |
|---|---|
| `OPENMEETING_TEST_PYTHON` | Python 路径；未设置时优先使用当前仓库 `server/.venv`，再使用 PATH 中的 Python |
| `OPENMEETING_ADB_BIN` | ADB 路径；未设置时从 `ANDROID_SDK_ROOT` / `ANDROID_HOME` 读取，或使用 PATH 中的 `adb` |
| `OPENMEETING_E2E_DEVICE` | 专用 Android 设备 ID，来自 `adb devices`；涉及真机的脚本要求显式配置 |
| `FLUTTER_ROOT` / `FLUTTER_SDK` | Flutter SDK 根目录；`mobile-rtc-release-race.mjs` 需要其中一项 |
| `OPENMEETING_RTC_TEST_ENV` | 测试服务的部署配置文件；未设置时使用当前仓库 `server/.env`，仅复用需要的平台配置 |
| `MEETING_READY_NATIVE_SDK` | 需要创建 SDK 调试副本时的本机 SDK 源码目录，必须显式指定 |
| `MEETING_UI_NATIVE_CLIENTS` | 已构建原生测试客户端的父目录，子目录 `a` / `b` / `c` 包含各自的 `openmeeting.exe` |
| `OPENMEETING_NATIVE_CLIENT_DIR` | 桌面 / Android 共享测试使用的原生客户端目录 |

例如在 PowerShell 中设置 `$env:OPENMEETING_E2E_DEVICE='<device-id>'`，替换为专用测试设备的实际 ID。Python、Flutter、Bun、Cargo 等工具需先安装；不把生产凭据放入脚本、报告或提交中。历史清理脚本的容器身份保护保留，只有确认本次资源所有权后才能执行清理。

## 会中 PCM 对象存储

`server/meeting_ms/tests/test_recording_chunk_objects.py` 在独立会议测试库验证上传幂等、502/503、提交失败重试、校验和保留策略。仅显式设置 `PCM_TEST_MINIO_ENDPOINT`、`PCM_TEST_MINIO_BUCKET`、`PCM_TEST_MINIO_ACCESS_KEY_ID`、`PCM_TEST_MINIO_ACCESS_KEY_SECRET` 时执行真实 MinIO 用例；测试使用独立随机对象前缀并在结束时清理，STT/LLM 为明确夹具。

`pcm-object-migration.py` 只允许 `PCM_MIGRATION_DATABASE_URL` 指向本机名为 `pcm_migration_test` 的专用空库，验证旧分片 / 字段移除、完整录音及文字记录保留和重复升级。不得指向业务数据库。真实出站代理和多服务存储验证沿用 `minio-roundtrip.py`，可用 `MINIO_STORAGE_OUTPUT` 指定独立产物目录。报告从 XML / JSON 生成：`python tests/e2e/pcm-object-report.py`，默认输出 `.artifacts/pcm-object-storage/测试报告.md`；此项为后端存储变更，无页面截图验收。

## 结束与离会返回首页

可用 `OPENMEETING_RETURN_HOME_OUTPUT` 指定本轮独立产物目录；脚本和报告生成器使用同一目录。

在仓库根目录先执行 `node tests/e2e/meeting-return-home.mjs --smoke` 验证失败夹具，再不带参数执行页面流程。桌面使用真实 Next 页面和明确的业务/IM/媒体夹具，覆盖双视口结束、离会、失败重试及弹层关闭；运行后用 `node tests/e2e/meeting-return-home-report.mjs` 从结构化产物组装报告。移动端入口见[移动测试](../../mobile/TESTING.md#结束与离会路由)，不将组件夹具记为真机或生产后端通过。

## 房主未开始会议的提示

先 `node tests/e2e/meeting-not-started.mjs --smoke` 验证明确not_started/not_found及POST入会故障入口，再不带参数运行。独立Next3197、生产真实错误适配器和中英文双视口验证未开始、不存在、预检查通过后入会失败、返回后重新加入成功；媒体/HTTP/IPC为显式夹具。先全部断言后统一截图。本地产物.artifacts/scheduled-meeting-not-started/，逐张查看登记visual-reviews.json后用 `--archive` 生成本地验收记录（不随源码分发）。后端另用独立PostgreSQL55443/not_started_test验证真实错误契约，移动端定向控制器测试验证detail保留；不代表本轮原生三端验收。

## 固定会议号预定与重复场次

从项目根目录启动 `tests/e2e/fixtures/scheduled-lifecycle-service.py`（Python解释器与依赖同server，PYTHONPATH指向server）。仅允许OPENMEETING_SCHEDULED_TEST_DATABASE指向本轮127.0.0.1:55442/scheduled_lifecycle_e2e；OPENMEETING_SCHEDULED_OUTPUT为.artifacts/scheduled-meeting-lifecycle绝对路径。先启动隔离PostgreSQL16并创建该数据库，禁止复用日常数据库。服务运行真实meeting_ms和迁移，身份/IM/RTC/模型提交是明确夹具。

先 `node tests/e2e/scheduled-lifecycle.mjs --smoke`，再执行不带参数的脚本，自动启动Next3168、使用real业务适配器、保留原3118/39110。包含预定创建/编辑/取消失败重试、活动限制、真实API两场独立记录。`--seed-only`仅通过桌面表单创建供Android继续的预定；`--room-ui`补验真实桌面提前加入密码预定、继续会议、确认结束和同号再次进入。统一使用同一个持久化30分钟预算。

Android使用已授权AVD emulator-5580、隔离后缀.scheduledtest，ADB reverse3169/39349；先 `node tests/e2e/scheduled-lifecycle-android.mjs`，再在mobile执行 `flutter test --no-pub integration_test/scheduled_lifecycle_test.dart -d emulator-5580 --dart-define=APP_ENV=dev --reporter expanded`，构建环境OPENMEETING_ANDROID_DEBUG_SUFFIX=.scheduledtest。移动端真实页面/控制器/HTTP继续桌面预定，媒体激活明确替身。脚本完成后另行关闭本次模拟器、业务服务和测试容器。

组件补验 `node tests/e2e/upcoming-meetings.mjs` 使用显式数据边界，覆盖排序/搜索、长列表滚动、加载/错误/空态、长主题和活动菜单权限，不代表真实业务或媒体。可设置UPCOMING_MEETINGS_OUTPUT到本轮产物/component。实际逐张查看截图后登记visual-reviews.json，执行 `node tests/e2e/scheduled-lifecycle-report.mjs --archive` 从JSON和日志生成本地验收记录（不随源码分发）。保留历史失败，不把中间步骤通过写成整套通过。

## 会后多会话转写与主动云下载

在仓库根目录先执行 `node tests/e2e/meeting-processing-state.mjs --smoke`，再执行不带参数的同一脚本。隔离 Next :3167 和显式 HTTP/IPC/IM/RTC 夹具验证房主、在线成员、提前离开成员三个独立登录会话：结束后等待、自动显示转写、状态读取错误、处理失败/取消及重试、完成后的真正空结果。挂载/切换标签/处理完成刷新均断言下载调用为零，只有“云下载”才获取录音并播放。桌面1280×800与窄窗口520×760全部断言通过后统一截图。

`--checks` 执行 TypeScript、前端单元和录音/音频契约，需要 Bun（可设置 OPENMEETING_BUN_BIN）。累计30分钟E2E预算不因失败重置。产物 `.artifacts/meeting-processing-state/`；逐张查看截图后写入 `visual-reviews.json`，通过 `--report` 自动生成报告、`--archive` 归档至 [当前功能与限制](../../docs/feature-status.md)。真实设备采集、模型输出、IM投递、Rust文件落盘及移动原生页面另行验收；浏览器三个上下文不等同于真实三台设备。

Android会后详情专项：启动隔离模拟器并设置ADB reverse tcp:39348后，先运行 `node tests/e2e/meeting-processing-android.mjs`，再从mobile运行 `flutter test --no-pub integration_test/meeting_processing_test.dart -d emulator-5580 --dart-define=APP_ENV=dev --reporter expanded`，构建时设置 `OPENMEETING_ANDROID_DEBUG_SUFFIX=.processingtest`。协调器复用本轮累计预算，提供桌面:3167与Android共同读取的HTTP任务夹具；覆盖排队、运行、完成和失败，转写页停留期间自动更新。Android截图为原生像素，仍不代表真实跨端RTC房间或音轨采集。仅关闭本次模拟器、协调器和开发服务；最终报告合并Android结果、单元/静态检查及清理记录。

## Windows 与 Android 真机共享

`mobile-desktop-share.mjs setup` 探测已有测试会话、复用 :39110，启动 :3160 透明转发、:39343 ADB loopback 协调器及当前前端 :3162。`desktop` 使用既有隔离调试壳启动 Windows，`create` 从真实快捷会议创建临时房间。Android 设置 `OPENMEETING_ANDROID_DEBUG_SUFFIX=.coreretry`，从 `mobile/` 运行 `flutter test --no-pub integration_test/share_interop_test.dart -d <无线ADB设备> --dart-define=APP_ENV=dev --dart-define=OPENMEETING_SERVER_URL=http://127.0.0.1:39110 --reporter expanded`；设备、SDK 和缓存构建路径当前为本地验收环境，迁移前须修改对应启动配置。

根目录运行 `node tests/e2e/mobile-desktop-share.mjs verify` 验证真实双向媒体及原生授权拒绝。断言全过后重新启动同一 Android 测试，执行 `verify --visual` 统一采集 1280×800/640×800 桌面和原始平板视口；Windows 选窗由 `select-share-source.ps1` 只操作本轮进程的 RGB 测试窗口。没有注入假媒体或替换 IM/RTC。`.artifacts/share-interop-current.json` 指向当前结果；30 分钟预算在同一目录内保持不变，失败历史保留。逐张查看最终截图并写入 SHA-256 视觉记录后，执行 `mobile-desktop-share-report.mjs` 自动组装报告。`cleanup` 只结束本轮房间、删除生成记录、停止自己的客户端/服务，恢复测试 profile、息屏超时和原映射，保留日常服务与原应用；静态检查和最终环境探测亦写入该目录。

## 历史会议与待开始会议

`node tests/e2e/upcoming-meetings.mjs` 使用真实会议记录页、历史列表、加入/预定/修改/取消弹窗及样式，原生桥接、账号与数据为显式夹具。输出 `.artifacts/upcoming-meetings/`（可用 `UPCOMING_MEETINGS_OUTPUT` 覆盖）：历史转写搜索及标签切换保留查询，今天/明天/下周/两年后分组，排除取消/结束/过期项，会议号搜索、窄窗口、预填加入意图、修改、后天新建、取消失败重试、加载/错误/空态和旧请求防覆盖。八张截图结合结构化结果复核，不代表真实 IM/RTC 或原生运行验收。

后端在独立测试 PostgreSQL 上运行 `meeting_ms/tests/test_scheduled.py`，验证省略 `to` 后查询包含未来日期、用户隔离、日期排序、原有时间区间及参数校验。勿将测试库指向日常数据。`sched_list` 的 `to` 改为可选，需要同步更新 meeting_ms 与重新构建桌面端；首页及提醒器仍传入原有范围。

## 屏幕共享参会者左侧列布局

`node tests/e2e/screen-share-layout.mjs` 使用真实 `VideoGrid`、媒体元素及应用样式，房间状态和画布媒体为显式夹具，不启动业务服务或连接真实 IM/RTC。默认输出 `.artifacts/screen-share-layout/`，可用 `SCREEN_SHARE_LAYOUT_OUTPUT` 指定独立目录。覆盖桌面、预留侧栏宽度、390px 窄窗口、短窗口、18 人独立滚动、鼠标/键盘成员资料与菜单、停止共享恢复网格、本地/远端/连接中/错误状态，以及布局切换不重新挂载摄像头元素。结果与六张截图需结合查看；不代表原生系统选屏和真实网络媒体验收。

## 入会加载与失败恢复

`cd frontend` 后执行 `pnpm test:meeting-entry`，验证真实入会组件和 RoomProvider 的创建、会议号预检、密码、设备初始化、权限拒绝、超时、重试及晚到请求；服务/SDK 边界为显式替身。完整页面验证从仓库根目录先运行 `node tests/e2e/meeting-entry-loading.mjs --smoke`，再运行不带参数的脚本。

页面脚本保留日常 3118/39110 及登录态，启动独立 Next :3198（`OPENMEETING_NEXT_DIST_DIR=.next-entry-merge`、开发专用 `OPENMEETING_E2E_DESKTOP_LAYOUT=1`），复用已有 HTTP/IPC/IM/RTC 夹具。先验证确定性聊天 503、加入 404 及恢复，再用 Playwright 跑 1280×800 / 390×844 的创建、连续加载、成功入会、聊天滚动、跨页返回、连接失败重试和入会失败返回。30 分钟预算不随重跑重置；断言通过后统一截图，逐张查看后写入 `visual-reviews.json`，再以 `--report` 从结构化结果组装报告。`MEETING_ENTRY_OUTPUT` 可覆盖默认 `.artifacts/meeting-entry-loading`；已有目录再次运行前先另存失败结果与截图。结束后关闭本次 Next/夹具并恢复 tsconfig，保留日常服务。该测试不证明真实原生设备或平台 RTC 可用。

## 自动录音与全员会后记录

合并后的真实Windows三端补验见[当前功能与限制](../../docs/feature-status.md)和本地验收记录（不随源码分发）。`shared-records-native.mjs` 的 `--smoke` / 无参数 / `--failure-paths` / `--offline` 使用真实鉴权、IM/RTC、Rust、独立业务服务/数据库与合成麦克风；功能通过后 `--visual` / `--offline-visual` 统一截图。`shared-records-native-report.mjs` 从结构化结果生成报告，`--archive` 归档。此轮发现并修复离线同步早于实时监听导致漏显入口，不能只用消息注入证明离线送达。首轮原生清理GET已结束房间失败及后续恢复清理均保留。

当前流程见[当前功能与限制](../../docs/feature-status.md)。从仓库根目录先执行 `node tests/e2e/meeting-shared-records.mjs --smoke`，成功后不带参数执行。脚本探测并保留日常服务/登录态，启动独立 Next :3164（`.next-e2e-shared-records`）和随机回环 HTTP 夹具，使用真实页面及显式 IPC/IM/RTC 替身。覆盖房主自动录音状态、成员提前离开、结束通知、只读记录、合成 WAV 播放、下载等待/成功/503恢复、转写/纪要滚动、处理失败保留音频、无音频与非参会者拒绝；浏览器三个角色由夹具控制，真实账号授权另由 API 测试证明。真实 RTC 采集、IM 离线投递、原生文件落盘和系统目录弹出未验收。

后端使用专用 PostgreSQL 测试库，设置 `OPENMEETING_TEST_DATABASE_URL` 后从 `server/` 执行 `pytest meeting_ms/tests/test_shared_records.py meeting_ms/tests/test_recording_controls.py meeting_ms/tests/test_room_recording.py meeting_ms/tests/test_rooms.py meeting_ms/tests/test_im_notifications.py meeting_ms/tests/test_meetings.py meeting_ms/tests/test_summary.py -q --junitxml=../.artifacts/meeting-shared-records/backend.xml`。严禁指向日常或 E2E 正在使用的数据库。然后执行 `node tests/e2e/shared-records-checks.mjs` 汇总前端/契约/Rust/后端检查；Bun 不在 PATH 时设置 `OPENMEETING_BUN_BIN` 指向已有二进制，Rust 可用 `CARGO_TARGET_DIR` 复用缓存。

本地产物 `.artifacts/meeting-shared-records/`，`SHARED_RECORDS_OUTPUT` 可指定新目录。30 分钟 E2E 累计预算不重置，先双视口断言全部通过，再统一截图；逐张实际查看后记录 `visual-reviews.json`，保留历史失败及原因。执行 `--report` 从 JSON/日志生成报告，`--archive` 归档至 `docs/testing/archive/自动录音与全员会议记录/`。页面脚本关闭自己的 Next/浏览器/HTTP 夹具并恢复 tsconfig；专用数据库由启动者关闭，记录 `cleanup.json` 后重新生成报告。不要关闭原先运行的数据库和日常服务。

## 聊天图片视频直接展示

本次组件交互验收使用 `node tests/e2e/chat-inline-media.mjs --smoke` 先验证错误夹具，再运行 `node tests/e2e/chat-inline-media.mjs`。自动启动隔离Next :3144和随机端口业务夹具，保留现有3118/39110与登录态；生产页面、合成媒体、显式IPC/IM替身。`CHAT_INLINE_MEDIA_OUTPUT`可覆盖默认 `.artifacts/聊天图片视频直接展示/`，`MEETING_CHAT_VIDEO`可覆盖现有MP4夹具。

覆盖登录/入会/聊天成功冒烟，图片直接展示与放大、视频行内播放与放大关闭、错误重试、加载取消、大文件限制和关闭聊天释放资源。共享30分钟浏览器预算，失败不重置；单步60秒上限。先完成1440×900、390×844断言，再统一截图并逐张实际查看。运行 `node tests/e2e/chat-inline-media-checks.mjs` 完成类型、单元和生产构建；写入实际视觉记录后，运行 `node tests/e2e/chat-inline-media-report.mjs` 从产物组装报告。旧快照中“预览 / 播放”的图片/视频交互不作为本次UI入口。原生协议与对象存储验收范围见[说明](../../docs/chat-inline-media.md)。

## 聊天姓名与 IM 头像设置（三端）

先按下方会议就绪启动器准备真实隔离后端与三份专用 Tauri 客户端：Next `3162`、后端 `3160/3161/3167`、出网代理 `3163`、CDP `9261/9262/9263`。设置新的 `MEETING_READY_OUTPUT`（默认 `.artifacts/chat-sender-avatar-settings`），不要使用日常账号。已有缓存调试二进制可复用，生产包须另验收。

```powershell
node tests/e2e/chat-avatar-checks.mjs
node tests/e2e/chat-avatar-settings.mjs --smoke
node tests/e2e/chat-avatar-settings.mjs
node tests/e2e/chat-avatar-settings.mjs --visual
```

功能断言通过后统一采集 1280×800 / 520×760 截图，逐张查看后写入 `visual-reviews.json`（截图相对路径映射到 `{pass,notes,viewport,method}`）。运行 `node tests/e2e/chat-avatar-report.mjs` 组装报告并归档到 `docs/testing/archive/聊天身份与头像设置/`，保留历史失败和截图。上传 helper 记录 `avatar-files.json`；清理器会校验 IM 文件 owner 和 purpose 后仅删除登记的测试头像。

清理顺序：`rtc-release-media-stop.mjs` 结束会议并退出 → `meeting-ready-desktops.mjs --stop` → 后端仍运行时执行 `meeting-ready-cleanup.py <服务配置>` 清理平台身份/群/已登记头像 → 关闭本轮后端和仅由本轮启动的数据库 → 探测日常服务及专用端口。清理器需要与隔离后端相同的 gateway/egress URL 和内部服务令牌，勿关闭代理后再清理。完成后再次生成报告。

## 统一出入网关专项

先安装服务开发依赖和 Playwright Chromium；可设置 `OPENMEETING_TEST_DEPENDENCIES` 指向已有前端依赖工作区。Docker Desktop 须可用。此专项复用已有依赖镜像并挂载当前生产服务源码；新环境先 `cd server; docker compose build`，再将 `docker-compose.egress-test.yml` 中四个 image 替换为本地构建标签。测试不会调用真实云供应商。

```powershell
python tests/e2e/fixtures/egress-cert.py
node tests/e2e/unified-egress.mjs --smoke
node tests/e2e/unified-egress.mjs
```

脚本使用隔离项目 `openmeeting-egress-acceptance`、三个独立数据库、四个业务服务和 edge 网络供应商夹具；API :39710、代理 :39711、供应商 :39880/:39881、Vite :5179。先探测既有服务和会话；原会话所属业务库不被测试清库，隔离环境使用专用管理员会话。先独立验证实际 IM/OSS/ASR/模型下载 SDK 传输、外网直连阻断和确定性故障入口，完整冒烟通过后才运行真实页面。页面累计调试预算为 30 分钟，重跑不清除 `.artifacts/unified-egress/ui-budget.json`。

桌面 1280×800、窄窗口 800×900 分别完成断言后，统一采集正常、加载、成功、错误、空态、权限、弹窗打开/关闭、表格滚动和长文本滚动截图。输出 `.artifacts/unified-egress/`，逐步 JSON、失败历史和日志保留；截图按编号命名。实际查看每张图后写 `visual-reviews.json`，再执行 `node tests/e2e/unified-egress.mjs --report` 自动组装报告。脚本 finally 关闭本轮 Vite 和隔离容器，保留数据卷；强制中断须手动停止对应隔离项目。trace 仅本地保留，不归档认证快照、证书私钥或数据库。

白名单、CONNECT/TLS、SDK 环境及生产升级方式见[统一网关说明](../../docs/unified-egress.md)。此验收验证真实代码和 SDK 的代理传输，不替代真实 IM 平台、短信送达、云端推理及模型权重下载验收。

检查汇总写入产物目录的 `checks.json`，历史调试原因写入 `setup-history.json`；执行 `node tests/e2e/unified-egress.mjs --archive` 从这些结构化产物组装报告，并精简归档至 `docs/testing/archive/统一出入网关/`。归档保留失败证据，不包含证书私钥、trace 认证快照或数据库。

## 内部网关与独立数据库真实验收

先按[独立数据库说明](../../docs/database-isolation.md)启动隔离项目的三个 PostgreSQL，再在仓库根运行：

```powershell
# 可复用主工作区的虚拟环境与 Playwright；新克隆按项目说明安装依赖。
$env:OPENMEETING_TEST_PYTHON='C:/projects/meeting/server/.venv/Scripts/python.exe'
$env:OPENMEETING_TEST_DEPENDENCIES='C:/projects/meeting'
node tests/e2e/internal-gateway.mjs --smoke
node tests/e2e/internal-gateway.mjs
node tests/e2e/internal-gateway.mjs --scroll-only
```

管理端需安装 `server/admin-web` 锁定依赖（worktree 可复用已有依赖）。脚本运行工作树生产四服务源码和真实 Vue/Vite 管理端，隔离端口 39710/39713/39707/39709、5179；仅测试启动器提供网关出站断连及列表错误/延迟，生产服务不注册控制入口。先独立冒烟，再跑真实登录、新增用户、客户端验证码登录与创建会议、跨库统计、抽屉/弹窗、故障保留数据和恢复删除。1280×800、800×900 断言全过后采集双视口截图。累计调试预算保存在 budget.json，不得为继续调试重置。

产物 `.artifacts/internal-gateway-routing/`；逐图查看后写入 visual-reviews.json，再运行 `node tests/e2e/internal-gateway.mjs --report`。归档至 `docs/testing/archive/内部网关与独立数据库/`，不归档会话、数据目录或包含网络令牌的 trace。脚本自动关闭四服务与 Vite；数据库由启动者另行 `docker compose -p openmeeting-gateway-acceptance -f docker-compose.yml -f docker-compose.gateway-test.yml stop user-postgres meeting-postgres stt-postgres`，记录后保留原服务。测试不修改旧部署业务数据，不代替生产迁移、原生设备或真实平台验收。

## 会议模块配置回归

先运行 `node tests/e2e/meeting-ui-config.mjs --smoke`，再运行不带参数的同一脚本。默认产物在 `.artifacts/会议模块配置/`，隔离开发端口3168；双视口逐项检查模块开关、陈旧入会选项与失败恢复，断言全通过后统一截图。实际查看截图后运行 `--report`，报告从结构化结果生成；完整范围、配置方式和夹具边界见[模块配置说明](../../docs/meeting-ui-config.md)。

会议准备提示与模块开关的合并兼容契约：`node frontend/tests/contracts/meeting-ready-ui.mjs`。它渲染实际RoomScreen，验证全关/单模块连接状态及共享状态隐藏，不替代上面的真实页面流程。

## 三端消息同步、会议准备与截图预览

开发方案见 [当前功能与限制](../../docs/feature-status.md)。默认产物 `.artifacts/meeting-ready-im-sync/`，完整真实 Windows Tauri 三端；禁止指向日常客户端。

1. 先读启动说明，探测日常服务及窗口。准备专用 PostgreSQL `127.0.0.1:55439`，使用独立数据库 `meeting_ready_user` / `meeting_ready_meeting`。脚本只复用现有 `.env` 的 IM 配置，不覆盖原配置、不发送短信。
2. 从 `server/` 用已有虚拟环境执行 `python ../tests/e2e/meeting-ready-services.py --env <原 server/.env>`，启动真实网关3160、用户服务3161、会议服务3167。账户密码只保存在本地产物 `accounts.private.json`，不得归档。

   启动器同时配置内部网关3160和仅监听回环的出站代理3163，目标许可复用部署配置。若本机DNS返回198.18等Fake-IP，可将经公开DNS核实的准确域名→公网IP JSON文件路径设置为 `MEETING_READY_DNS_MAP`；它仅改变隔离网关进程的域名解析，保留生产代理的原域名/端口许可、地址检查和TLS验证。未配置时使用系统DNS，不自动放行私网。此流程不启动STT，若验证转写还须另备本机STT39109；日常内部网络中的STT不会发布该端口。
3. 从根目录设置 `MEETING_READY_NATIVE_SDK` 为本机 `tauri-plugin-deeprespond-im-1.0.0-alpha` 源码目录；`MEETING_READY_CARGO_TARGET` 可指定共享缓存，`OPENMEETING_TEST_PYTHON` 指定已有 Python。运行 `node tests/e2e/meeting-ready-desktops.mjs --build --start`。首次构建前需按项目说明准备 FFmpeg 二进制。三个独立 identifier、主窗口及隐藏引擎开放匹配的CDP参数；SDK调试副本只加参数，不改业务能力，Cargo.lock 结束恢复。
4. 依次运行 `node tests/e2e/meeting-ready-native.mjs --smoke`、`node tests/e2e/meeting-ready-native.mjs`、`node tests/e2e/meeting-ready-visual.mjs`、`node tests/e2e/meeting-ready-quick-capture.mjs`。先断言再截图。`--resume` 继续同一房间的失败阶段，`--permissions-only` 只复核最后的原生权限步骤，均保留已通过步骤来源标记和历史失败，不重置30分钟累计预算。新的独立验收应保留旧产物再使用新的目录/检出，不能删除预算来延长本轮调试。
5. 实际逐张检查后填写 `visual-reviews.json`。必要时 `meeting-ready-quick-capture.mjs --waiting` 在关闭音频选择框后重拍等待室，原遮挡图保留。`node tests/e2e/meeting-ready-checks.mjs` 记录前端/SDK检查；后端 pytest 的 JUnit 写 `backend.xml`。运行 `node tests/e2e/meeting-ready-report.mjs --archive` 自动组装报告、失败对应图与归档，禁止将主动错误图标成真实IM故障。
6. 用 `meeting-ready-desktops.mjs --stop` 停止本轮客户端和Next；停止本轮 Python 子服务，监督进程记录关闭结果。`meeting-ready-cleanup.py <原 server/.env>` 仅删除独立测试库及账户台账绑定、且群业务属性匹配的 IM 测试资源。复核本轮端口关闭，并将原本停止的专用数据库容器恢复停止；记录 `cleanup.json` 后重新组装报告。日常服务及窗口保留。

测试采用真实密码认证、原生 IPC、IM/RTC SDK、OSS 上传下载与图片解码；错误分支通过隔离服务开关和本地图片协议拦截确定性触发。视口是原生 WebView 的 CDP 视口仿真，过渡动画在自动化中关闭；不等同于真实硬件音视频传输或生产安装包验收。

原生主流程、视觉及RTC媒体补验均支持 `MEETING_READY_SYNTHETIC=1`，通过已有 `media-input.mjs` 在本次客户端主页面与引擎页面安装振荡器/画布采集源，保留真实IM/RTC传输。默认不替换采集；开启时须在报告标明合成输入，不计作物理设备验收。使用缓存原生构建时，主窗口与引擎的浏览器参数必须匹配，不能仅靠给引擎追加fake-device参数处理权限弹窗。

## IM 视频通道屏幕共享

当前第二普通视频轨道设计见[专项说明](../../docs/im-rtc-second-video.md)，旧SCREEN_SHARE方案及403保留为历史。基于最新develop新建worktree后，在frontend执行pnpm install --frozen-lockfile安装锁定依赖。先探测保留已有服务和登录态，再单独冒烟：

```powershell
node tests/e2e/rtc-capture-smoke.mjs
node tests/e2e/im-rtc-screen-share.mjs --smoke
```

页面在隔离 Next :3188 执行，默认连接已配置的真实 IM 平台，通过 :3177 本地代理仅在内存交付临时用户/频道票据；使用 OPENMEETING_TEST_PYTHON 指定安装了服务端 SDK 的 Python，OPENMEETING_RTC_TEST_ENV 指定现有 IM 配置文件（不覆盖）。原生 CDP 不可用时保留日常客户端，测试创建自己的临时身份，不读取现有令牌。

```powershell
node tests/e2e/im-rtc-second-video-probe.mjs
node tests/e2e/im-rtc-screen-share.mjs
```

先用im-rtc-second-video-probe.mjs确认真实平台两条Camera视频发布订阅、独立控制、晚加入及subscriber发布拒绝，再运行完整页面；两者共用30分钟预算。本轮显式采用Camera来源+screen:<sessionId>名称扩展，不修改平台权限，不能当作官方原生屏幕共享支持。真实发布或解码失败必须保留。

可显式运行本地 SFU 测试：从 LiveKit 官方 Windows 发行下载 livekit-server.exe，设置 OPENMEETING_TEST_LIVEKIT 指向它（或放在 .artifacts/tools/livekit/），脚本仅在 7880 未运行时启动 --dev --bind 127.0.0.1，结束后关闭。此分支使用真实补丁 SDK media provider、生产 ImChannelMediaClient 和真实 SFU 视频传输，IM 频道控制面、业务 IPC/聊天和采集输入为夹具；不代表平台授权、原生 IPC 或系统选屏通过。

```powershell
node tests/e2e/im-rtc-screen-share.mjs --local-rtc
node tests/e2e/im-rtc-screen-checks.mjs
```

产物默认 `.artifacts/IM第二视频轨道共享/`，IM_RTC_SCREEN_OUTPUT可指定目录。budget.json累计30分钟，不因重试重置，平台探测复用同一预算。到期停止浏览器调试并降级API/契约验证。共用im-rtc-screen-failures.mjs夹具先冒烟，验证发布失败、发布权限403、刷新失败和恢复；合成摄像头也先单独冒烟，避免在E2E超时内调试输入。

先完成桌面 1280×800、窄窗口 640×600 全部断言，再统一截图。覆盖摄像头/屏幕并存、晚加入、接管、返回会议、错误回滚和清理、抽屉滚动及设置权限。逐张实际打开后将 `{screenshot:{pass,notes,sha256}}`（sha256 使用当前截图的 Get-FileHash -Algorithm SHA256，小写；仅填写已实际打开查看的图） 写入 visual-reviews.json，执行 `node tests/e2e/im-rtc-screen-share.mjs --report` 由结构化产物组装报告。所有历史失败保存在 attempts.json；没有实际查看的图片不计视觉通过。旧 meeting-share-return.mjs 仅转发新入口，原 P2P 验收结果只作为历史。

## 摄像头预览确定性浏览器回归

`camera-preview.mjs` 在独立 Next 开发服务 3148 加载生产会议组件，使用
Playwright 无头 Chromium 验证开关五轮、缺失信令回传、SDK 原地替换轨道、
权限拒绝及恢复、聚焦、成员抽屉和弹窗。它替换业务 API、RTC 传输及摄像头
输入，不代替下面的原生双端验收；不读取登录令牌、不操作已有会议。

先在 `frontend/` 安装依赖，再从根目录依次执行：

```powershell
node tests/e2e/camera-preview.mjs --smoke
node tests/e2e/camera-preview.mjs
```

默认产物为 `.artifacts/camera-preview/`，可用 `CAMERA_TEST_OUTPUT` 指定目录。
先独立冒烟夹具，再运行完整回归；桌面 1280×800、窄视口 600×900 的截图
在断言通过后生成。脚本关闭本次服务和浏览器、移除临时 public 文件、恢复
Next 修改的 tsconfig。逐张实际查看截图后，将观察写入 `visual-review.json`
（截图相对路径映射到观察文字），执行 `node tests/e2e/camera-preview.mjs --report`
由结构化结果重新组装报告。未查看的截图显示为待检查。

## 会议 IM 集成分阶段验收

开发范围与已知问题见 [交付清单](../../docs/meeting-im-capabilities.md)。产物在 `.artifacts/meeting-im-integration/`。

1. 保留已运行服务，使用独立测试数据库 `127.0.0.1:55439/openmeeting_im_chat_test`，不要改为业务库。
2. 设置 `OPENMEETING_TEST_PYTHON` 指向已有 server 虚拟环境 Python，运行 `node tests/e2e/meeting-im-checks.mjs`，生成后端 JUnit、类型/SDK/引擎检查记录。
3. 单独运行 `node tests/e2e/meeting-im-integration.mjs --smoke`，通过后运行同一脚本无参数。它启动并关闭隔离 Next 3141 和回环夹具，先双视口断言，再双视口截图，保留失败历史和 trace。
4. 逐张查看截图，在 `visual-reviews.json` 写入 `{screenshot,pass,notes}` 数组，再运行 `node tests/e2e/meeting-im-integration.mjs --report`，报告从结果和检查记录生成，未查看的图不会标为视觉通过。
5. 可选真实 IM：从 server 目录运行 `python ../tests/e2e/fixtures/meeting-im-live-server.py --env <现有 .env>`，仅复用 IM 配置，使用独立数据库和临时用户。再从根目录运行 `node tests/e2e/meeting-im-live.mjs`。服务仅绑定 127.0.0.1:3147，测试结束须停止；该入口注入测试网关身份，不是生产认证入口。脚本删除其创建的 IM 群和用户，失败仍记录，不能冒充原生验收。
6. 需要归档时运行 `node tests/e2e/archive-meeting-im.mjs`。它复制结构化结果、报告、逐图检查和截图到 `docs/testing/archive/会议IM集成/`，大体积 trace 只生成哈希清单，不提交压缩包。

旧 `meeting-im-chat.mjs` 入口转发到上述完整验收。不要同时运行两份页面验收或在同一测试库运行 Python 清库测试和真实 IM 测试。

## 原生双端入口

当前入口是 `native-meeting.mjs`，从最近双端验证流程提取，覆盖正常 UI 发起/入会、双向聊天、真实 RTC 传输、可选系统窗口捕获、结束会议、录音保存与播放。脚本通过 CDP 控制已有的专用 Tauri 测试客户端，直接调用真实 Rust IPC，不替换业务后端或平台 SDK。

## 准备

1. 按[快速启动](../../quickstart.md)启动后端，配置 IM/RTC；准备两个不同的专用测试账号。
2. 准备两个独立 identifier 的 Tauri 开发客户端和配置目录，完成引导、登录，语言设为中文，停留在首页。不要使用日常用户客户端。两端应指向同一网关和测试前端。
3. 分别开放本机 CDP 9256、9257；测试客户端主窗口与隐藏 IM 引擎的 WebView 参数必须一致。当前仓库没有为 SDK 注入调试补丁；历史隔离 SDK 构建的边界见本地验收记录（不随源码分发）。无法连接或 IM 引擎未就绪时先解决测试客户端配置，不能用浏览器 IPC 替身冒充原生成功。
4. 在 `frontend/` 安装锁定依赖。首次使用 Playwright 若缺少浏览器，执行 `pnpm exec playwright install chromium`。屏幕测试还需要本机 Chrome。

已有最近测试的隔离客户端位于工作区外，属于本机产物，新克隆不会自带。新机器需准备自己的专用客户端；脚本不会自动生成账号、覆盖配置或初始化 SDK 调试副本。

测试 Next 服务示例，在 `frontend/` 的 PowerShell 终端执行：

```powershell
$env:OPENMEETING_NEXT_DIST_DIR = '.next-e2e-native'
$env:NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE = 'real'
$env:OPENMEETING_E2E_SYNTHETIC = '0'
pnpm build:im-engine
pnpm exec next dev -p 3138
```

`OPENMEETING_E2E_SYNTHETIC=1` 的旧适配器夹具仅供独立逻辑测试，native E2E 不使用它。native 脚本的 `--synthetic` 只替换 getUserMedia 输入，保留 SDK、RTC、IPC、上传及业务服务。

## 执行

在仓库根目录：

```powershell
node tests/e2e/native-meeting.mjs --help
$env:OPENMEETING_E2E_UI_URL = 'http://localhost:3138/'
$env:OPENMEETING_E2E_HOST_CDP = 'http://127.0.0.1:9256'
$env:OPENMEETING_E2E_MEMBER_CDP = 'http://127.0.0.1:9257'
node tests/e2e/native-meeting.mjs --synthetic
```

也可在 `frontend/` 使用 `pnpm test:e2e:native --synthetic`。不带 `--synthetic` 时申请真实麦克风和摄像头，需要可用设备与授权。

加 `--screen` 时，脚本打开标题为 `OpenMeeting E2E capture source` 的专用 Chrome 窗口。手动选择该窗口，或在专用测试 WebView 中添加 `--enable-usermedia-screen-capturing --auto-select-desktop-capture-source=OpenMeeting E2E capture source`。只捕获该测试源；自动选源不覆盖手动弹窗验收。

## 输出及限制

每次运行创建 `.artifacts/e2e/native-<时间>/`，记录结果、失败及截图，不覆盖历史报告。脚本不写登录令牌、用户录音或完整服务配置。失败后保留测试房间及客户端供检查，必要时通过测试主持人 UI 结束会议；脚本不终止应用或业务服务。

转写/纪要取决于 STT/LLM 配置；脚本记录处理状态，不把模型未配置等同于音频保存失败。真实模型效果、弱网、三人以上、生产安装包、跨平台仍须单独验收。本次结构整理的执行结果见本地验收记录（不随源码分发）。

历史脚本和结果只作为[当前功能与限制](../../docs/feature-status.md)。录音故障恢复测试已提取到 `frontend/tests/contracts/room-recording.mjs`，运行 `pnpm test:recording`。

## 电脑端响应式页面回归

在仓库根目录运行：

```powershell
node tests/e2e/desktop-responsive.mjs --smoke
node tests/e2e/desktop-responsive.mjs
```

脚本先探测现有服务，再启动隔离的 Next 开发服务 3138 和回环 HTTP 夹具。覆盖登录、首页、会议记录、详情、录音、设置全部页签、消息与会议室，在 1280×800、640×600 验证成功、加载、错误、空态、权限、长内容和滚动，并检查五人两列邀请补位、侧栏、聚焦恢复及 24 人短窗口。每步输出结构化 JSON；断言阶段通过后统一运行截图阶段。结束时关闭本次启动的服务，保留原有服务。

这是页面布局测试：`OPENMEETING_E2E_DESKTOP_LAYOUT=1` 仅在开发环境显式替换 IPC、IM 与 RTC 依赖，不能替代上面的原生双端回归，也不验证真实设备、系统文件对话框和首次安装引导。夹具位于 `fixtures/desktop-layout-*`，不创建真实账号或写业务后端。

产物在 `.artifacts/桌面响应式布局/`，包括 `results.json`、逐步截图、服务日志和自动组装的 `测试报告.md`；调试失败保留在结果历史中。实际查看截图后，将逐张结论写入该目录的 `visual-reviews.json`（键为结果中的相对截图路径，值为检查结论），再执行以下命令刷新报告。未查看的截图在报告中保持待检查。

```powershell
node tests/e2e/desktop-responsive.mjs --report
```

独立新一轮回归可通过 `DESKTOP_RESPONSIVE_OUTPUT` 指定新的 `.artifacts/` 子目录；同一轮重试继续使用该目录，保留预算与失败历史。脚本会先预编译涉及的路由，避免将首次 Next 编译耗时混入交互等待。全功能验收应同时运行预定、入会、聊天媒体、共享和会后记录专项，原生设备、生产安装包以及未通过的旧夹具须单独记录，不能由页面布局通过推定。

聊天与响应式脚本按当前契约断言结束会议返回首页。摄像头夹具复用会议聊天 SDK 替身，以实际房间就绪状态关闭全局入会遮罩，并实现当前 LiveKit 适配器的 `createTracks`、`publishTrack`、`mute`、`unmute` 接口；画面来自动态 canvas，不代表实体摄像头或真实 IM/RTC 验收。

## 会议预定日期与时间选择

新工作树基于 develop，先运行 `node tests/e2e/schedule-time-picker.mjs --smoke` 单独验证错误/延迟/恢复夹具，再运行无参数脚本。自动启动 Next :3159（`.next-e2e-schedule`）及现有显式 HTTP/IPC 夹具；保留日常 :3118/:39110 和登录态。脚本以固定本地时间验证两种视口的日历、滚轮/键盘选择、分段输入与非法值、创建失败重试及编辑回填，断言全部通过后统一截图，并补充英文检查。30 分钟预算持久化，失败不重置。

`--checks` 执行类型检查。产物在 `.artifacts/schedule-time-picker/`；逐图查看后写入 `visual-reviews.json`，运行 `--report` 生成本地报告、`--archive` 生成本地验收记录（不随源码分发）。报告由逐步 JSON、视觉记录和历史失败证据组装。该局部组件测试不代表真实业务服务、原生三端或 IM/RTC 验收。

## 侧栏设计对齐

先运行 `node tests/e2e/nav-design-alignment.mjs --smoke`，再运行不带参数的同一脚本。隔离 Next :3158 与现有显式布局/IM 夹具验证四项导航、登录失败恢复、会议聊天及隐藏工作台兼容路由；保留日常 :3118。`--checks` 执行类型与 IM/会议聊天契约检查。逐张查看截图后写入 `visual-reviews.json`，运行 `--report` 在产物目录生成报告；默认产物 `.artifacts/nav-design-alignment/`，可用 `NAV_DESIGN_OUTPUT` 为新一轮指定独立目录。复测不自动覆盖历史归档，确认需要归档时显式执行 `--archive`，历史见本地验收记录（不随源码分发）。测试结束会恢复 Next 改写的 tsconfig。不代表真实 IM/RTC 或原生三端验收。

## 会议 IM 聊天专项

消息气泡和操作菜单的快速回归：仓库根目录运行 `node tests/e2e/chat-message-actions.mjs`。使用生产共用组件、真实样式和显式 IM/剪贴板夹具，覆盖左右头像与昵称、仅复制/删除/撤回、无已读对号、超时撤回、删除取消/失败重试及 320px 长文本；截图与结果在 `.artifacts/chat-message-actions/desktop/`。这不替代真实 IM 或 Tauri 剪贴板联调。移动端对应测试见 `mobile/test/core/im/chat_message_actions_test.dart`。

运行 `node tests/e2e/meeting-im-chat.mjs` 会转发到本文开头的完整会议 IM 验收，使用独立 Next 开发服务 `:3141` 和显式 IM/原生替代服务。当前产物在 `.artifacts/meeting-im-integration/`；`.artifacts/meeting-im-chat/` 仅保留早期六项检查的历史产物。

此检查运行真实会议页面组件，不代表真实 IM 服务、对象存储或原生保存文件验收。平台能力缺口、迁移及后端专项验证见 [会议 IM 对接说明](../../docs/meeting-im-chat.md)。

## RTC 释放、媒体预览与聊天身份

`meeting-ready-services.py`、`meeting-ready-desktops.mjs`、`meeting-ready-native.mjs`、`meeting-ready-checks.mjs` 和清理脚本支持 `MEETING_READY_OUTPUT`，默认保留原会议准备测试目录。继续测试时使用新的目录，避免覆盖历史证据。专用客户端保留登录态时，原生脚本会核对并切换到当前目录登记的测试用户。

在真实三端会议准备成功后运行 `node tests/e2e/rtc-release-media-preview.mjs`，检查真实 IM 头像、MP4、无文件名 WAV、播放进度、错误恢复及成员快速重入；再运行 `--visual` 统一采集 1280×800 / 520×760 截图。语音输入走 SDK 公开 API，视频走会议文件控件，素材为合成输入。脚本读取持久化的累计 30 分钟预算，重跑不清零。先执行 `meeting-ready-native.mjs --smoke`，媒体解码错误入口也有单独冒烟步骤。

实际查看截图后，将逐张结论写入产物目录的 `visual-reviews.json`，执行 `node tests/e2e/rtc-release-media-report.mjs` 自动组装报告。保留历史失败；运行清理脚本、关闭本次启动的服务后再次生成报告。开发方案见 [当前功能与限制](../../docs/feature-status.md)。

## 会议聊天生命周期、气泡与附件预览

独立复验可设置 `MEETING_CHAT_OUTPUT` 为产物目录绝对路径，页面、原生、检查、审计和报告脚本均使用该目录；原生服务启动及冒烟另需设置 `MEETING_READY_OUTPUT=<产物目录>/native`。复验结果与来源分支的历史产物分别保存。

产物目录为 `.artifacts/会议聊天生命周期与界面/`。先读取项目规则并探测已有服务与原生登录态；本轮保留 :3118/:39110，页面夹具使用独立 :3144，真实原生开发版使用 :3162。不要替换未知实例或退出未知用户。

1. 在 frontend 依赖就绪后，从仓库根执行 `node tests/e2e/meeting-chat-ui.mjs --smoke`，再执行不带参数的同一脚本。失败夹具先单独冒烟，页面流程覆盖登录、快速会议、收发与回复、系统 tip、长文本、文本/图片/视频预览、加载取消、权限拒绝、文件列表分页滚动、连接失败重试、结束与下一场空态。完整断言通过后才采集 1440×900 / 390×844 截图。视频素材可通过 `MEETING_CHAT_VIDEO` 指向本地 MP4；默认复用已有 640×360 合成验收素材。
2. 按上文原生回归说明启动专用 PostgreSQL :55439，将 `MEETING_READY_OUTPUT` 设置为本目录 `native`，通过 `meeting-ready-services.py --env <server/.env>` 启动修改后的真实服务。若 DNS 被 Fake-IP 接管，只在隔离网关使用已核实公网地址的 `MEETING_READY_DNS_MAP`，保持出站白名单、私网拒绝及 TLS 校验。
3. 在 frontend 执行 `node scripts/build-im-engine.mjs`，启动 Next :3162（`OPENMEETING_NEXT_DIST_DIR=.next-chat-native`、`NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=real`）。本轮复用 `meeting-ui-native-start.mjs --clients` 的三个已有隔离原生调试构建；设置 `MEETING_UI_NATIVE_OUTPUT` 为相同的 `native` 目录。源码改变 Rust/能力权限时应重新构建，不能用缓存构建代替。
4. 先执行 `node tests/e2e/meeting-ready-native.mjs --smoke`，确认真实 API 的故障/恢复分支；再设置 `MEETING_READY_SYNTHETIC=1` 并运行 `node tests/e2e/meeting-chat-native.mjs`。两端使用真实密码登录、Rust IPC、IM 与对象存储，验证双向消息、文本/视频收发预览、403、结束与新场空态。合成设备输入不算硬件通过。浏览器及原生共用持久化的 30 分钟预算，不得清零重跑；超时按要求降级并记录。
5. 原生服务尚在运行且测试账号尚未清理时，执行 `python tests/e2e/meeting-chat-native-audit.py <server/.env>`，核对本次房间群全部解散且实际播放缓存释放。`node tests/e2e/meeting-chat-checks.mjs` 执行类型、单元及独立测试数据库内的后端检查，并删除它创建的契约测试库。
6. 实际查看每张正式截图后写入 `visual-reviews.json`；未查看的截图不能标为通过。原生退出登录、平台清理、停止本次服务和专用数据库后记录 `cleanup.json`，执行 `node tests/e2e/meeting-chat-report.mjs` 从结构化结果生成报告及脚本快照。清理复用 `meeting-ui-native-start.mjs --logout/--stop` 和 `meeting-ready-cleanup.py`；平台清理必须使用本轮出站代理 :3163 及对应内部令牌，不能误连日常环境。
## 文件直传验收

`direct-upload-checks.py` 验证真实 API、PostgreSQL、MinIO 的上传、确认、下载与鉴权；`direct-upload.mjs` 使用已有 Playwright 验证管理端创建版本、两类失败重试、发布、逐字节下载及 1440×960 / 390×844 弹窗。先运行 API 脚本冒烟故障入口，再运行浏览器；调试预算 30 分钟，失败产物保留。`fixtures/direct-upload.py` 仅用于隔离验收，IM、STT 就绪和任务提交是显式替身，不代表真实 ASR、OSS 或原生设备通过。

从根目录准备独立 PostgreSQL 16（127.0.0.1:35461，用户 openmeeting，密码 direct-upload-pg）及项目 MinIO 镜像（127.0.0.1:39361，用户 direct-upload-user，密码 direct-upload-password）；不得使用日常卷或数据库。MinIO 临时挂载使用 `/data:rw,size=1073741824,mode=1777`，兼容镜像的非 root 用户。容器应使用本轮独立名称及标签，结束后只关闭自己创建的资源。

```powershell
.\server\.venv\Scripts\python.exe tests/e2e/fixtures/direct-upload.py # 独立 API 39362；默认产物 .artifacts/direct-upload-20261105
.\server\.venv\Scripts\python.exe tests/e2e/direct-upload-checks.py # 另一个终端：先验证真实存储与失败入口
# 在 server/admin-web 的独立终端启动本轮网页
$env:OPENMEETING_GATEWAY_URL='http://127.0.0.1:39362'
pnpm exec vite --host 127.0.0.1 --port 5186 --strictPort
# 回到根目录运行页面验收
node tests/e2e/direct-upload.mjs # 输出结构化结果，断言通过后统一截图及 trace
.\server\.venv\Scripts\python.exe tests/e2e/direct-upload-report.py # 汇总结果；截图须实际查看后登记 visual-reviews.json
```
