//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

//Optional类型用例，连续使用
let testLabel: UILabel? = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 15))
testLabel?.text = "321"
if let label = testLabel{
    if let text = label.text{
        let x = text.hashValue
    }
}
//一行中用?连续逐层访问，效果相同,注意y是Optional Int而z是Int
let y = testLabel?.text?.hashValue//尝试unwrap
let z = testLabel!.text!.hashValue//强制unwrap，如果为nil程序崩溃

//??尝试使用一个Optional相关值或一个默认值
let testLabel2: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 15))
var s: String? = "456"
if s != nil{
    testLabel2.text = s
}else{
    testLabel2.text = " "
}
//使用??
testLabel2.text = s ?? " "


//tuple元组是swift中的一种类型，由任意类型组合而成，使得方法可以返回不止一个值，以下是两种用法
//第一种，事先命名每个元素
var tuple1:(i:Int,d:Double,s:String) = (1,3.5,"Hello")
tuple1.d
tuple1.i
tuple1.s
//第二种，要从中取值前再命名
var tuple2 = (1,3.5,"Hello")
let (i0,d0,s0) = tuple2
let (_,_,s1) = tuple2//swift的_全局的缺省名
i0
d0
s0
s1
//方法返回多个值
func tupleTest()->(Int, Double){
    return (2,2.5)
}
let (tt1,tt2) = tupleTest()
tt1
tt2


//函数的完整语法,外部形参命名和实际形参命名
//可用_省略外部形参命名，swift默认省略函数第一个形参的命名，之后的形参按swift规范不该被省略,下面的properWay（swift2）方法是正确使用方法
//swift3中函数第一个参数已经不能省略
func myFunc(externalFirstPara first: Int, externalSecondPara second: Double){
    
}
func myFunc2(a: Int,b: Int){
    _="First Int Para is: \(a). Second Int Para is: \(b)."
}
func myFunc3(_ a: Int,_ b: Int){
    _="First Int Para is: \(a). Second Int Para is: \(b)."
}
func properWay(_ a: Int, secondParameter b: Int){
    _="First Int Para is: \(a). Second Int Para is: \(b)."
}
func excute(Something a: Int, AnotherThing b: Int){
    _="First Int Para is: \(a). Second Int Para is: \(b)."
}
//调用函数时须要写外部形参命名
myFunc(externalFirstPara: 1, externalSecondPara: 1.1)
myFunc2(a: 1, b: 2)
myFunc3(1, 2)
properWay(3,secondParameter: 2)
excute(Something: 1, AnotherThing: 2)


//Range是swift中的两个端点，范型，例如Range<T>
/* 可以理解为
 struct Range<T>{
    var startIndex: T
    var endIndex: T
 }
*/
//数组的range是Range<Int>
//字符串的range不是Int而是Range<String.Index>
//以下是例子
let myRange = 3...7
let myRange2 = 3..<7
let myArrary = ["a", "b", "c", "d", "e"]
let mySubArrary = myArrary[2...3]


//Class Struct Enum
//相似之处：1.都能拥有属性和方法（Enum只能拥有get set定义的经计算的属性）
//2.除了Enum都有构造函数
//3.Struct Enum是值类型，传递的是拷贝，Class是应用类型，传递的是指针。值类型被赋予给let修饰的变量将不更改，let修饰的指针，指针无法修改，但指向的对象依然可以修改、使用属性和方法。对于Enum和Struct能修改值类型的方法要用关键词mutating标记
//4.结构体多用于基础类型，如String Double Int Arrary Dictionay Point Rectangle。独立自给自足的小东西，通过复制值传递才有意义，大东西一般用Class
//Enum的方法中rawValue关键词
enum Mouth: Int{
    case Frown
    case Smirk
    case Neutral
    case Grin
    case Smile
    
    func sadderMouth() ->Mouth{
        return Mouth(rawValue: rawValue - 1) ?? .Frown
    }
    
    func happierMouth() -> Mouth{
        return Mouth(rawValue: rawValue + 1) ?? .Smile
    }
}



//Switch语法
let mouth = Mouth.Frown
switch mouth{
 case .Frown: fallthrough //用下一个case的代买来执行
 case .Smirk: let two = 1+1//do something
 case .Neutral,.Grin: let one = 1+0//do another thing //同时处理c和d两种情况
 default: break //如果全部枚举完了就不需要default了
}




//Property属性的更多用法
//成员变量被称为熟悉，属性可以被override复写
//存储的属性和计算属性都可以使用willSet和didSet来观察任何属性的变化
//当属性是引用类型时，改变引用对象的属性无法触发，改变所引用对象才会触发；当属性是值类型时改变值会触发willSet和didSet方法
var someStoredProperty: Int = 42{
willSet{
    newValue
}
didSet{
    oldValue
}
}
someStoredProperty = 100
//属性的Lazy Initialization
//只能用var
class People{
    let name: String? = ""
}

class myTestLazy{
    lazy var myObject = People()//用lazy修饰的属性直到使用时才会真正初始化，对于大型对象比较可节约性能，只可用于成员变量
    lazy var someProperty: People = {
        print("anonymous initializer")
        return People()
    }()
    //lazy var myProperty = initializeMyProperty()
    func initializeMyProperty()->(People){
        print("2th initializer")
        return People()
    }
}
let aTestLazy = myTestLazy()//直到下一行被执行才有打印
let bTestLazy = aTestLazy.someProperty


//数组语法
//申明
var ar = Array<String>()
var ar2 = [String]()
//赋值
let animals = ["Giraffe", "Cow", "Doggie", "Bird"]//let申明的变量无法使用mutating方法
var animalMutable = animals
animalMutable.append("Fish")
for animal in animals{
    print(animal)
}
//数组的过滤方法
//Array<T>.filter(includeElement: (T) -> Bool) -> [T]
let filteredNumber = [20,30,40,50,60,77,532,43].filter{$0>25 && $0<70}
for num in filteredNumber{
    print(num)
}
//数组ß转换为另一种数据类型
//Array<T1>.map(transform: (T1) -> T2) -> [T2]
var mappedArray = filteredNumber.map({String($0)})
//当closure（闭包）是函数的最后一个参数，可以写在在数列表的()外面
mappedArray = filteredNumber.map(){String($0)}
mappedArray = filteredNumber.map{String($0)}


//字典的语法
//申明
var studentRanking = Dictionary<String, Int>()
var studentRanking2 = [String: Int]()
//赋值
studentRanking = ["Tom": 80, "Jack": 75]
let ranking = studentRanking["Jack"]//注意取到的是Optional类型的
//字典的枚举，使用tuple
for (key, value) in studentRanking{
    print("\(key)的成绩是\(value)")
}

//字符串
//swift的字符串是Full Unicode，支持世界各种语言和Emoji
//要处理字符串中的单个字符，请用String的以下属性，用法详见其出处
//var characters: String.CharacterView

//字符串各种常用方法都是有的，起始、结束index，是否有前后缀，单词大写，全部转大小写，用某个分隔符分割


//NSObject是所有OC对象的父类，而swift所有的类并没有公共父类
//当使用OC的API时需要用到NSObject

//NSNumber用来把OC中的整形浮点型的数字wrap包装成swift的Int和Double

//NSDate包含世界各地的时间以及相互转换


//initialization初始化（构造函数）
//通过初始化赋值、lazy修饰符、Optional类型和执行闭包，可以避免写init方法，但当有一个属性这些方法都不行时，就必须写init方法
//init(),是默认“免费的”的初始化方法，当你写了一个有参数的init方法后“免费的”就不可用了

//init方法里可以写些什么？
//给任意属性赋值，即使是let常量，可以调用一个其他init方法self.init(<args>)，调用父类的init方法

//init方法必须遵守什么？
//当init方法执行完时，所有属性必须有值，Optional类型可以为nil
//初始化方法可分为两种，convenience和designated（随意的和指定的（不随意的））
//designated初始化方法必须调用最接近的父类的初始化方法，必须在调用父类初始化方法前，初始化所有本类新引入的属性，必须要调用父类初始化方法后，才能修改继承的属性
//convenience方法必须只能调用自身的初始化方法，此后才能修改属性的值
//调用完其他初始化方法后，才能去动属性和方法

//继承初始化方法
//如果你没实现任何designated初始化方法，你将会继承所有父类的designated方法。反之实现了一个designated初始化方法就失去了所有
//如果你复写了所有父类的designated初始化方法，你就会继承所有的convenience初始化方法
//如果什么初始化方法都没有实现，你会继承所有父类的初始化方法
//根据以上三行规则继承来的初始化方法都遵守了上一块中的规则

//必须的初始化方法用required标记，要求子类必须实现这一方法

//可失败的初始化方法 init? 返回Optional类型

//创建对象,调用类型的名字
let p = People()
let dic = [String: Int]()
let arr = [Double]()


//AnyObject(类似于C#的装箱拆箱)
//是一个特殊类型（实际上是一种协议）
//用来与老OC中的API适配，现在已渐渐不需要使用了，因为 苹果更新了老的类库
//可以指向任何类，但你不知道是什么类，不能指向结构体和枚举
//Any可以指向任何类型，几乎不用
//何时使用AnyObject？
//确实希望一个方法的参数能够接受任何类的对象
//或者你希望把对象交给对方但不让对方知道其类，并原样返回给你，例如cookie

//AnyObject的使用
//用as关键字尝试转换，生成Optional类型的对象，用is关键字返回Bool判断是否能转换成某种种类
/*例如
 let ao: AnyObject = …
 if let foo = ao as? SomeClass{
 }
 
 @IBAction func touchDigit(sender: AnyObject){
    if let sendingButton = sender as? UIButton{
        let digit = sendingButton.currentTitle!
        …
    }else if let sendingSlider = sender as? UISlider{
        let digit = String(Int(sendingSlider.value))
        …
    }
 }
*/













