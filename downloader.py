import json
import os
import requests
from urllib.parse import urljoin
import time

def ensure_dir(directory):
    """确保目录存在，如果不存在则创建"""
    if not os.path.exists(directory):
        os.makedirs(directory)

def download_file(url, save_path):
    """下载文件并保存到指定路径"""
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        return True
    except Exception as e:
        print(f"下载失败 {url}: {str(e)}")
        return False

def download_resources():
    # 基础URL
    base_url = "https://ajlee2006.github.io/rhc/Revival%20Hymns%20and%20Choruses/"
    
    # 创建下载目录
    download_dir = "downloads"
    ensure_dir(download_dir)
    ensure_dir(os.path.join(download_dir, "mp3"))
    ensure_dir(os.path.join(download_dir, "midi"))
    ensure_dir(os.path.join(download_dir, "images"))
    
    # 读取JSON文件
    try:
        with open('music_resources.json', 'r', encoding='utf-8') as f:
            resources = json.load(f)
    except FileNotFoundError:
        print("未找到 music_resources.json 文件")
        return
    
    total_files = 0
    downloaded_files = 0
    
    # 遍历并下载所有资源
    for song_id, data in resources.items():
        print(f"\n处理歌曲 {song_id}...")
        
        # 下载MP3
        if data['mp3']:
            total_files += 1
            mp3_url = urljoin(base_url, data['mp3'])
            mp3_path = os.path.join(download_dir, "mp3", f"{song_id}.mp3")
            print(f"下载MP3: {mp3_url}")
            if download_file(mp3_url, mp3_path):
                downloaded_files += 1
            time.sleep(0.5)  # 添加延迟避免请求过快
        
        # 下载MIDI
        if data['midi']:
            total_files += 1
            midi_url = urljoin(base_url, data['midi'])
            midi_path = os.path.join(download_dir, "midi", f"{song_id}.mid")
            print(f"下载MIDI: {midi_url}")
            if download_file(midi_url, midi_path):
                downloaded_files += 1
            time.sleep(0.5)
        
        # 下载图片
        for i, img_url in enumerate(data['images']):
            total_files += 1
            full_img_url = urljoin(base_url, img_url)
            img_path = os.path.join(download_dir, "images", f"{song_id}_{i+1}.jpg")
            print(f"下载图片 {i+1}: {full_img_url}")
            if download_file(full_img_url, img_path):
                downloaded_files += 1
            time.sleep(0.5)
    
    print(f"\n下载完成！成功下载 {downloaded_files}/{total_files} 个文件")

if __name__ == "__main__":
    download_resources()
