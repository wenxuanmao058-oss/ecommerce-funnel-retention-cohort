# 用户行为分析：漏斗 · 留存 · Cohort

基于 Kaggle 电商用户行为数据集，围绕"用户从进入平台到留存/流失"这一完整生命周期，构建漏斗转化、留存、Cohort 三层分析框架，定位平台转化与留存问题的具体节点。

📄 完整业务结论见 [`用户行为分析_业务结论.md`](./用户行为分析_业务结论.md)

---

## 数据说明

数据集：Kaggle 电商行为数据集，6 张表

| 表名 | 说明 |
|---|---|
| `users` | 用户基础信息、注册日期 |
| `sessions` | 用户会话记录 |
| `interactions` | 用户行为日志（view / click / add_to_cart / add_to_wishlist / remove_from_cart / remove_from_wishlist），约 10 万条 |
| `purchases` | 购买记录 |
| `reviews` | 商品评论 |
| `products` | 商品信息 |

数据清洗：`products.rating_avg` 缺失 548 条（商品未被评分，属正常业务状态，保留不做填充）；`reviews.purchase_id` 缺失 200 条（验证为"未验证购买"的正常评论，保留）。

## 技术栈

- **MySQL**：数据清洗、字段类型规范化、索引优化、前置聚合（漏斗数据 UNION ALL 拼接、视图封装）
- **Python**：
  - `pandas` + `sqlalchemy`：从 MySQL 读取聚合结果，做留存计算、Cohort 透视
  - `plotly`（`go.Funnel`）：漏斗转化可视化，交互式展示每层绝对值、相对总体占比、相对上一步占比
  - `seaborn`（`heatmap`）：Cohort 月度留存热力图

## 分析框架

```
SQL 聚合 → Python 深度计算 → 可视化
```

| 分析模块 | SQL 负责 | Python 负责 |
|---|---|---|
| 漏斗转化 | 按 interaction_type 分组统计去重用户数，UNION ALL 拼接为漏斗视图 `v_funnel_summary` | 计算相对上一步 / 相对总体转化率，`go.Funnel` 可视化 |
| 留存分析 | JOIN `users` 与 `interactions`，导出注册日期 + 行为日期明细 | 计算 `days_since_signup`，按 Day 1/7/14/30 节点统计精确匹配留存率（总留存 / 有效留存两个口径） |
| Cohort 分析 | 同上明细数据 | 按注册月份分组，`pivot_table` 构建留存矩阵，`seaborn.heatmap` 可视化 |

## 已做的工程优化

- 建立索引（`idx_user_id`、`idx_interaction_type`、`idx_timestamp`），实测查询耗时从 0.735s / 0.672s 降至 0.531s，用 `EXPLAIN` 验证优化前后执行计划差异
- `interactions` 表字段类型规范化（varchar/decimal 定长），减少存储与查询开销
- 漏斗聚合逻辑封装为视图 `v_funnel_summary`，避免重复解析同一段 SQL

## 已知局限

- 留存率分母为"有行为记录的用户"，非全部注册用户，两种口径对应不同业务问题，详见结论文档
- Cohort 矩阵中的空值需区分"观测窗口不足"与"真实流失"两种性质，不能直接等同处理
- 未按用户来源渠道 / 首单类型做分层留存对比，是后续可扩展的方向

## 项目文件

```
├── 用户行为分析_业务结论.md   # 完整业务结论与图表解读
├── funnel_retention_cohort.sql   # SQL 聚合与视图定义
└── analysis.ipynb                # Python 计算与可视化
```
