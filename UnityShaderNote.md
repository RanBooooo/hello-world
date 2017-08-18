### Surface Shader语法语式大致如下

Shader "Example/ExampleShader" {

// 此处定义向外暴露的变量

​	Properties{

​		_MainTex ("Texture", 2D) = "white" {} // 变量名("编辑器中的名字",类型)="默认值"{}

​		_BumpMap ("Bumpmap", 2D) = "bump" {}

​		_RimColor ("Rim Color", Color) = (0.26,0.19,0.16,0.0)

​      		_RimPower ("Rim Power", Range(0.5,8.0)) = 3.0	

​	}

​	SubShader {

​		Tags{ "RenderType" = "Opaque" } 

​		CGPROGRAM // 开始HLSL程序

​		// 此处是Surface Shader的编译指令

​		\#pragma surface surf Lambert

​		// 选择需要的内置输入

​		struct Input {

​          		float2 uv_MainTex;

​          		float2 uv_BumpMap;

​         		float3 viewDir;		

​		}

​		// 此处声明的变量与最上面Properties对应

​     		 sampler2D _MainTex;

​      		sampler2D _BumpMap;

​      		float4 _RimColor;

​      		float _RimPower;

​		// surf函数，片源相关计算

​		void surf ( Input IN, inout SurfaceOutout o ) {

​			o.Albedo = tex2D (_MainTex, IN.uv_MainTex).rgb;

​         		 o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));

​          		half rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));

​          		o.Emission = _RimColor.rgb * pow (rim, _RimPower);

​		}

​		ENDCG // HLSL程序结束

​	}

// 另一个子Shader ，比上面的功能更加简单，以适配老显卡

​	SubShader{



​	}

// 以上全不支持时最终采用的Unity内置Shader

​	Fallback "Diffuse"

}

### Surf常见内置输入输出

详见：https://docs.unity3d.com/Manual/SL-SurfaceShaders.html

#### 输入 Input

float2 uv_MainTex // uv_贴图的名字 可以获得当前顶点的贴图坐标

float3 viewDir // 顶点到摄像机的单位向量

float4 screenPos // 顶点在屏幕上的齐次坐标，要转化为坐标再使用

float3 worldRefl // 世界反射的向量，例子：texCUBE (_Cube, IN.worldRefl).rgb可获得cubemap的颜色

float3 worldPos // 顶点的世界坐标

#### 输出 SurfaceOuput

.Albedo // 颜色

.Normal // 法线

.Emission // 自发光

### Surface Shader编译指令   \#pragma

 \#pragma surface surf Lambert 

vertex:functionName // 表示把functionName作为顶点函数，参数列表：(inout appdata_full v, out Input o)第二个参数可选

finalcolor:functionName // 表示把functionName作为最终颜色函数，可在其中修改输出的最终颜色，参数列表：(Input IN, SurfaceOutput o, inout fixed4 color)

\#pragma multi_compile_fog 可以使用：uniform half4 unity_FogStart; uniform half4 unity_FogEnd;

自定义光线光线模型 \#pragma surface surf SimpleLambert // 此处SimpleLambert对应的实际函数名称应该是LightingSimpleLambert

曲面细分函数tessellate:functionName，返回值是一个float4，三个元素代表三角形的三条边，一个元素代表三角形内部还要添加:\#pragma target 4.6\#include "Tessellation.cginc"

### ShaderLab语法

#### SubShader Pass Category

SubShader位于Shader之中，至少一个，多个表示对不同硬件的fallback。将命令写于SubShader中表示对齐下的Pass都适用

Pass位于SubShader中，至少一个（可不写），多个表示对一个物体的多次渲染；也有某些Pass会执行多次，例如ForwardAdd会根据多少光影响了物体而执行多次；可设置条件是某一Pass只在某一条件下渲染，例如只在deferred下渲染。可用UsePass从其他文件中复制某一Pass。GrabPass抓取屏幕纹理用于之后的Pass渲染。

Category是逻辑组，可用于存放SubShader，将命令写于Category中表示对齐下的SubShader都适用

#### ShaderLab命令

#####SubShader标签

以下是unity内置的tags必须卸载SubShader中，不能写在Pass中，此外也可以自定义tags用Material.GetTag获取

1渲染顺序- **Queue**标签 决定物体的绘图顺序，Shader 决定它属于哪个渲染队列，透明shader确保在不透明物体之后绘制等等

Background此队列在所有其他之前，一般用在背景物体上

Geometry默认，不透明几何体就使用这一队列

AlphaTest alpha测试几何体用这一队列，独立于Geometry队列，因为在不透明体绘制后再渲染alpha测试物体效率更高

Transparent此队列在Geometry和AlphaTest之后，从后往前的顺序。所有alpha混合（例如不写入深度缓冲区的shader）应该在这里

Overlay 这一渲染队列是为了层叠效果。任何最后渲染的应该在这里（例如lens flares光斑效果）

在两个队列之间的特殊用法。每个队列代表一个整数Background是1000，Geometry是2000，AlphaTest是2450，Transparent是3000，Overlay是4000。Shader的的队列可以是这样的

Tags { "Queue" = "Geometry+1" }

这就表示队列序号是2001。当要在两个队列间绘制时很有用。例如透明的水绘制应该在不透明之后，但在透明之前。

队列知道2500（"Geometry+500" ）都被当做不透明物体，被优化绘制顺序已获得最佳性能。2500以上的队列被认为是透明物体根据距离排序物体，从远到近渲染。天空盒在所有的不透明和透明物体之间绘制。

2渲染类型 **RenderType**标签

用于shader替换和产生摄像机的深度纹理

3禁用Batching **DisableBatching**标签

某些shader（主要是那些物体-空间顶点变形的）在Draw Call Batching使用时无法工作。因为Batching便换了左右几何体到世界坐标中，所以物体空间丢失了

三个值：True对此Shader永远禁用batching，False默认不禁用，LODDading当LOD法定启用时禁用，主要用与树木

4强制不施加阴影 **ForceNoShadowCasting**标签

Ture值物体用此subshader 渲染永不产生阴影。在对透明物体用替换shader时最有用，不会希望从别的subshader继承阴影pass

5忽略投影器 **IgnoreProjector**标签 时物体不受Projector影响。用于半透明物体，因为Projector对他们的效果不理想

5能使用图集 **CanUseSpriteAtlas**标签

False值表示：当被打包成图集时不工作

6预览类型 **PreviewType**标签

表示材质监视器预览如何展示材质。默认是球体，但也能设为平面或天空盒

#####Pass名字和标签

一个Pass能定义一个名字Name和任意数量的标签Tags

语法

Pass {\[Name and Tags\]}

Tags包括：LightMode PassFlags 和RequireOptions

LightMode只在某一渲染路径下使用此Pass

"PassFlags"="OnlyDirectional" 

"RequireOptions"="SoftVegetation"

详见：https://docs.unity3d.com/Manual/SL-PassTags.html

#####Pass渲染状态设置：

Cull Back|Fornt|Off 多边形剔除模式，剔除背面、剔除正面、不剔除

ZTest (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) Z-Buffer深度检测，小于、大于、小于等于、大于等于、等于、不等于、永远

ZWrite On|Off是否写入深度缓冲区

Offset OffsetFactor, OffsetUnits 写入深度缓冲区的偏移

Blend渲染后像素如何与已有的像素混合，详见：https://docs.unity3d.com/Manual/SL-Blend.html

ColorMask 任意RGBA的组合 色彩遮罩，关闭某一通道的写入

一些Legacy固定函数命令：

Lighting On | Off

Material { Material Block }

SeparateSpecular On | Off

Color Color-value

ColorMaterial AmbientAndDiffuse | Emission

Fog { Fog Block }

AlphaTest (Less | Greater | LEqual | GEqual | Equal | NotEqual | Always) CutoffValue

SetTexture textureProperty { combine options }

#### 高级

1.替换着色器

Camera.RenderWithShader或Camera.SetReplacementShader 用某一Shader替换场景中所有带某一Tag的shader进行渲染。详见：https://docs.unity3d.com/Manual/SL-ShaderReplacement.html

2.Shader LOD

只使用LOD值小于一个指定值的shader或subshader

### 其他Tips

1.受法线影响的世界反射。Input结构体中要加入INTERNAL_DATA；

o.Emission = texCUBE (_Cube, WorldReflectionVector (IN, o.Normal)).rgb;

2.水平切割效果clip (frac((IN.worldPos.y+IN.worldPos.z*0.1) * 5) - 0.5); // frac取小数部分 clip函数：若输入值大于0则丢弃当前像素

3.在顶点函数中自定义参数传递给surf的数据。

void vert (inout appdata_full v, out Input o) {

​          UNITY_INITIALIZE_OUTPUT(Input,o);

​          o.customColor = abs(v.normal);

}

注意Input中定制的变量命名不能以uv开头

3.在语句中加入预编译条件，在应对不同的渲染管线设置

void mycolor (Input IN, SurfaceOutput o, inout fixed4 color) {

​	fixed3 fogColor = _FogColor.rgb;

\#ifdef UNITY_PASS_FORWARDADD

​	fogColor = 0;

\#endif

​	color.rgb = lerp (color.rgb, fogColor, IN.fog); // lerp 线性插值函数。第一第二个参数间根据第三个参数线性插值

​	// 词句同 UNITY_APPLY_FOG_COLOR(IN.fog, color, fogColor);

}



4.到镜头中心越远值越大，最大1

void myvert (inout appdata_full v, out Input data){

​	UNITY_INITIALIZE_OUTPUT(Input,data);

​	float4 hpos = UnityObjectToClipPos(v.vertex); // 乘以MVP矩阵

​	hpos.xy/=hpos.w;

​	data.fog = min (1, dot (hpos.xy, hpos.xy)*0.5); // 点乘自身等于模的平方

}

5.Decals贴花，用于在运行时给材质增加细节（例如弹痕）。尤其在deferred渲染管线时特别有用，因为在点亮前改变了GBuffer，所以节约性能。一般贴花在不透明物体之后渲染，不被施加阴影。见以下Tags

​    Tags { "RenderType"="Opaque" "Queue"="Geometry+1" "ForceNoShadowCasting"="True" }

​	LOD 200

​	Offset -1, -1

​	CGPROGRAM

\#pragma surface surf Lambert decal:blend

5.Diffuse Wrap明暗反差更小的Lambert，模拟次表面散射

​	half NdotL = dot (s.Normal, lightDir);

​	half diff = NdotL * 0.5 + 0.5;

​	half4 color  = s.Albedo * _LightColor0.rgb * (diff * atten);

6.Toon Ramp卡通渐变

sampler2D _Ramp;

half4 LightingRamp (SurfaceOutput s, half3 lightDir, half atten) {

​	half NdotL = dot (s.Normal, lightDir);

​	half diff = NdotL * 0.5 + 0.5;

​	half3 ramp = tex2D (_Ramp, float2(diff)).rgb;

​	half4 c;

​	c.rgb = s.Albedo * _LightColor0.rgb * ramp * atten;

​	c.a = s.Alpha;

​	return c;

}

7.简单反射

half3 h = normalize (lightDir + viewDir);

half diff = max (0, dot (s.Normal, lightDir));

float nh = max (0, dot (s.Normal, h));

float spec = pow (nh, 48.0);

half4 color.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * atten;

8.曲面细分的几种类型：

不细分，根据置换贴图在顶点函数中移动顶点

固定数量的曲面细分

基于和摄像机的距离

基于三角形的投影在屏幕上的大小

Phong曲面细分，可以没有置换贴图

### Unity Standard Shader

​	Unity标准着色器功能广泛。适合于渲染真实世界中的物体例如石头、木头、草、塑料和金属。支持广泛的shader类型和组合。在材质编辑器中填或不填某一参数就能控制shader功能的开与关

​	纳入了先进的光照模式Physically Based Shading（基于物理的着色）(PBS)。PBS模拟真实世界材质与光线间的交互。PBS最近才在实时图像技术下成为可能。在光线和材质真实自然共存的情况下表现最好。

​	基于物理的着色器的理念是创造用户友好的方式在不同的光照条件下得到持续合理的外观。在不使用多种单一用途光照模型的情况下，模拟了现实的光。为了实现这一效果，我们遵循了物理原理，包括能量守恒（物体永远不会反射超过接收量的光），菲尼尔反射（所有物体在掠射角反射更强），表面如何吸收其自身（称为Geometry Term），对其他物体。

​	标准着色器以硬表面（也被称为建筑材质）为目标设计，能够处理大多数真实世界的材质，如石头、玻璃、陶瓷、黄铜、银河橡胶。即使一些非硬表面的材质例如皮肤、头发和布料也有着不错的表现。

​	用标准着色器大量的着色器类型（例如漫反射、镜面、凸起的镜面，反射）都被合成了一个着色器，所以能够在不同的材质类型上使用。这样做的好处是同一种光照计算在场景中的所有区域使用，使所有使用了标准着色器的模型都能有自然、统一、可信的光影分布。

#### 术语

有一些概念在谈论Unity中的PBS时非常有用，包括：

##### 能量守恒

这一物理概念保证物体永不反射比接受到的更多的光，一个物体越是镜面，它就越不漫反射；表面约光滑，高光就约强且越小

##### 高动态范围HDR

这指的是超过了0-1范围的颜色。例如太阳轻松的达到蓝天10倍的亮度。

### 材质属性

##### 渲染模式

Opaque（不透明）适合于一般固体不透明的区域

Cutout（剪下来的）能创建透明和不透明间的硬边缘，没有半透明，只有100%透明和不透明。用于创建树叶，衣服上的洞。

Transparent（透明）适合于渲染正式的透明材质例如塑料盒玻璃。此模式材质会读取透明值（基于纹理的alpha通道），然而反射和光线的高光将完全保持可见，就如同真实的透明材质。

Fade（渐隐）使透明度值遍布整个物体，包括所有的镜面高光和反射，此模式可以用来做渐隐动画，不适合正式的透明物体，因为高光也会带有渐隐效果

##### 镜面设置和金属设置（默认）

​	两者都产生镜面高光，选用哪一个更主要取决于美术风格。镜面设置直接控制亮度和颜色渐变

##### 高度贴图

​	比法线贴图更近一步，实际移动可见表面的纹理，得到一种表面级的阻塞效果。实际测试效果：会在表面内部产生高低感，但不会像曲面细分那样实际影响物体的外轮廓。

##### 环境阻塞贴图

​	那些区域应该接受高或低的间接光照（环境光和反射）,例如裂纹或皱褶不该接受太多的间接光照。灰度图约白表示接受越多间接光照，越黑表示接受越少的间接光照。

##### 自发光

​	控制物体表面散发出来的光的强度和颜色。当场就中有一个自发光材质时，他被自身光点亮而可见。

​	常被用于例如从内部点亮的东西例如显示屏，发红的刹车盘，控制台上发光的按钮或是怪物发光的眼睛。

​	有参数可控用于全局光照。None不影响旁边物体。Realtime会吧它加入实时GI计算周围物体会被点亮。Baked静态物体会受影响。

##### 次要贴图（细节贴图）和细节遮罩

​	叠加于主要贴图之上给表面添加细节，有颜色和法线两种，一般是小型重复多次的贴图。

​	这样做的好处是近看有细节，远看细节一般。不用太高分辨率的主贴图。

​	用了次要贴图开销会提高。

​	细节遮罩让你遮罩一部分不套用细节贴图。

##### 菲涅尔效果

​	真实的视觉效果的重要一环，物体在掠射角变得更加反射。

​	在标准着色器中没有直接的控制方法，间接受光滑属性的控制。越光滑菲涅尔效果越强。

#### 材质图表

​	参照此表以得到真实的渲染效果https://docs.unity3d.com/Manual/StandardShaderMaterialCharts.html

#### 自己制作

​	标准着色器的源码提供下载，可以在此基础上修改得到你想要的效果

​	https://unity3d.com/cn/get-unity/download/archive  下拉菜单中选择内置着色器

#### 通过脚本改变标准着色器的注意事项

##### 1.为你所需的标准着色器变体启用正确的关键字

​	一开始未分配的属性，要分配属性。会导致使用另一个标准着色器变体，此时必须调用“启用关键字”函数，来启用那一变体。例如给原来没赋予法线贴图的材质赋予法线贴图，或把原来为0的自发光值设为0以上。

##### 2.确保Unity build时包含了着色器变体

​	包含至少一个同类的材质资源，以确保Unity知道你想要用的着色器变体。材质至少要被应用于一个场景或被放到Resources文件夹中。否则Unity build时会漏掉，因为显然没有被使用。

### Unity渲染管线

由于光线计算必须在shader中，而且有多种可能的光线和阴影类型，写出能正常工作的Shader以及很复杂了。为了让事情变简单，Unity有Surface Shaders，其中所有的光线，阴影，LightMapping，forward和Deferred渲染都被自动处理了。

####渲染路径

​	光线如何施加、以及用Shader中的哪一个Pass，取决于用了哪个渲染路径。shader中的每个pass通过pass的tags交流它的光线类型。

在Forward Rendering中使用**ForwardBase** 和**ForwardAdd** pass

在Deferred Shading中使用**Deferred** pass

在legacy Deferred Lighting中使用**PrepassBase**和**PrepassFinal** pass

在legacy Vertex Lit中使用**Vertex** **VertexLMRGBM** **VertexLM** pass

在以上任何一个中，要渲染阴影或深度纹理，使用**ShadowCaster** pass

#### Forward渲染路径细节

将场景中的光源分为三类：逐像素（数量在Quality Setting中设置，除了第一个其他的使用Additional render passes）、逐顶点、SH（Spherical Harmonics立体调和函数）

Base Pass 用逐像素和SH渲染物体。此pass也添加shader中所有的lightmap，环境光和自发光。平行光有阴影。Lightmap的物体得不到从SH的光照。如果使用“OnlyDirectional”pass指令，base pass 只渲染主平行光，环境光/光探测球和lightmap，SH和顶点光不会包含在pass数据中。

Additional Passes，对于除了第一个逐像素的光源执行，默认不产生阴影，除使用multi_compile_fwdadd_fullshadows缩写指令。

#### Deferred shading 渲染路径

使用了这种渲染路径能影响物体的光数量没有限制，所有的光都会逐像素计算，都能正确的与法线贴图交互。另外所有的光能够有cookies和阴影。

使用MRT（multiple render targets），先渲染几何体存入G-buffer，再进行光计算，每个光都得到计算，得到真实的光影效果。







