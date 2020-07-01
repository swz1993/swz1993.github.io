# 概述

Data Binding是一种支持库，借助该库，我们可以使用声明性格式（而非程序化地）将布局中的界面组件绑定到应用中的数据源。

## 1、布局和绑定表达式

#### **布局**

首先，将app配置为使用Data Binding，需要在build.gradle中配置

```java
android{

...
dataBinding {
        enabled = true
    }
...

}
```

>必须为依赖于使用Data Binding的应用程序模块配置dataBinding，即使该应用程序模块不直接使用Data Binding也是如此

然后，在配置xml文件

```xml
<?xml version="1.0" encoding="utf-8"?>
<layout xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:app="http://schemas.android.com/apk/res-auto"
        xmlns:tools="http://schemas.android.com/tools"
        tools:context=".main.MainActivity">

    <data>

		<!--第一种方式-->

		 <variable
            name="user"
            type="com.ywt.myapplication.jetpack.databinding.UserInfo" />
              
        <!--第二种方式-->

        <--<import type="com.ywt.myapplication.jetpack.databinding.UserInfo" />

        <variable
                name="user"
                type="UserInfo" />-->
               
    </data>


    <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:gravity="center">


        <TextView
                android:id="@+id/mainTextView"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="@{user.name,default = my_defult}"
                app:layout_constraintBottom_toBottomOf="parent"
                app:layout_constraintLeft_toLeftOf="parent"
                app:layout_constraintRight_toRightOf="parent"
                app:layout_constraintTop_toTopOf="parent" />

    </LinearLayout>


</layout>

```
使用“@{}”语法将属性写入布局中

>布局表达式应该小而简单，因为影响单元测试，而且不符合我们解耦的原则

其中

**layout**：根结点，其中包含了data和界面布局的根元素，不能直接包含<merge>

**data**：绑定的数据，只能有一个data标签

**variavle**：描述在此布局中使用的类及其在布局中使用的名称(上例中 UserInfo 就是使用到的类，user 就是在布局中使用的名称，用于在控件中直接使用)，是data标签中的属性

**import**：静态导入某个类，可以直接使用被导入类的静态方法，可配合variavle使用，是data标签中的属性

**alias**：类名冲突时，可以使用此属性设置别名，是import中的属性

**class**：自定义Data Binding生成的类名及路径，不过一般不需要，是data标签中的属性

**include**：，是data标签中的属性，两个布局通过**include**的**app:变量名=@{表达式}**来传递. 两个布局的变量名必须相等

```xml

<variable
          name="userName"
          type="String"/>

....

<include
		  android:id="@+id/include"
         layout="@layout/data_binding_view"
         app:name="@{user.name}" />
```

data\_binding\_view

```xml
    <data>

        <variable
            name="name"
            type="String"/>
    </data>
...

<TextView
		  android:id="@+id/name"
         android:layout_width="match_parent"
         android:layout_height="match_parent"
         android:gravity="center"
         android:text="@{name}" />


```

在代码中使用

```kotlin
bingding.include.name.text = "swz"
```

>如果同时为TextView在代码和布局中赋值，那么布局中为TextView所赋的值会覆盖代码中所赋的值

#### **绑定视图**

系统会为每个布局文件生成一个绑定类。默认情况下，类名称基于布局文件的名称，它会转换为 Pascal 大小写形式并在末尾添加 Binding 后缀。比如布局文件名为 `activity_main.xml`，生成的对应类为 `ActivityMainBinding`。此类包含从布局属性（例如，`user` 变量）到布局视图的所有绑定，并且知道如何为绑定表达式指定值。此类的使用方式为：

```java
@Override
    protected void onCreate(Bundle savedInstanceState) {
       super.onCreate(savedInstanceState);
       ActivityMainBinding binding = DataBindingUtil.setContentView(this,         R.layout.activity_main);
       UserInfo user = new UserInfo("Test", "User");
       binding.setUser(user);
    }
```

或者，可以使用 `LayoutInflater` 绑定视图

```java
ActivityMainBinding binding = ActivityMainBinding.inflate(getLayoutInflater());
```



在`Fragment`、`ListView` 或 `RecyclerView` 适配器中使用数据绑定项，可以使用绑定类或 [`DataBindingUtil`](https://developer.android.google.cn/reference/androidx/databinding/DataBindingUtil) 类的 [`inflate()`](https://developer.android.google.cn/reference/androidx/databinding/DataBindingUtil#inflate(android.view.LayoutInflater, int, android.view.ViewGroup, boolean, android.databinding.DataBindingComponent)) 方法

```java
ListItemBinding binding = ListItemBinding.inflate(layoutInflater, viewGroup, false);
    // or
ListItemBinding binding = DataBindingUtil.inflate(layoutInflater, R.layout.list_item, viewGroup, false);
```

## 表达式语言

可以在表达式语言中使用以下运算符和关键字：

- 算术运算符 `+ - / * %`
- 字符串连接运算符 `+`
- 逻辑运算符 `&& ||`
- 二元运算符 `& | ^`
- 一元运算符 `+ - ! ~`
- 移位运算符 `>> >>> <<`
- 比较运算符 `== > < >= <=`（请注意，`<` 需要转义为 `<`）
- `instanceof`
- 分组运算符 `()`
- 字面量运算符 - 字符、字符串、数字、`null`
- 类型转换
- 方法调用
- 字段访问
- 数组访问 `[]`
- 三元运算符 `?:`

比如：

```xml
android:text="@{String.valueOf(index + 1)}"
android:visibility="@{age > 13 ? View.GONE : View.VISIBLE}"
android:transitionName='@{"image_" + id}'
```

不可以使用的表达式语言：

- `this`
- `super`
- `new`
- 显式泛型调用

#### **Null合并运算符**

如果左边运算数不是 `null`，则 Null 合并运算符 (`??`) 选择左边运算数，如果左边运算数为 null ，则选择右边运算数。

```xml
android:text="@{user.displayName ?? user.lastName}"
```

等价于

```xml
android:text="@{user.displayName != null ? user.displayName : user.lastName}"
```



### **属性引用**

表达式可以使用以下格式在类中引用属性，这对于字段、getter 和 [`ObservableField`](https://developer.android.google.cn/reference/androidx/databinding/ObservableField) 对象都一样：

```xml
android:text="@{user.lastName}"
```

### **避免出现 Null 指针异常**

生成的数据绑定代码会自动检查有没有 `null` 值并避免出现 Null 指针异常。例如，在表达式 `@{user.name}` 中，如果 `user` 为 Null，则为 `user.name` 分配默认值 `null`。如果您引用 `user.age`，其中 age 的类型为 `int`，则数据绑定使用默认值 `0`。

### 集合

为方便起见，可使用 `[]` 运算符访问常见集合，例如数组、列表、稀疏列表和映射。

```xml
<data>
        <import type="android.util.SparseArray"/>
        <import type="java.util.Map"/>
        <import type="java.util.List"/>
        <variable name="list" type="List&lt;String>"/>
        <variable name="sparse" type="SparseArray&lt;String>"/>
        <variable name="map" type="Map&lt;String, String>"/>
        <variable name="index" type="int"/>
        <variable name="key" type="String"/>
    </data>

 …
    android:text="@{list[index]}"
    …
    android:text="@{sparse[index]}"
    …
    android:text="@{map[key]}"
```

> 要使 XML 不含语法错误，必须转义 `<` 字符。例如：不要写成 `List<String>` 形式，而是必须写成 `List&lt;String>`。

还可以使用 `object.key` 表示法在映射中引用值。例如，以上示例中的 `@{map[key]}` 可替换为 `@{map.key}`。

### 字符串字面量

可以使用单引号括住特性值，这样就可以在表达式中使用双引号，如以下示例所示：

```xml
android:text='@{map["firstName"]}'
```

也可以使用双引号括住特性值。如果这样做，则应使用反单引号 ``` 将字符串字面量括起来：

```xml
android:text="@{map[`firstName`]}"
```

### **资源**

可以使用以下语法访问表达式中的资源：

```xml
android:padding="@{large? @dimen/largePadding : @dimen/smallPadding}"
```

格式字符串和复数形式可通过提供参数进行求值：

```xml
android:text="@{@string/nameFormat(firstName, lastName)}" android:text="@{@plurals/banana(bananaCount)}"
```

当一个复数带有多个参数时，应传递所有参数：

```xml
      Have an orange
      Have %d oranges

    android:text="@{@plurals/orange(orangeCount, orangeCount)}"
    
```

某些资源需要显式类型求值，如下表所示：

| 类型              | 常规引用  | 表达式引用         |
| :---------------- | :-------- | :----------------- |
| String[]          | @array    | @stringArray       |
| int[]             | @array    | @intArray          |
| TypedArray        | @array    | @typedArray        |
| Animator          | @animator | @animator          |
| StateListAnimator | @animator | @stateListAnimator |
| color int         | @color    | @color             |
| ColorStateList    | @color    | @colorStateList    |

