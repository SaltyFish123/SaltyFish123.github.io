---
title: 关于
layout: page
comments: no
---

## 自我介绍

{{ site.about }}

----

## 关于本站

本站文章大部分是我个人的读书笔记，小部分是我自己做项目的经验总结，分享在网站上不仅是希望能够帮助到有需要的人，同时也是对于自己知识体系的一个总结，加深理解。由于个人技术水平和精力有限，文章难免有疏漏之处，如果有发现，还请见谅，请及时反馈给我，我会尽快改正，谢谢。

----

## 联系方式

{% if site.qq %}
ＱＱ：[{{ site.qq }}](tencent://message/?uin={{ site.qq }})
{% endif %}
网站：[{{ site.name }}]({{ site.url }})

邮箱：[{{ site.email }}](mailto:{{ site.email }})

GitHub : [http://github.com/{{ site.github }}](http://github.com/{{ site.github }})

{% if site.weibo %}
[![新浪微博](http://service.t.sina.com.cn/widget/qmd/{{ site.weibo }}/f78fbcd2/1.png)](http://weibo.com/u/{{ site.weibo }})
{% endif %}
