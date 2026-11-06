# 桌面客户端自动更新签名密钥（Tauri Updater）

`src-tauri/signing/updater/` 整个目录由本机初始化脚本生成，包括开发版、测试版、正式版的私钥、公钥、密码与配置；整个目录和 `.env.build.<环境>` 均不提交 Git。本说明保留在生成目录外，便于新用户准备自己的发行环境。

已有构建机继续使用原路径下的本地文件；新构建机应从凭据保管处恢复相应文件。公开仓库的独立发行版使用下方脚本创建自己的签名配置。

> 取消跟踪不会删除历史提交中的密钥。公开发布时应使用不含这些密钥的新历史，或先清理旧历史；不要直接推送仍含密钥的旧分支或标签。
>
> ⚠️ 用户装上某个版本之后，这个版本只认构建时写进去的公钥。
> **私钥一旦丢失，这批用户就再也收不到自动更新**，只能让他们手动下载安装新版本。

这套密钥**只用于自动更新包的签名校验**，和 macOS（Apple Developer ID）、Windows 的系统代码签名证书无关。
系统代码签名证书需要向 Apple 或 CA 申请，不在这里。

## 一条命令初始化

安装 `frontend/` 的锁定依赖后，在该目录执行，将示例网关换成自己的真实 HTTPS 网关：

```powershell
pnpm updater:init --server-url https://meeting.example.com
```

默认一次初始化 `dev/test/prod`，每个环境使用不同的密钥和随机密码，各环境的网关初始设为传入地址。也可分别初始化：

```powershell
pnpm updater:init --env dev --server-url http://127.0.0.1:39110
pnpm updater:init --env test --server-url https://test-meeting.example.com
pnpm updater:init --env prod --server-url https://meeting.example.com
```

每个环境会生成 `meeting-<环境>.key`、`meeting-<环境>.key.pub`、`password.env`、`tauri.updater.json`，并在 `frontend/` 生成 `.env.build.<环境>`。脚本自动写入配套公钥、随机密码、私钥绝对路径和网关地址，不需要手动复制这些内容。只有 dev 允许 HTTP 更新，test/prod 必须传入 HTTPS 网关。

已有完整配置会跳过且不修改；存在部分文件则报错，避免重新生成密钥与旧配置混用。脚本没有强制覆盖选项。要修改已有环境的网关，直接编辑 `.env.build.<环境>`；迁移构建机后也应检查该文件中的私钥绝对路径。

初始化完成后按[桌面构建指南](README.md)运行对应 `tauri:build:dev/test/prod` 命令。脚本不构建安装包、不上传产物，也不会将密码或私钥打印到终端。

## 目录结构

```
signing/updater/
├── dev/
│   ├── meeting-dev.key          # 私钥（已用密码加密，minisign 格式）
│   ├── meeting-dev.key.pub      # 公钥
│   ├── password.env             # 私钥密码：TAURI_SIGNING_PRIVATE_KEY_PASSWORD=...
│   └── tauri.updater.json       # 构建时覆盖 tauri.conf.json 里公钥的配置片段
├── test/                        # 测试版，文件结构同上
└── prod/                        # 正式版，文件结构同上
```

| 环境 | 用途 | 公钥写在哪 |
| --- | --- | --- |
| `dev` | 开发自测包 | `dev/tauri.updater.json`，构建时用 `--config` 覆盖 |
| `test` | 发给测试同事 / 内测用户的包 | `test/tauri.updater.json`，`tauri:build:test` 显式加载 |
| `prod` | 正式发布 | `prod/tauri.updater.json`，`tauri:build:prod` 显式通过 `--config` 加载 |

## 手动生成密钥并配置公钥

已有发行版继续使用原来的密钥，不执行本节。首次创建独立发行版时，在 `frontend/` 中以 PowerShell 执行下面的 `prod` 示例；`dev`、`test` 分别替换目录名和文件名，各环境独立生成一次：

```powershell
New-Item -ItemType Directory -Force src-tauri/signing/updater/prod | Out-Null
if (Test-Path src-tauri/signing/updater/prod/meeting-prod.key) { throw '私钥已存在，请使用原密钥，不要覆盖' }
pnpm tauri signer generate -w src-tauri/signing/updater/prod/meeting-prod.key
```

按交互提示设置私钥密码，不将真实密码写进命令行。命令生成配套的 `meeting-prod.key` 私钥和 `meeting-prod.key.pub` 公钥。

生成后完成以下配置：

1. 在同目录本地创建 `password.env`，写入 `TAURI_SIGNING_PRIVATE_KEY_PASSWORD="<生成时设置的密码>"`，替换占位符并妥善保管；该文件已被忽略。
2. 将 `.key.pub` 文件的完整内容（去掉首尾换行）填入同环境 `tauri.updater.json` 的 `plugins.updater.pubkey`。这里填公钥内容，不填文件路径；保留配置中的其他字段。
3. 基础 `src-tauri/tauri.conf.json` 的公钥留空，构建时通过 `--config` 加载本地生成的环境配置；不将自己的公钥写回公共基础配置。
4. 按[桌面指南](README.md)准备本地 `.env.build.prod`，把 `TAURI_SIGNING_PRIVATE_KEY` 指向新私钥的绝对路径，再运行相应环境的构建命令。

私钥用于给更新包签名，公钥用于客户端验签，二者必须配套，但不需要一起纳入 Git。公钥公开本身没有保密风险；本项目为便于独立部署，统一将整个生成目录排除出 Git。当前 updater 实际读取的是 JSON 配置里的公钥，不会在运行时读取 `.key.pub` 文件。更换公钥代表更换更新信任关系，现有客户端不会自动信任新密钥。

生成方式与公钥配置见 [Tauri 官方更新签名说明](https://v2.tauri.app/plugin/updater/#signing-updates)。

## 构建时选择签名环境

完整 dev / test / prod 构建命令只维护在[桌面指南](README.md)，本页维护密钥和公钥的对应关系。私钥和密码必须与构建内公钥属于同一环境；test 包使用 test 私钥和 `test/tauri.updater.json`。安装包位置见[安装与分发](README.md#3-安装与分发)。

## 手动给文件签名

在 `frontend/` 执行，将文件占位符替换为待签名产物；密码文件来自受控构建环境。

```bash
set -a; source src-tauri/signing/updater/prod/password.env; set +a
pnpm tauri signer sign -f src-tauri/signing/updater/prod/meeting-prod.key <要签名的文件>
```

## 注意事项

GitHub Actions 的网关、公钥与签名探针配置见[发布指南](../docs/releases.md)。未签名测试包显式关闭 updater 产物生成；正式更新包验证公私钥配套后再构建，产物生成后不再修改或重新打包。

- Rust 的 [updates.rs](src-tauri/src/updates.rs) 按包内网关地址构造业务更新端点并传给 updater；静态 `plugins.updater.endpoints` 为空不表示更新未启用。版本发布、灰度及安装包上传见[服务端发布流程](../server/README.md#七客户端升级版本发布)。
- 开发版、测试版、正式版的公钥互不兼容：装了测试版的用户，只能收到用测试版私钥签名的更新。
- **正式版私钥和密码**应备份在密码管理器或加密离线介质中，不以源码仓库作为凭据备份。
- 如果私钥泄露：重新生成一对密钥，发一个手动安装的新版本（内置新公钥）。已安装客户端需要通过手动安装包更换内置公钥。
- 初始化脚本不负责已有发行版的密钥轮换，不要通过删除旧文件来绕过保护。
