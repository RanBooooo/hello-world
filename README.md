# hello-world
Test Repository From RanBoo

Hi Human!

RanBoo here, I am learning unity3D and want to become a game developer.

I may take some notes about Unity3D and C# down below.

Unity Tips
1.If Unity3D Editor crushed, and sense havn't save. You can find backup file in the path: Project/Temp/_Backupscenes/
1.如果编辑器意外崩溃了，但场景未保存，这时可以打开工程目录，找到/Temp/_Backupscenes/文件夹，可以看到有后缀名为.backup的文件，将该文件的后缀名改为.unity拖拽到项目视图，即可还原编辑器崩溃前的场景。

2.Dialogue System for Unity是一款非常不错的对话系统，可以实现0代码编写对话数据库、设置对话UI、设置对话触发器等，从而构建游戏的对话系统。其标准的对话形式和我项目的需求有所不同，所以目前我正在研究中，看如何运用到我的毕业作品中。Dialogue System官方文档地址是：http://www.pixelcrushers.com/dialogue_system/manual/html/index.html

3.用Resource的方式读取文档 尤其在安卓上可以避免使用WWW的麻烦
3.To avoid using WWW to open file on Android, you can use Resource instead.
string jsn = Resources.Load<TextAsset>("questions_data").text;  
questions = JsonUtility.FromJson<Questions> (jsn);

4.If you can't deserialize only on Android. Use string.Trim() to solve the string before you deserialize it.
4.解析Json在安卓ios可能遇到解析不出的问题，只需用string.Trim()处理掉多余的空格就能正常解析了

5.Android Studio导出.jar的方法：把要导出的Module设为android library，然后build，生成的jar文件在build/intermediates/bundles/release/classes.jar
参考链接： 
http://blog.csdn.net/u010019717/article/details/51762010
http://www.cnblogs.com/wuya/p/android-studio-gradle-export-jar-assets.html
