## v1.5.6（2025-02-25）

### Bug 修复
- 修复 vhost del 删除站点后未 reload nginx 的问题
- 修复 Binary 安装缺少 init.d/php-fpm 启动脚本
- 修复 Binary 安装从 GitHub 下载 php.ini 国内不可达，改为镜像站 + 内置兜底

### CI 改进
- 修复 release.yml YAML 语法错误
- Release 说明改用 body_path，自动包含更新内容
- 修复 GitHub URL 指向旧账号的问题
