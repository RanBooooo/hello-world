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

6.LOD(level of Detail)和Occlusion Culling（遮挡剔除）可用于性能优化，都是通过减少渲染的mesh降低GPU负担，都广泛运用于各类高画质游戏大作中。
LOD使用高中低不同精细程度的模型添加到LOD Group中，当摄像机逐渐远离物体，一档档切换为低模。
Occlusion Culling，bake场景中的static物体，通过对场景进行细分，把被遮挡的物体和不在摄像机视野内的物体隐藏。

7.Realtime GI(Global Illumination)（实时全局照明）实现游戏场景的间接光照、反射光照和实时光源变化，是次时代游戏必备的功能，在Unity5以上版本可用。
共有三个档次non-directional,directional,directional specular，移动端一般用non-directional。
通过bake static物品。预计算物体在所有光照情况下受周围物体间接光照的数据，保存为lightmap光照贴图。lightmap parameter对bake时间和运行时性能影响很大，需要细致调节。
一般只bake场景中的大中型物体，小物体一般用light probe来照亮。

8.除了Light，Unity 5 Standard Shader包含的Emission属性也可以用来点亮场景，默认作用于static物体，想点亮非static物品需要使用Light Probe。

9.Unity旋转，四元数操作。参考链接：http://blog.csdn.net/candycat1992/article/details/41254799
通过欧拉角：
首先使用Quaternion.eulerAngles来得到欧拉角度，然后使用Mathf.Clamp对其进行插值运算。
最后更新Quaternion.eulerAngles或者使用Quaternion.Euler(yourAngles)来创建一个新的四元数
通过矩阵旋转：
例如Quaternion.AngleAxis(float angle, Vector3 axis)，它可以返回一个绕轴线axis旋转angle角度的四元数变换。我们可以一个Vector3和它进行左乘，就将得到旋转后的Vector3



