# 桌面端 UI 设计规范（V2 Aurora Dark）

设计语言为 **Aurora Dark**（深空夜幕 + 品牌极光渐变）：深色背景、玻璃质感卡片、品牌极光渐变及柔和光晕。应用只提供深色主题。参考原型为 `design\设计图V2\电脑端\index.html`，使用 Tailwind Play CDN 和 `assets/base.css` 中的 CSS 变量。所有页面必须遵守本规范。

## 品牌
- 名称：`t('common.appName')` → 深应会议。界面文案中不硬编码“深应会议”。
- 标志：使用 `@/components/brand/BrandLogo` 中的 `<BrandLogo />`，加载 `public/brand-logo.png`，不使用其他标志资源。放置在宽 64px 的导航栏顶部。
- 账号入口：导航栏底部使用渐变头像（`bg-brand-gradient`，显示姓名首字母），点击后打开账号菜单（账号设置 / 退出登录）。V2 不显示底部服务端状态栏。
- 语言切换：`<LanguageSwitcher variant="segmented|toggle" />` 放在“设置 → 通用”中，不放在应用外壳中。

## 颜色（使用 Tailwind 主题标记，不用原始十六进制颜色或 gray-xxx / blue-xxx 表达界面语义）
| 用途 | 类名 |
|---|---|
| 应用背景 | `bg-background`（#0B0D13 深空夜幕），内容后方叠加固定极光光晕：靛色、青色、蓝色三个低透明度径向渐变，仅在外壳层渲染一次，使用 `pointer-events-none` |
| 卡片、面板 | `bg-card`（#14161F），或玻璃效果：`bg-white/[0.04] border border-white/[0.07] backdrop-blur-md` + `shadow-card` |
| 导航栏 | `bg-sidebar`（#080A10，比主背景更深）+ `border-r border-white/[0.05]` |
| 主要操作、链接、选中导航 | `bg-primary text-primary-foreground`（#3B82F6）、`text-primary` |
| 选中及悬停底色 | `bg-accent text-accent-foreground`（深蓝底色），玻璃表面中可使用 `bg-white/[0.07]` |
| 正文、次要文字 | `text-foreground` / `text-muted-foreground`；仅在玻璃表面内按原型使用 `text-white/xx` 透明度级别 |
| 输入框、标签等浅填充 | `bg-muted`、`bg-secondary` |
| 危险、成功、警告 | `destructive`、`success`、`warning`，例如 `text-destructive`、`bg-success/10 text-success` |
| 品牌强调（快捷入口标签、头像、选中导航、主要操作按钮） | `bg-brand-gradient`、`brand-50…900`、`brand-cyan`（#4CC3FF） |
录音进行中仅录制/停止控件使用 `destructive`（红色）。

**品牌色板（V2 现代亮蓝）：**主色为 `brand-500 #3B82F6`，另有 `brand-600 #2F6AE8`、`brand-cyan #4CC3FF`；渐变 `linear-gradient(135deg, #6366F1 0%, #3B82F6 52%, #22D3EE 100%)` 对应 `bg-brand-gradient`。

**阴影：**`shadow-card` 用于柔和深阴影，`shadow-elevated` 用于弹窗及浮层，`shadow-glow` 用于品牌按钮悬停时的蓝色光晕 `rgba(59,130,246,0.38)`。

## 形状、间距与排版
- 圆角基准为 `--radius: 0.875rem`；各级为 `xl = base+4px`、`lg = base`、`md = base-2px`、`sm = base-4px`。入口块及主视觉卡片使用 `rounded-2xl`，按钮及输入框使用 `rounded-lg`，标签及徽章使用 `rounded-full`。
- 页面内边距使用 `p-6`，首页主视觉区域使用 `px-12 pt-12`；卡片内边距使用 `p-5`，间距使用 `gap-3`/`gap-4`。分区标题使用 `text-[13px] font-medium text-muted-foreground`，页面标题使用 `text-xl font-semibold`，主视觉日期使用 `text-[36px] font-semibold`。
- 字体使用 `font-sans`（Source Sans 3 + PingFang SC / Microsoft YaHei）。中英文均须适配，不给文字设置固定宽度；允许换行，或使用 `truncate` 并提供 `title`。
- 图标使用 `lucide-react`，行内尺寸为 16px（`h-4 w-4`）；导航项上下排列图标与 10px 标签。

## 布局
- 应用外壳：左侧固定导航栏（w-16、`bg-sidebar`），顶部为标志，中间为首页/会议/录制/设置导航（图标加小标签，选中时显示 `bg-brand-gradient` 光晕块），底部为渐变头像。内容区使用 `ml-16` 和 `bg-background`，并叠加极光氛围层。
- 路由：`#/home`、`#/meetings`、`#/meeting/:id`、`#/record`、`#/schedule`、`#/join`、`#/room/:code`、`#/settings`。
- 内容列宽：首页 `max-w-[920px]`，会议列表及详情 `max-w-5xl`，设置页 `max-w-6xl`，均居中。
- **会议房间 `#/room/:code` 使用全屏沉浸布局**：隐藏导航栏且不留外边距；顶部显示标题、可点击会议号、加密徽章及计时器；中间为带麦克风状态的 2–6 个头像视频格；底部为麦克风/摄像头/共享/成员/更多/离会工具栏；右侧提供成员滑出面板和聊天面板。
- 首页：主视觉区域显示时段问候和大日期；左列为 2×2 玻璃快捷入口卡片（加入会议/快速会议/预定会议/录音转写）及今日会议列表，右列为最近会议纪要列表。
- 弹窗：居中深色模态框（`shadow-elevated`）。入会包含六位分段会议号输入（2×3，自动跳格并支持粘贴）及昵称；预定包含独立日历（月份导航及今天/明天/后天快捷项）、固定冒号的两位 HH:mm 编辑和可滚动的每刻钟下拉选项，以及时长、密码和提醒开关。
- 空态：简洁线条插画（月亮与窗口意象），或强调色圆形底的居中图标，配一行说明和主要操作。
- 提示：使用 `sonner` 的 `toast.*`，在右下角显示本地化文案。

## 动效
- 入场：首页使用 `rise-in` 交错动画（rise-1…rise-4，0.55s cubic-bezier）。
- 悬停：快捷入口上移 `-translate-y-1` 并显示光晕；列表行提亮边框和背景；按钮使用 `hover:brightness-110 active:scale-95`。
- 路由切换使用 0.5s 向上淡入动画，录音波形使用脉冲环动画。

## 组件
使用 `@/components/ui/*` 中的 shadcn 基础组件（Button、Input、Select、Dialog、Tabs、Switch、Tooltip 等），按上述主题标记设置样式；`className` 仅用于布局。共享基础组件由应用外壳维护方负责，不另行派生副本。玻璃表面和渐变标签可在本地组合，但颜色、阴影及圆角必须使用主题标记。

## 国际化规则（必须遵守）
- 所有界面文案通过 `t()` 获取：组件中使用 `const t = useT()`（或 `useI18n()`），React 之外使用 `import { t } from '@/i18n'`。
- 在 `src/i18n/messages/<ns>.ts` 的命名空间文件中通过 `defineMessages({ en, 'zh-CN' })` 增加键，提供两种语言且键结构完全一致，由类型检查验证。使用 `{name}` 占位符，不拼接字符串。
- 保存、取消、重试、加载等共用词语使用 `common.*`，不重复定义。
- 日期和时间使用 `toLocaleString(locale)` / `Intl.DateTimeFormat(locale, …)`，其中 `locale` 来自 `useI18n()`。
- 不翻译日志（`console.*`）、事件名、命令名和服务端数据（会议标题、转写、总结）。

## 原型与实际实现
原型（`设计图V2/电脑端`）使用 `localStorage` 中的模拟数据渲染（`dr_meetings_desktop`、硬编码的张伟及用户池、模拟房间成员）。实际应用继续使用既有数据源（Tauri 命令和服务端 API），不得复制原型的数据库层。功能范围及缺口维护在 [DESIGN_V2_REQUIREMENTS.md](DESIGN_V2_REQUIREMENTS.md)。
