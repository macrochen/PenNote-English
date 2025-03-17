import re
import csv
import os
from pathlib import Path
import genanki
import random
import requests
from bs4 import BeautifulSoup
import time


def parse_markdown_table(markdown_file):
    words = []
    with open(markdown_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 确保至少有表头和分隔行
    if len(lines) < 3:
        return words
    
    # 跳过表头和分隔行（前两行）
    data_lines = lines[2:]
    
    for line in data_lines:
        line = line.strip()
        # 跳过空行或分隔行（只包含 | 和 - 的行）
        if not line or not '|' in line or line.replace('|', '').replace('-', '').replace(' ', '') == '':
            continue
            
        # 分割每一行并清理空白
        parts = [part.strip() for part in line.split('|')]
        # 移除首尾空字符串（由于行首尾的 | 符号导致）
        if parts and parts[0] == '':
            parts = parts[1:]
        if parts and parts[-1] == '':
            parts = parts[:-1]
            
        # 确保有足够的列
        if len(parts) < 12:
            continue
            
        # 验证这是否是有效的数据行（第一列应该是英文单词，不是分隔符）
        if parts[0].replace('-', '') == '':
            continue
            
        word = {
            'english': parts[0],
            'pronunciation': parts[1],
            'part_of_speech': parts[2],
            'chinese': parts[3],
            'importance': parts[4],
            'grade': parts[5],
            'semester': parts[6],
            'unit': parts[7],
            'example': parts[8],
            'example_translation': parts[9],
            'etymology': parts[10],
            'memory_tip': parts[11]
        }
        words.append(word)
    
    return words


# 添加下载音频的函数
def download_audio(word, output_dir):
    """从 Cambridge Dictionary 下载单词的音频文件，如果已存在则直接使用"""
    # 跳过包含空格或特定词组的情况
    if ' ' in word or word.lower() in ['from', 'to', 'in', 'on', 'at', 'for', 'with', 'by']:
        return None
    
    os.makedirs(output_dir, exist_ok=True)
    
    # 检查音频文件是否已存在
    uk_audio_file = f"{word}_uk.mp3"
    us_audio_file = f"{word}_us.mp3"
    uk_audio_path = os.path.join(output_dir, uk_audio_file)
    us_audio_path = os.path.join(output_dir, us_audio_file)
    
    existing_files = []
    if os.path.exists(uk_audio_path):
        print(f"✓ 使用已存在的英式发音: {uk_audio_file}")
        existing_files.append(uk_audio_file)
    if os.path.exists(us_audio_path):
        print(f"✓ 使用已存在的美式发音: {us_audio_file}")
        existing_files.append(us_audio_file)
    
    # 如果两个音频文件都存在，直接返回
    if len(existing_files) == 2:
        return existing_files
      
    return None

    # 如果没有完整的音频文件，则下载缺失的部分
    base_url = "https://dictionary.cambridge.org/dictionary/english/"
    url = base_url + word
    max_retries = 3
    retry_delay = 2

    # 原有的下载逻辑保持不变，但只下载缺失的音频
    for attempt in range(max_retries):
        try:
            print(f"正在下载 {word} 的音频（尝试 {attempt + 1}/{max_retries}）...")
            response = requests.get(
                url, 
                headers={
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
                    'Accept-Language': 'en-US,en;q=0.5',
                },
                timeout=10
            )
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')
            
            # 查找英式发音和美式发音
            uk_audio_element = soup.find('source', attrs={'type': 'audio/mpeg', 'src': lambda x: x and 'uk_pron' in x})
            us_audio_element = soup.find('source', attrs={'type': 'audio/mpeg', 'src': lambda x: x and 'us_pron' in x})

            audio_files = []
            
            # 下载英式发音
            if uk_audio_element:
                uk_audio_url = "https://dictionary.cambridge.org" + uk_audio_element['src']
                uk_audio_filepath = os.path.join(output_dir, f"{word}_uk.mp3")
                if download_file(uk_audio_url, uk_audio_filepath):
                    print(f"✓ 成功下载 {word} 的英式发音")
                    audio_files.append(f"{word}_uk.mp3")

            # 下载美式发音
            if us_audio_element:
                us_audio_url = "https://dictionary.cambridge.org" + us_audio_element['src']
                us_audio_filepath = os.path.join(output_dir, f"{word}_us.mp3")
                if download_file(us_audio_url, us_audio_filepath):
                    print(f"✓ 成功下载 {word} 的美式发音")
                    audio_files.append(f"{word}_us.mp3")

            if audio_files:
                return audio_files
            else:
                print(f"✗ 找不到 {word} 的音频链接")
                return None

        except requests.RequestException as e:
            print(f"✗ 下载失败 ({attempt + 1}/{max_retries}): {str(e)}")
            if attempt < max_retries - 1:
                print(f"等待 {retry_delay} 秒后重试...")
                time.sleep(retry_delay)
                retry_delay *= 2
            continue
        except Exception as e:
            print(f"✗ 未知错误: {str(e)}")
            return None

    print(f"✗ {word} 的音频下载失败，已达到最大重试次数")
    return None

def download_file(url, filepath):
    """下载文件到指定路径"""
    try:
        response = requests.get(
            url, 
            stream=True, 
            headers={
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': '*/*',
                'Accept-Language': 'en-US,en;q=0.5',
                'Referer': 'https://dictionary.cambridge.org/',
            },
            timeout=10
        )
        response.raise_for_status()
        
        with open(filepath, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        return True
        
    except Exception as e:
        print(f"✗ 文件下载失败: {str(e)}")
        return False

def generate_anki_cards(words, output_file):
    model = genanki.Model(
        random.randrange(1 << 30, 1 << 31),
        '英语词汇卡',
        fields=[
            {'name': 'sort_field'},  # 添加排序字段
            {'name': 'english'},
            {'name': 'pronunciation'},
            {'name': 'part_of_speech'},
            {'name': 'chinese'},
            {'name': 'importance'},
            {'name': 'grade'},
            {'name': 'semester'},
            {'name': 'unit'},
            {'name': 'example'},
            {'name': 'example_translation'},
            {'name': 'etymology'},
            {'name': 'memory_tip'},
        ],
        templates=[
            {
                'name': '英语词汇卡',
                'qfmt': '''
                <div class="card-container front-container">
                  <div class="front-content">
                    <div class="word-badge">释义</div>
                    <div class="word">{{chinese}}</div>
                    <div class="part-of-speech">{{part_of_speech}}</div>
                  </div>
                </div>
                ''',
                'afmt': '''
                <div class="card-container back-container">
                  <div class="header">
                    <div class="word">{{english}}</div>
                    <div class="pronunciation-container">
                        <span class="pronunciation">{{pronunciation}}</span>
                        <div class="audio-controls">
                            <span class="audio-uk">{{audio}}</span>
                        </div>
                    </div>
                  </div>
                  
                  <div class="main-content">
                    <div class="meaning-section">
                      <div class="meaning">
                        <span class="part-of-speech">{{part_of_speech}}</span>
                        <span class="chinese">{{chinese}}</span>
                      </div>
                      <div class="tag-container">
                        <span class="tag importance-tag {{importance}}">{{importance}}</span>
                        <span class="tag source-tag">{{grade}}年级 {{semester}}学期 {{unit}}单元</span>
                      </div>
                    </div>
                    
                    <div class="example-section">
                      <div class="example">{{example}}</div>
                      <div class="example-translation">{{example_translation}}</div>
                    </div>
                    
                    <div class="info-section">
                      <div class="info-item etymology">
                        <div class="info-icon">🔍</div>
                        <div class="info-content">
                          <div class="info-label">词形结构</div>
                          <div class="info-text">{{etymology}}</div>
                        </div>
                      </div>
                      
                      <div class="info-item memory-tip">
                        <div class="info-icon">💡</div>
                        <div class="info-content">
                          <div class="info-label">记忆技巧</div>
                          <div class="info-text">{{memory_tip}}</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                '''
            }
        ],
        css='''
/* 全局样式 */
@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap');

.card {
  font-family: 'Nunito', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  font-size: 16px;
  line-height: 1.6;
  text-align: left;
  color: #333;
  background: #f5f7fa;
  margin: 0;
  padding: 0;
}

.card-container {
  max-width: 600px;
  margin: 0 auto;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

/* 正面卡片样式 */
.front-container {
  background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
  min-height: 320px;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 30px;
}

.front-content {
  text-align: center;
}

.word-badge {
  display: inline-block;
  background-color: rgba(255, 255, 255, 0.2);
  color: white;
  font-size: 14px;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 20px;
  margin-bottom: 20px;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.front-container .word {
  font-size: 48px;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.15);
  letter-spacing: 1px;
}

/* 背面卡片样式 */
.back-container {
  background-color: white;
}

/* 头部区域 */
.header {
  background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
  color: white;
  padding: 20px 25px;
  text-align: center;
  position: relative;
}

.header .word {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 5px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.15);
}

.header .pronunciation {
  font-size: 18px;
  opacity: 0.9;
  font-weight: 400;
}

/* 主要内容区域 */
.main-content {
  padding: 25px;
}

/* 词义部分 */
.meaning-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.meaning {
  font-size: 22px;
  margin-bottom: 10px;
  flex: 1;
  min-width: 200px;
}

.part-of-speech {
  color: #6a11cb;
  font-weight: 700;
  margin-right: 8px;
  background-color: #f3e5ff;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.9em;
  text-transform: lowercase;
  letter-spacing: 0.5px;
}

.chinese {
  color: #333;
  font-weight: 600;
}

/* 标签容器 */
.tag-container {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 5px;
}

.tag {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.importance-tag {
  background-color: #f8f9fa;
}

.重点 {
  background-color: #fff0f0;
  color: #e53935;
  border: 1px solid #ffcdd2;
}

.普通 {
  background-color: #f1f8e9;
  color: #7cb342;
  border: 1px solid #dcedc8;
}

.source-tag {
  background-color: #e3f2fd;
  color: #1976d2;
  border: 1px solid #bbdefb;
}

/* 例句部分 */
.example-section {
  background-color: #f8f9fa;
  border-radius: 12px;
  padding: 15px 20px;
  margin: 20px 0;
  position: relative;
  border-left: 4px solid #2575fc;
}

.example {
  color: #333;
  font-style: italic;
  margin-bottom: 8px;
  font-weight: 500;
}

.example-translation {
  color: #666;
  font-size: 15px;
}

/* 信息部分 */
.info-section {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-top: 20px;
}

.info-item {
  display: flex;
  gap: 15px;
  padding: 12px 15px;
  border-radius: 12px;
  background-color: #f8f9fa;
  transition: all 0.2s ease;
}

.info-item:hover {
  background-color: #f1f1f1;
  transform: translateY(-2px);
}

.etymology {
  border-left: 3px solid #9c27b0;
}

.memory-tip {
  border-left: 3px solid #ff9800;
}

.info-icon {
  font-size: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.info-content {
  flex: 1;
}

.info-label {
  font-size: 14px;
  font-weight: 600;
  color: #666;
  margin-bottom: 3px;
}

.info-text {
  color: #333;
}


/* 音频控制样式 */
.pronunciation-container {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
}

.audio-controls {
    display: flex;
    gap: 8px;
}

.audio-uk span, .audio-us span {
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 4px 8px;
    border-radius: 4px;
    background: rgba(255, 255, 255, 0.2);
    transition: all 0.2s ease;
}

.audio-uk span:hover, .audio-us span:hover {
    background: rgba(255, 255, 255, 0.3);
}

/* 替换音频图标为喇叭 */
.audio-uk span:before, .audio-us span:before {
    content: "🔊";
    font-size: 16px;
}
'''
    )

    # 创建音频目录
    audio_dir = Path(output_file).parent / 'audio'
    audio_dir.mkdir(parents=True, exist_ok=True)

    # 修改模型定义，添加音频字段
    model = genanki.Model(
        random.randrange(1 << 30, 1 << 31),
        '英语词汇卡',
        fields=[
            {'name': 'sort_field'},
            {'name': 'english'},
            {'name': 'pronunciation'},
            {'name': 'part_of_speech'},
            {'name': 'chinese'},
            {'name': 'importance'},
            {'name': 'grade'},
            {'name': 'semester'},
            {'name': 'unit'},
            {'name': 'example'},
            {'name': 'example_translation'},
            {'name': 'etymology'},
            {'name': 'memory_tip'},
            {'name': 'audio'},  # 添加音频字段
        ],
        templates=[
            {
                'name': '英语词汇卡',
                'qfmt': '''
                <div class="card-container front-container">
                  <div class="front-content">
                    <div class="word-badge">释义</div>
                    <div class="word">{{chinese}}</div>
                    <div class="part-of-speech">{{part_of_speech}}</div>
                  </div>
                </div>
                ''',
                'afmt': '''
                <div class="card-container back-container">
                  <div class="header">
                    <div class="word">{{english}}</div>
                    <div class="pronunciation-container">
                        <span class="pronunciation">{{pronunciation}}</span>
                        <div class="audio-button">{{audio}}</div>
                    </div>
                  </div>
                  
                  <div class="main-content">
                    <div class="meaning-section">
                      <div class="meaning">
                        <span class="part-of-speech">{{part_of_speech}}</span>
                        <span class="chinese">{{chinese}}</span>
                      </div>
                      <div class="tag-container">
                        <span class="tag importance-tag {{importance}}">{{importance}}</span>
                        <span class="tag source-tag">{{grade}}年级 {{semester}}学期 {{unit}}单元</span>
                      </div>
                    </div>
                    
                    <div class="example-section">
                      <div class="example">{{example}}</div>
                      <div class="example-translation">{{example_translation}}</div>
                    </div>
                    
                    <div class="info-section">
                      <div class="info-item etymology">
                        <div class="info-icon">🔍</div>
                        <div class="info-content">
                          <div class="info-label">词形结构</div>
                          <div class="info-text">{{etymology}}</div>
                        </div>
                      </div>
                      
                      <div class="info-item memory-tip">
                        <div class="info-icon">💡</div>
                        <div class="info-content">
                          <div class="info-label">记忆技巧</div>
                          <div class="info-text">{{memory_tip}}</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                '''
            }
        ],
        css='''
/* 全局样式 */
@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap');

.card {
  font-family: 'Nunito', 'PingFang SC', 'Microsoft YaHei', sans-serif;
  font-size: 16px;
  line-height: 1.6;
  text-align: left;
  color: #333;
  background: #f5f7fa;
  margin: 0;
  padding: 0;
}

.card-container {
  max-width: 600px;
  margin: 0 auto;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

/* 正面卡片样式 */
.front-container {
  background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
  min-height: 320px;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 30px;
}

.front-content {
  text-align: center;
}

.word-badge {
  display: inline-block;
  background-color: rgba(255, 255, 255, 0.2);
  color: white;
  font-size: 14px;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 20px;
  margin-bottom: 20px;
  letter-spacing: 1px;
  text-transform: uppercase;
}

.front-container .word {
  font-size: 48px;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 10px rgba(0, 0, 0, 0.15);
  letter-spacing: 1px;
}

/* 背面卡片样式 */
.back-container {
  background-color: white;
}

/* 头部区域 */
.header {
  background: linear-gradient(135deg, #6a11cb 0%, #2575fc 100%);
  color: white;
  padding: 20px 25px;
  text-align: center;
  position: relative;
}

.header .word {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 5px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.15);
}

.header .pronunciation {
  font-size: 18px;
  opacity: 0.9;
  font-weight: 400;
}

/* 主要内容区域 */
.main-content {
  padding: 25px;
}

/* 词义部分 */
.meaning-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.meaning {
  font-size: 22px;
  margin-bottom: 10px;
  flex: 1;
  min-width: 200px;
}

/* 正面卡片词性样式 */
.front-container .part-of-speech {
  color: white;
  font-weight: 700;
  font-size: 24px;
  margin-top: 15px;
  background: rgba(255, 255, 255, 0.2);
  padding: 5px 15px;
  border-radius: 8px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

/* 背面卡片词性样式 */
.part-of-speech {
  color: white;
  font-weight: 700;
  font-size: 20px;
  margin-right: 12px;
  background: #6a11cb;
  padding: 4px 12px;
  border-radius: 6px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.chinese {
  color: #333;
  font-weight: 600;
}

/* 标签容器 */
.tag-container {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 5px;
}

.tag {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
}

.importance-tag {
  background-color: #f8f9fa;
}

.重点 {
  background-color: #fff0f0;
  color: #e53935;
  border: 1px solid #ffcdd2;
}

.普通 {
  background-color: #f1f8e9;
  color: #7cb342;
  border: 1px solid #dcedc8;
}

.source-tag {
  background-color: #e3f2fd;
  color: #1976d2;
  border: 1px solid #bbdefb;
}

/* 例句部分 */
.example-section {
  background-color: #f8f9fa;
  border-radius: 12px;
  padding: 15px 20px;
  margin: 20px 0;
  position: relative;
  border-left: 4px solid #2575fc;
}

.example {
  color: #333;
  font-style: italic;
  margin-bottom: 8px;
  font-weight: 500;
}

.example-translation {
  color: #666;
  font-size: 15px;
}

/* 信息部分 */
.info-section {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin-top: 20px;
}

.info-item {
  display: flex;
  gap: 15px;
  padding: 12px 15px;
  border-radius: 12px;
  background-color: #f8f9fa;
  transition: all 0.2s ease;
}

.info-item:hover {
  background-color: #f1f1f1;
  transform: translateY(-2px);
}

.etymology {
  border-left: 3px solid #9c27b0;
}

.memory-tip {
  border-left: 3px solid #ff9800;
}

.info-icon {
  font-size: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.info-content {
  flex: 1;
}

.info-label {
  font-size: 14px;
  font-weight: 600;
  color: #666;
  margin-bottom: 3px;
}

.info-text {
  color: #333;
}


/* 音频按钮样式 */
.audio-btn {
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    padding: 4px 8px;
    border-radius: 4px;
    background: rgba(255, 255, 255, 0.2);
    transition: all 0.2s ease;
}

.audio-btn:hover {
    background: rgba(255, 255, 255, 0.3);
}
'''
    )

    # 创建牌组
    deck = genanki.Deck(
        random.randrange(1 << 30, 1 << 31),
        '英语词汇学习'
    )

    # 创建媒体文件列表和统计计数器
    media_files = []
    stats = {
        'total': len(words),
        'success': 0,
        'failed': 0,
        'cached': 0
    }

    # 对单词列表进行排序
    sorted_words = sorted(words, key=lambda x: (
        int(x['grade']) if x['grade'].isdigit() else 0,
        int(x['semester']) if x['semester'].isdigit() else 0,
        int(x['unit']) if x['unit'].isdigit() else 0
    ))

    # 添加笔记到牌组
    for word in sorted_words:
        # 下载音频
        audio_files = download_audio(word['english'], str(audio_dir))
        audio_tag = ''
        need_delay = False  # 添加标志来追踪是否需要延迟
        
        if audio_files:
            has_us = False
            for audio_file in audio_files:
                media_files.append(str(audio_dir / audio_file))
                audio_tag = ''
                if '_us' in audio_file and os.path.exists(str(audio_dir / audio_file)):
                    audio_tag = f'<span class="audio-btn">[sound:{audio_file}]</span>'
                    has_us = True
                    if not os.path.exists(str(audio_dir / audio_file)):
                        stats['success'] += 1
                        need_delay = True
                    else:
                        stats['cached'] += 1
            
            if not has_us:
                audio_tag = '<span style="color: #ff6b6b;">暂无音频</span>'
                stats['failed'] += 1
        else:
            audio_tag = '<span style="color: #ff6b6b;">暂无音频</span>'
            stats['failed'] += 1

        # 创建排序字段的代码保持不变
        try:
            sort_field = f"{int(word['grade']):02d}-{int(word['semester']):02d}-{int(word['unit']):02d}"
        except ValueError:
            # 如果转换失败，使用默认值
            sort_field = "00-00-00"
        
        note = genanki.Note(
            model=model,
            fields=[
                sort_field,
                word['english'],
                word['pronunciation'],
                word['part_of_speech'],
                word['chinese'],
                word['importance'],
                word['grade'],
                word['semester'],
                word['unit'],
                word['example'],
                word['example_translation'],
                word['etymology'],
                word['memory_tip'],
                audio_tag,  # 添加音频标签
            ]
        )
        deck.add_note(note)
        if need_delay:
            time.sleep(1)  # 只在实际下载了新音频时添加延迟

    # 生成 .apkg 文件
    package = genanki.Package(deck)
    package.media_files = media_files  # 添加媒体文件
    package.write_to_file(output_file)

    # 打印统计信息
    print("\n音频下载统计:")
    print(f"总单词数: {stats['total']}")
    print(f"成功下载: {stats['success']} 个音频文件")
    print(f"使用缓存: {stats['cached']} 个音频文件")
    print(f"下载失败: {stats['failed']} 个单词")
def main():
    # 获取脚本所在目录的父目录（项目根目录）
    root_dir = Path(__file__).parent.parent
    
    # 使用绝对路径
    input_file = root_dir / 'Documentation/Vocabulary.md'
    output_file = root_dir / 'Anki/vocabulary.apkg'
    
    # 确保输出目录存在
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    # 处理词汇表
    words = parse_markdown_table(input_file)
    generate_anki_cards(words, output_file)
    
    print(f'成功生成 {len(words)} 个单词卡片')
    print(f'输出文件：{output_file}')

if __name__ == '__main__':
    main()