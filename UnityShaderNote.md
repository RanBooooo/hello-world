#### Surface Shader语法语式大致如下

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

​	比法线贴图更近一步，实际移动可见表面的纹理，得到一种表面级的阻塞效果

##### 环境阻塞贴图

​	那些区域应该接受高或低的间接光照（环境光和反射）,例如裂纹或皱褶不该接受太多的间接光照。灰度图约白表示接受越多间接光照，越黑表示接受越少的间接光照。

##### 自发光

​	控制物体表面散发出来的光的强度和颜色。当场就中有一个自发光材质时，他被自身光点亮而可见。

​	常被用于例如从内部点亮的东西例如显示屏，发红的刹车盘，控制台上发光的按钮或是怪物发光的眼睛。

​	有参数可控用于全局光照。None不影响旁边物体。Realtime会吧它加入实时GI计算周围物体会被点亮。Baked静态物体会受影响。