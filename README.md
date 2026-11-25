# Tabby RS 插件索引

Tabby RS 设置页 Plugins 分区 Available 列表读取的签名插件索引，由本仓库构建并发布到 GitHub Pages

## 内容

```
tabby-rs-plugins/
├─ plugins.txt                     # 发布的插件：tabby-rs 仓库 extensions/ 下的目录名，每行一个
├─ scripts/build.sh                # 构建插件、打包并写出 site/
├─ .github/workflows/publish.yml   # 推送 main 或手动触发时构建、签名并发布到 GitHub Pages
└─ site/                           # 构建输出（不入库）
   ├─ index.json                   # 插件列表、版本、包的 sha256 与大小、能力、各语言的描述
   ├─ index.json.minisig           # index.json 的签名（带密钥构建时）
   └─ <id>-<version>.tar.gz        # 插件包
```

- 插件源码在 tabby-rs 仓库的 `extensions/`，本仓库只记录发布哪些插件
- 索引格式与客户端行为见 tabby-rs README「插件索引」

## 本地构建

前置：Rust 1.95.0 与 wasm32-wasip2 target、tabby-rs 仓库的检出

```bash
# 安装 wasm32-wasip2 target
rustup +1.95.0 target add wasm32-wasip2

# 构建，不签名：输出到 site/，Tabby RS 不使用未签名的索引
scripts/build.sh ../tabby-rs

# 构建并用索引私钥签名
INDEX_KEY_FILE=<索引私钥文件> scripts/build.sh ../tabby-rs
```

- 不设置 `BASE_URL` 时，`index.json` 中包的地址是相对 `index.json` 的文件名，包与索引放在同一目录发布

## 发布

1. 在 GitHub 创建公开仓库 `tabby-rs/tabby-rs-plugins` 并推送本仓库（私有仓库的 Pages 需要付费计划）
2. Settings → Pages 的 Source 选 GitHub Actions
3. 设置仓库 secret：
   - `TABBY_PLUGIN_INDEX_KEY`：索引私钥文件的全部内容（公钥已内置在 Tabby RS，key id A75A98047A51A570）
   - `TABBY_RS_TOKEN`：能读取 tabby-rs 仓库的 token（tabby-rs 公开后可删除这一项与 workflow 中的 `token`）
4. 推送 main 或在 Actions 页手动运行 Publish，索引地址为 `https://tabby-rs.github.io/tabby-rs-plugins/index.json`，即 tabby-rs `crates/tabby-app/src/plugin_manager.rs` 的 `DEFAULT_INDEX_URL`

## 添加或更新插件

1. 在 tabby-rs 的 `extensions/<id>/` 修改插件，更新 `extension.toml` 的 `version`；改了文案时在 tabby-rs 中运行 `cargo +1.95.0 xtask plugin-i18n extensions/<id>` 把新原文补进 `locales/*.po` 并翻译（打包时检查这些文件，格式错误时构建失败）
2. 新插件把目录名加入 `plugins.txt`
3. 推送 main，或在 Actions 页手动运行 Publish 并填写 tabby-rs 的分支、tag 或提交

- 索引只保留每个插件的当前版本
