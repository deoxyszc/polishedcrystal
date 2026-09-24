# 粉页布局 JSON 到 ROM

排版器新增“导出ROM布局”。图形RGBA不写入ROM；坐标及绑定进入构建。动态姓名、经验、等级读取游戏RAM，预览示例内容不替换游戏数值。

```sh
python3 tools/zh/runtime_build.py --language zh-Hans --layout /path/summary-pink-rom.json --font /path/font.ttf --licenses /path/licenses --out /path/new-build
```

构建先校验布局，生成 constants/zh_summary_layout.asm，ASM消费者直接引用这些常量；构建目录保存layout-input.json和data/zh/summary_layout_report.json（输入hash与绑定）。默认配置tools/zh/layout_configs/summary_pink.json。

本轮是有限接通，不是所有自由拖动都已适配。经验两行、升级提示、页签及球位置可按支持的8px步长改变。原生立绘、编号、等级、性别、经验条及部分窗口行当前锁定；移动不支持项会报错。字形偏移目前只接受已实现的正文0/4、页签3/4。模板固定，不能把预览例值当译文。粉页已适配边框、底部显示及详情缓存恢复；后续页面仍需独立ROM验收。

已验证只改变JSON经验行X从8到16，重新构建后实际ROM该行精确右移8px，内容逐像素一致。随后恢复确认配置。

## 后续排版工作流程（代理执行）

1. 用当前已验收布局、对应字模和同场景截图生成编辑器。编辑器从summary_layout_config.py读取同一份约束，默认加载绑定模板。
2. 固定元素禁止移动；可动元素只按8px定位；字形偏移、绑定、动态模板不得在预览中任意修改。新增能力先改页面适配器及约束。
3. 在工具中排版并导出ROM布局JSON。测试长名字/大数字需保留数据绑定，不把样例写成运行时文本。
4. 使用runtime_build.py --layout构建，保存输入哈希、ROM/sym/map。
5. 实际ROM检查进入/返回、完整字形、边框、图标、数字，与同场景英文对照。工具效果只是候选；缓存/显隐/VRAM需实际检查。
6. 把通过的JSON保存为页面配置，再更新交接。不得手抄坐标绕过配置。

当前工作流版本锁定模板文字与字形偏移，避免产生不可构建的设计；未来可扩展受控数据样例选择。
