# 用 GitHub 编译 HH500V 固件（手把手）

> 目标：**24.10.6 + 全插件 + 你的 ZeroTier GUI**，编译成可直接刷的 `factory.bin`。
> 全程在网页上操作，不需要装 Linux、不需要会用 git 命令。

---

## 准备

| 需要 | 说明 |
|---|---|
| GitHub 账号 | 免费注册：https://github.com/signup |
| 本机文件 | `hh500v-firmware.zip`（我已给你）→ **解压**到一个文件夹 |
| 时间 | 编译约 **60~120 分钟**（GitHub 免费额度内） |

---

## 方法 0：真·一键（推荐，3 分钟装好工具后一条命令）

> 如果你不想手动点网页，用这个。

1. 装两个工具（只需一次）：
   - **Git for Windows**：https://git-scm.com/download/win
   - **GitHub CLI**：`winget install GitHub.cli`（或 https://cli.github.com/）
2. 登录一次：打开终端，运行

   ```powershell
   gh auth login
   ```
   （选 GitHub.com → HTTPS → 浏览器登录）

3. 解压 `hh500v-firmware.zip`，**进入该文件夹**，右键「在终端中打开」，运行：

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\publish-and-run.ps1
   ```

4. 它会自动：
   - 建公开仓库
   - 推送代码
   - **触发 24.10.6 + full 编译**
   - 打印运行链接

5. 等 60~120 分钟后，在链接页面底部 **Artifacts** 下载。

> Linux / WSL 用户：`bash publish-and-run.sh`（同样效果）

---

## 第一步：创建仓库

1. 登录 GitHub，点右上角 **+ → New repository**
2. 填写：
   - **Repository name**：`hh500v-firmware`（随便起）
   - **Public**（选公开：Actions 分钟数免费无限；私有也有 2000 分钟/月，够用）
   - 勾选 **Add a README file**（随意）
3. 点 **Create repository**

---

## 第二步：上传文件（两种方法，选一种）

### 方法 A：网页上传（最简单）

1. 在仓库页面点 **Add file → Upload files**
2. 打开你解压出来的 `hh500v-firmware` 文件夹，**全选里面的所有文件和文件夹**（包括隐藏的 `.github` 文件夹！）
3. **拖进网页的拖拽区**
   - ⚠️ 关键：`.github` 文件夹必须一起传（Windows 资源管理器默认隐藏它 → 先开"显示隐藏项目"）
4. 下方填提交信息（随便写），点 **Commit changes**

> 如果 `.github` 传不上去（网页有时忽略点开头的文件夹），改用方法 B。

### 方法 B：GitHub Desktop（推荐，最稳）

1. 下载安装 **GitHub Desktop**：https://desktop.github.com
2. 登录你的账号
3. 菜单 **File → Add local repository** → 选你解压出的 `hh500v-firmware` 文件夹
   - 若提示"不是 git 仓库"，点 **create a repository** → Create
4. 点 **Publish repository**（取消勾选 "Keep this code private" 就是公开）
5. 完成，网页上就能看到你的仓库

---

## 第三步：启用 Actions

1. 进仓库 → 点顶部 **Actions**
2. 第一次会看到提示：**"Workflows aren't being run on this repository"** →
   点 **I understand my workflows, go ahead and enable them**
3. 左侧列表里应出现 **Build HH500V ImmortalWrt**

---

## 第四步：开始编译

1. 点左侧 **Build HH500V ImmortalWrt**
2. 右侧点 **Run workflow** 按钮
3. 两个下拉：
   - **firmware version**：选 **`24.10.6`**
   - **plugin set**：选 **`full`**（全插件：openclash/passwall2/mihomo/UU/daed/tailscale/zerotier/QModem）
4. 点绿色 **Run workflow**

---

## 第五步：等（60~120 分钟）

- 刷新页面，会看到一条运行记录，点进去看实时日志；
- 状态：🟡 进行中 → ✅ 成功（绿色对勾）/ ❌ 失败（红叉）

### 各阶段在干什么（看日志对照）

| 阶段 | 内容 | 正常耗时 |
|---|---|---|
| Clone ImmortalWrt | 拉 24.10.6 源码（commit `cf234f8de6d5`） | 1~3 分 |
| Backport HH500V device | 打 3 个设备补丁 | 1 分 |
| Backport MHI IRQ fix to 6.6 | 打 706 补丁 | 10 秒 |
| Install custom packages | 装我写的 ZeroTier GUI | 5 秒 |
| Write feeds.conf | 配置官方 + 第三方 feed | 10 秒 |
| Configure | 生成 .config | 1~2 分 |
| Download | 下载所有源码包 | 10~30 分 |
| **Build** | **编译（最久）** | **40~90 分** |
| Collect / Upload | 打包产物 | 1 分 |

---

## 第六步：下载固件

编译成功后：

1. 在该次运行页面**最下方**找到 **Artifacts**
2. 点 **hh500v-24.10.6-full** 下载（zip）
3. 解压，你会得到：
   - `...-squashfs-factory.bin` ← **首刷用这个**
   - `...-squashfs-sysupgrade.bin` ← 以后升级用
   - `...-initramfs-uImage.itb` ← 想先验证用这个（不写 flash）

---

## 第七步：刷机

### 方式 1：原厂固件 SSH（推荐）

```bash
# 1) 连上原厂系统（HH500V 原厂：root，端口 42000，无密码）
ssh -p 42000 root@<设备IP>

# 2) 传固件
scp -P 42000 ...-squashfs-factory.bin root@<设备IP>:/tmp/factory.bin

# 3) 刷（-n 表示不保留配置）
ssh -p 42000 root@<设备IP> "sysupgrade -n /tmp/factory.bin"
```

### 方式 2：先跑 initramfs 验证（更安全，不写 flash）

```
U-Boot/TFTP 引导 initramfs 镜像 → 看串口/网口/5G 是否正常 → 再刷 factory.bin
```

---

## 第八步：刷完检查（5 分钟）

| 检查 | 命令/位置 |
|---|---|
| 5G 上网 | LuCI 状态页看接口是否拿到 IP；`ping 223.5.5.5` |
| SIM 卡 | `ls /dev/wwan* /dev/cdc-wdm*`；QModem → 总览 |
| WiFi | `iwinfo` 看 Tx-Power（应 >20dBm）+ 手机测速 |
| 网口 | 有线接 PC，测 500Mbps |
| **ZeroTier GUI** | LuCI → **服务 → ZeroTier**（我写的页面） |
| 代理 | LuCI → 服务 → OpenClash / PassWall（**同时只开一个**） |

---

## 常见问题

| 现象 | 原因 | 处理 |
|---|---|---|
| Actions 里没有 workflow | `.github/workflows/build.yml` 没上传成功 | 用 GitHub Desktop 重传，确认网页上能看到该文件 |
| `Backport ... 冲突` | 24.10.6 与补丁有冲突 | 把日志发我，我改补丁 |
| 某插件 `build failed` | 第三方包在 24.10.6 上不兼容 | 从 `configs/hh500v-24.10.config` 删掉该包重跑 |
| 编译超时 | GitHub 单任务上限 6 小时（我们设了 360 分钟） | 正常不会超；超了说明某包装死，看日志 |
| 下载 artifact 是空的 | 编译失败但没报错 | 看 `Collect` 步骤日志 |

---

## 失败时把什么发我

1. 失败的**步骤名**（如 "Build"）
2. 该步骤日志的**最后 30~50 行**（尤其是 `error:` / `Error 1` 附近）
3. 若是 backport 失败：`git status` 的输出

我拿到就能改配置/补丁，你重新 Run 一次即可。

---

## 费用与限制

| 项 | 说明 |
|---|---|
| 公开仓库 | Actions **免费无限** |
| 私有仓库 | 免费 2000 分钟/月（一次编译约 60~120 分钟） |
| Artifacts 保留 | 默认 **90 天**，过期要重编 |
| 并发 | 免费账号同时 1~2 个任务 |
