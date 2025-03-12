# PenNote English 数据模型文档

## LearningStats（学习统计）
- `correctCount`: Int16 - 正确答题数
- `date`: Date - 统计日期
- `id`: UUID - 统计记录唯一标识
- `masteredCount`: Int16 - 已掌握单词数
- `newWordsCount`: Int16 - 新学单词数
- `totalTime`: Double - 总学习时间（单位：分钟）

## Word（单词）
### 基本信息
- `id`: UUID - 单词唯一标识
- `english`: String - 英文单词
- `chinese`: String - 中文释义
- `phonetic`: String - 音标
- `partOfSpeech`: String - 词性
- `importance`: Int16 - 重要程度（0：普通词汇，1：重点词汇，2：核心词汇/高频词，3：特别重要）
- `createdAt`: Date - 创建时间
- `updatedAt`: Date - 更新时间

### 教材信息
- `grade`: Int16? - 年级（1-6年级）
- `semester`: Int16? - 学期（1-2学期）
- `unit`: Int16? - 单元编号
- `lesson`: String? - 课文名称/编号

### 学习辅助
- `etymology`: String? - 词源（可选）
- `example`: String? - 例句（可选）
- `exampleTranslation`: String? - 例句翻译（可选）
- `memoryTips`: String? - 记忆技巧（可选）
- `structure`: String? - 词形结构（可选）

### 关系
- `wordResults`: Relationship - 练习结果集合

## WordResult（单词练习结果）
### 基本信息
- `id`: UUID - 结果唯一标识
- `date`: Date - 练习日期
- `isCorrect`: Bool - 是否正确

### 错误分析
- `errorTypes`: [String]? - 错误类型列表（用于记录拼写错误类型）

### 关系
- `word`: Relationship - 关联的单词（多对一关系）

## 关系说明
Word ←→ WordResult：一对多关系
- 一个单词可以有多个练习结果
- 每个练习结果对应一个单词
- 删除单词时级联删除相关练习结果