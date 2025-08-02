#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自动批量替换中文为英文脚本
使用方法: python auto_replace.py
"""

import os
import re
import glob

# 替换映射表
REPLACEMENTS = {
    # 应用基础
    '卡路里追踪器': 'Calorie Tracker',
    '卡路里': 'Calories',
    
    # 餐次
    '早餐': 'Breakfast',
    '午餐': 'Lunch', 
    '晚餐': 'Dinner',
    '零食': 'Snacks',
    '餐次:': 'Meal:',
    '餐次': 'Meal',
    
    # 食物分类
    '主食': 'Staple Food',
    '蛋白质': 'Protein',
    '蔬菜': 'Vegetables',
    '水果': 'Fruits',
    '饮品': 'Beverages',
    '其他': 'Others',
    
    # 食物名称
    '米饭': 'Rice',
    '面条': 'Noodles',
    '面包': 'Bread',
    '鸡胸肉': 'Chicken Breast',
    '鸡蛋': 'Egg',
    '牛肉': 'Beef',
    '鱼肉': 'Fish',
    '西兰花': 'Broccoli',
    '胡萝卜': 'Carrot',
    '番茄': 'Tomato',
    '苹果': 'Apple',
    '香蕉': 'Banana',
    '橙子': 'Orange',
    '薯片': 'Potato Chips',
    '巧克力': 'Chocolate',
    '牛奶': 'Milk',
    '可乐': 'Cola',
    
    # 个人信息
    '个人设置': 'Personal Settings',
    '个人资料已更新！': 'Profile updated successfully!',
    '基本信息': 'Basic Information',
    '姓名': 'Name',
    '年龄': 'Age',
    '性别': 'Gender',
    '身高': 'Height',
    '体重': 'Weight',
    '男': 'Male',
    '女': 'Female',
    '活动水平': 'Activity Level',
    
    # 活动水平描述
    '久坐 (很少或没有运动)': 'Sedentary (little/no exercise)',
    '轻度活动 (每周轻度运动1-3天)': 'Light Activity (light exercise 1-3 days/week)',
    '中度活动 (每周中度运动3-5天)': 'Moderate Activity (moderate exercise 3-5 days/week)',
    '高度活动 (每周剧烈运动6-7天)': 'High Activity (hard exercise 6-7 days/week)',
    '极度活动 (非常剧烈的运动，体力工作)': 'Very High Activity (very hard exercise, physical job)',
    
    # 操作按钮
    '添加食物': 'Add Food',
    '快速添加': 'Quick Add',
    '保存': 'Save',
    '取消': 'Cancel',
    '确定': 'Confirm',
    '删除': 'Delete',
    '编辑': 'Edit',
    '搜索': 'Search',
    '完成': 'Done',
    '添加': 'Add',
    '重置默认': 'Reset to Defaults',
    '保存设置': 'Save Settings',
    
    # 页面标题
    '今日目标': "Today's Goal",
    '今日卡路里进度': "Today's Calorie Progress",
    '营养概览': 'Nutrition Overview',
    '快速操作': 'Quick Actions',
    '营养分析': 'Nutrition Analysis',
    '查看历史': 'View History',
    '历史记录': 'History Records',
    '设置': 'Settings',
    
    # 数据显示
    '剩余卡路里': 'Calories Remaining',
    '超出': 'Exceeded',
    '完成': 'Completed',
    '% 完成': '% Complete',
    '目标摄入': 'Target Intake',
    '实际摄入': 'Actual Intake',
    '基础代谢率': 'BMR',
    '每日消耗': 'TDEE',
    '今日食物': "Today's Food",
    '项': 'items',
    
    # 搜索和添加
    '搜索食物名称或分类...': 'Search food name or category...',
    '请选择一个食物': 'Please select a food',
    '请输入有效的数量': 'Please enter a valid quantity',
    '数量': 'Quantity',
    '总卡路里': 'Total Calories',
    '添加并继续': 'Add and Continue',
    '完成添加': 'Finish Adding',
    
    # 营养相关
    '营养成分分布': 'Nutrition Distribution',
    '营养目标达成情况': 'Nutrition Goals Progress',
    '营养建议': 'Nutrition Advice',
    '营养比例很均衡，继续保持！': 'Nutrition is well balanced, keep it up!',
    '蛋白质摄入偏低，建议增加鸡胸肉、鱼类或豆类': 'Protein intake is low, consider adding chicken, fish or legumes',
    '碳水化合物过高，减少精制糖和加工食品': 'Carbohydrate intake is high, reduce refined sugar and processed foods',
    
    # 历史记录
    '趋势': 'Trends',
    '统计': 'Statistics',
    '食物': 'Foods',
    '最近7天概览': 'Last 7 Days Overview',
    '平均摄入': 'Average Intake',
    '活跃天数': 'Active Days',
    '目标达成率': 'Achievement Rate',
    '最常吃的食物': 'Most Frequent Foods',
    
    # 推荐功能
    '🤖 AI智能推荐': '🤖 AI Recommendations',
    '基于您的饮食习惯和当前时间': 'Based on your dietary habits and current time',
    '刷新推荐': 'Refresh Recommendations',
    'AI正在分析您的需求...': 'AI is analyzing your needs...',
    '为您推荐以下食物：': 'Recommended for you:',
    '查看更多推荐': 'View More Recommendations',
    '暂无推荐': 'No recommendations',
    '多记录一些饮食，推荐会更准确': 'Record more diet data for more accurate recommendations',
    
    # 时间问候语
    '上午好': 'Good morning',
    '下午好': 'Good afternoon',
    '晚上好': 'Good evening',
    '你好': 'Hello',
    
    # 验证信息
    '请输入姓名': 'Please enter name',
    '年龄应在10-120岁之间': 'Age should be between 10-120 years',
    '身高应在100-250cm之间': 'Height should be between 100-250cm',
    '体重应在30-300kg之间': 'Weight should be between 30-300kg',
    
    # 数据管理
    '数据统计': 'Data Statistics',
    '清除数据': 'Clear Data',
    '确定要清除所有数据吗？': 'Are you sure you want to clear all data?',
    '所有数据已清除': 'All data cleared',
    '正在加载数据...': 'Loading data...',
    
    # 通用词汇
    '今天': 'Today',
    '昨天': 'Yesterday',
    '前天': 'Day before yesterday',
    '今日': 'Today',
    '日期': 'Date',
    '时间': 'Time',
    '分类': 'Category',
    '类型': 'Type',
    '状态': 'Status',
    '结果': 'Result',
    '成功': 'Success',
    '失败': 'Failed',
    '错误': 'Error',
    '警告': 'Warning',
    '信息': 'Info',
}

# 需要特殊处理的模板字符串
TEMPLATE_REPLACEMENTS = {
    r'已添加\s*(\S+)\s*\((\d+)\s*卡路里\)': r'Added \1 (\2 calories)',
    r'让我们开始记录今天的饮食，目标：(\d+)\s*kcal': r"Let's start recording today's diet, goal: \1 kcal",
    r'吃了\s*(\d+)\s*次': r'eaten \1 times',
    r'你好,\s*(\S+)!': r'Hello, \1!',
    r'(\d+)岁': r'\1 years old',
    r'(\d+)天': r'\1 days',
    r'(\d+)项食物': r'\1 food items',
}

def replace_in_file(file_path):
    """替换单个文件中的中文"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # 普通替换
        for chinese, english in REPLACEMENTS.items():
            content = content.replace(chinese, english)
        
        # 模板字符串替换
        for pattern, replacement in TEMPLATE_REPLACEMENTS.items():
            content = re.sub(pattern, replacement, content)
        
        # 如果内容有变化，写回文件
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Updated: {file_path}")
            return True
        else:
            print(f"⚪ No changes: {file_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def main():
    """主函数"""
    print("🚀 开始批量替换中文为英文...")
    print("=" * 50)
    
    # 查找所有 Dart 文件
    dart_files = glob.glob('lib/**/*.dart', recursive=True)
    
    if not dart_files:
        print("❌ 没有找到 Dart 文件，请确保在项目根目录运行此脚本")
        return
    
    print(f"📁 找到 {len(dart_files)} 个 Dart 文件")
    print()
    
    updated_count = 0
    for file_path in dart_files:
        if replace_in_file(file_path):
            updated_count += 1
    
    print()
    print("=" * 50)
    print(f"🎉 替换完成！")
    print(f"📊 总文件数: {len(dart_files)}")
    print(f"📝 更新文件数: {updated_count}")
    print(f"⚪ 无需更新: {len(dart_files) - updated_count}")
    print()
    print("💡 建议接下来：")
    print("1. 运行 'flutter run' 测试应用")
    print("2. 检查UI布局是否正常")
    print("3. 测试所有功能是否正常工作")
    print("4. 如有问题，请手动调整相关代码")

if __name__ == "__main__":
    main()