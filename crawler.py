import requests
from bs4 import BeautifulSoup
import json

def crawl_music_resources():
    source = "https://ajlee2006.github.io/rhc/Revival%20Hymns%20and%20Choruses/index.html"
    
    # 获取页面内容
    response = requests.get(source)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # 找到body中的第二个元素（第一个表格）
    body = soup.find('body')
    if not body:
        raise Exception("未找到body标签")
        
    target_table = body.find_all('table', {'class': 'sortable', 'id': 'ver-minimalist'})[0]
    if not target_table:
        raise Exception("未找到目标表格")
    
    # 存储结果的字典
    result = {}
    
    # 遍历所有行
    for tr in target_table.find_all('tr'):
        # 找到第5个td
        tds = tr.find_all('td')
        if len(tds) >= 5:  # 确保行有足够的列
            td = tds[4]
            links = td.find_all('a')
            
            if links:  # 如果有链接
                row_data = {
                    "mp3": links[0]['href'] if len(links) > 0 else "",
                    "midi": links[1]['href'] if len(links) > 1 else "",
                    "images": []
                }
                
                # 添加图片链接（第三个链接开始）
                for link in links[2:]:
                    row_data["images"].append(link['href'])
                
                # 使用行的第一列作为键（如果存在）
                row_key = tds[0].text.strip() if tds[0].text.strip() else f"row_{len(result)}"
                result[row_key] = row_data
    
    # 将结果保存到JSON文件
    with open('music_resources.json', 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    crawl_music_resources()