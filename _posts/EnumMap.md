##Java Enum原理 
```
public enum Size{ SMALL, MEDIUM, LARGE, EXTRA_LARGE };
```
实际上，这个声明定义的类型是一个类，它刚好有四个实例，在此尽量不要构造新对象。

因此，在比较两个枚举类型的值时，永远不需要调用equals方法，而直接使用"=="就可以了。(equals()方法也是直接使用==,  两者是一样的效果)

Java Enum类型的语法结构尽管和java类的语法不一样，应该说差别比较大。但是经过编译器编译之后产生的是一个class文件。该class文件经过反编译可以看到实际上是生成了一个类，该类继承了java.lang.Enum<E>。

  例如：

```
public enum WeekDay { 
     Mon("Monday"), Tue("Tuesday"), Wed("Wednesday"), Thu("Thursday"), Fri( "Friday"), Sat("Saturday"), Sun("Sunday"); 
     private final String day; 
     private WeekDay(String day) { 
            this.day = day; 
     } 
    public static void printDay(int i){ 
       switch(i){ 
           case 1: System.out.println(WeekDay.Mon); break; 
           case 2: System.out.println(WeekDay.Tue);break; 
           case 3: System.out.println(WeekDay.Wed);break; 
            case 4: System.out.println(WeekDay.Thu);break; 
           case 5: System.out.println(WeekDay.Fri);break; 
           case 6: System.out.println(WeekDay.Sat);break; 
            case 7: System.out.println(WeekDay.Sun);break; 
           default:System.out.println("wrong number!"); 
         } 
     } 
    public String getDay() { 
        return day; 
     } 
}
```
WeekDay经过反编译(javap WeekDay命令)之后得到的内容如下(去掉了汇编代码)：

```
public final class WeekDay extends java.lang.Enum{ 
    public static final WeekDay Mon; 
    public static final WeekDay Tue; 
    public static final WeekDay Wed; 
    public static final WeekDay Thu; 
    public static final WeekDay Fri; 
    public static final WeekDay Sat; 
    public static final WeekDay Sun; 
    static {}; 
    public static void printDay(int); 
    public java.lang.String getDay(); 
    public static WeekDay[] values(); 
    public static WeekDay valueOf(java.lang.String); 
}
```
### 用法一：常量

在JDK1.5 之前，我们定义常量都是： public static fianl.... 。现在好了，有了枚举，可以把相关的常量分组到一个枚举类型里，而且枚举提供了比常量更多的方法。
```
public enum Color {  
  RED, GREEN, BLANK, YELLOW  
}
```
### 用法二：switch

JDK1.6之前的switch语句只支持int,char,enum类型，使用枚举，能让我们的代码可读性更强。

```
enum Signal {
        GREEN, YELLOW, RED
    }

    public class TrafficLight {
        Signal color = Signal.RED;

        public void change() {
            switch (color) {
            case RED:
                color = Signal.GREEN;
                break;
            case YELLOW:
                color = Signal.RED;
                break;
            case GREEN:
                color = Signal.YELLOW;
                break;
            }
        }
    }
```
### 用法三：向枚举中添加新方法

如果打算自定义自己的方法，那么必须在enum实例序列的最后添加一个分号。而且 Java 要求必须先定义 enum 实例。

```
public enum Color {
    RED("红色", 1), GREEN("绿色", 2), BLANK("白色", 3), YELLO("黄色", 4);
    // 成员变量
    private String name;
    private int index;

    // 构造方法
    private Color(String name, int index) {
        this.name = name;
        this.index = index;
    }

    // 普通方法
    public static String getName(int index) {
        for (Color c : Color.values()) {
        if (c.getIndex() == index) {
            return c.name;
        }
        }
        return null;
    }

    // get set 方法
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getIndex() {
        return index;
    }

    public void setIndex(int index) {
        this.index = index;
    }
    }
```
### 用法四：覆盖枚举的方法

下面给出一个toString()方法覆盖的例子。

```
public class Test {
    public enum Color {
        RED("红色", 1), GREEN("绿色", 2), BLANK("白色", 3), YELLO("黄色", 4);
        // 成员变量
        private String name;
        private int index;

        // 构造方法
        private Color(String name, int index) {
            this.name = name;
            this.index = index;
        }

        // 覆盖方法
        @Override
        public String toString() {
            return this.index + "_" + this.name;
        }
    }

    public static void main(String[] args) {
        System.out.println(Color.RED.toString());
    }
}
```
### 用法五：实现接口

所有的枚举都继承自java.lang.Enum类。由于Java 不支持多继承，所以枚举对象不能再继承其他类。

```
public interface Behaviour {
    void print();

    String getInfo();
    }

    public enum Color implements Behaviour {
    RED("红色", 1), GREEN("绿色", 2), BLANK("白色", 3), YELLO("黄色", 4);
    // 成员变量
    private String name;
    private int index;

    // 构造方法
    private Color(String name, int index) {
        this.name = name;
        this.index = index;
    }

    // 接口方法

    @Override
    public String getInfo() {
        return this.name;
    }

    // 接口方法
    @Override
    public void print() {
        System.out.println(this.index + ":" + this.name);
    }
    }
```
### 用法六：使用接口组织枚举 

```
public interface Food {
        enum Coffee implements Food {
            BLACK_COFFEE, DECAF_COFFEE, LATTE, CAPPUCCINO
        }

        enum Dessert implements Food {
            FRUIT, CAKE, GELATO
        }
    }
```
### 用法七：关于枚举集合的使用

java.util.EnumSet和java.util.EnumMap是两个枚举集合。EnumSet保证集合中的元素不重复;EnumMap中的 key是enum类型，而value则可以是任意类型。关于这个两个集合的使用就不在这里赘述，

## EnumMap

Map的实现类有很多种，EnumMap从名字我们可以看出这个Map是给枚举类用的。它的key为枚举元素，value自定义。在工作中我们也可以用其他的Map来实现我们关于枚举的需求，但是为什么要用这个EnumMap呢？因为它的性能高！为什么性能高？因为它的内部是用数组的数据结构来维护的！我们可以看一下它的源码实现：

**put方法**

```
    public V put(K key, V value) {
        typeCheck(key);

        int index = key.ordinal();
        Object oldValue = vals[index];
        vals[index] = maskNull(value);
        if (oldValue == null)
            size++;
        return unmaskNull(oldValue);
    }
```

typeCheck是用来检查key的类型的，因为key只能为枚举元素。接下来的这一句int index = key.ordinal();key.ordinal()这个就是我们上面说的枚举类型的序号，然后被当做数组的下标，放到vals这个数组里。那么get方法呢？

**get方法**

```
    public V get(Object key) {
        return (isValidKey(key) ?
                unmaskNull(vals[((Enum<?>)key).ordinal()]) : null);
    }
```

注意这一句话：vals[((Enum<?>)key).ordinal()]。这个不就是取得下标，根据下标获取数组中的值吗？！


**remove方法**

```
    public V remove(Object key) {
        if (!isValidKey(key))
            return null;
        int index = ((Enum<?>)key).ordinal();
        Object oldValue = vals[index];
        vals[index] = null;
        if (oldValue != null)
            size--;
        return unmaskNull(oldValue);
    }
```
remove方法的实现也是挺简单的，就是把相应下标的元素变为null，等着GC回收。
这里我们只是说了EnumMap里比较常用的三个方法，如果有兴趣的同学可以看看其他的方法实现。

一个使用EnumMap的例子奉上：

```
EnumMap<EnumTest01, String> enumMap = new EnumMap<EnumTest01, String>(EnumTest01.class);
enumMap.put(EnumTest01.UPDATE, "qqqqqq");
    for (Map.Entry<EnumTest01, String> entry : enumMap.entrySet()) {
            System.out.println(entry.getValue() + entry.getKey().getEnumDesc());
        }
```
 
## EnumSet

EnumSet这是一个用来操作Enum的集合，是一个抽象类，它有两个继承类：JumboEnumSet和RegularEnumSet。在使用的时候，需要制定枚举类型。它的特点也是速度非常快，为什么速度很快呢？因为每次add的时候，每个枚举值只占一个长整型的一位。我们可以翻看源码来看看它的实现：


**add方法**

```
    public boolean add(E e) {
        typeCheck(e);

        long oldElements = elements;
        elements |= (1L << ((Enum<?>)e).ordinal());
        return elements != oldElements;
    }
```

从中我们可以看出是先对一个长整型左移枚举类型的序列数.

**of方法**

of方法有好几个重载的方法，它的作用是创建一个最初包含指定元素的枚举 set。

```
EnumSet<EnumTest01> enumSets = EnumSet.of(EnumTest01.DELETE);
```

**allOf**

创建一个包含指定元素类型的所有元素的枚举 set。

```
EnumSet<EnumTest01> enumSets = EnumSet.allOf(EnumTest01.class);
```

**range方法**

创建一个指定范围的Set。

```
EnumSet<EnumTest01> enumSets = EnumSet.range(EnumTest01.DELETE,EnumTest01.UPDATE);
```

**noneOf方法**

创建一个指定枚举类型的空set。

```
EnumSet<EnumTest01> enumSet = EnumSet.noneOf(EnumTest01.class);
enumSet.add(EnumTest01.DELETE);
enumSet.add(EnumTest01.UPDATE);
for (Iterator<EnumTest01> it = enumSet.iterator(); it.hasNext();) {
            System.out.println(it.next().getEnumDesc());
        }
        for (EnumTest01 enumTest : enumSet) {
            System.out.println(enumTest.getEnumDesc() + "  ..... ");
        }
```
**copyOf**

创建一个set的并copy所传入的集合中的枚举元素。

```
EnumSet<EnumTest01> enumSets = EnumSet.copyOf(enumSet);
```


### 完整示例代码

枚举类型的完整演示代码如下：

```
public class LightTest {

    // 1.定义枚举类型

    public enum Light {

    // 利用构造函数传参

    RED(1), GREEN(3), YELLOW(2);

    // 定义私有变量

    private int nCode;

    // 构造函数，枚举类型只能为私有

    private Light(int _nCode) {

        this.nCode = _nCode;

    }

    @Override
    public String toString() {

        return String.valueOf(this.nCode);

    }

    }

    /**
     * 
     * @param args
     */

    public static void main(String[] args) {

    // 1.遍历枚举类型

    System.out.println("演示枚举类型的遍历 ......");

    testTraversalEnum();

    // 2.演示EnumMap对象的使用

    System.out.println("演示EnmuMap对象的使用和遍历.....");

    testEnumMap();

    // 3.演示EnmuSet的使用

    System.out.println("演示EnmuSet对象的使用和遍历.....");

    testEnumSet();

    }

    /**
     * 
     * 演示枚举类型的遍历
     */

    private static void testTraversalEnum() {

    Light[] allLight = Light.values();

    for (Light aLight : allLight) {

        System.out.println("当前灯name：" + aLight.name());

        System.out.println("当前灯ordinal：" + aLight.ordinal());

        System.out.println("当前灯：" + aLight);

    }

    }

    /**
     * 
     * 演示EnumMap的使用，EnumMap跟HashMap的使用差不多，只不过key要是枚举类型
     */

    private static void testEnumMap() {

    // 1.演示定义EnumMap对象，EnumMap对象的构造函数需要参数传入,默认是key的类的类型

    EnumMap<Light, String> currEnumMap = new EnumMap<Light, String>(

    Light.class);

    currEnumMap.put(Light.RED, "红灯");

    currEnumMap.put(Light.GREEN, "绿灯");

    currEnumMap.put(Light.YELLOW, "黄灯");

    // 2.遍历对象

    for (Light aLight : Light.values()) {

        System.out.println("[key=" + aLight.name() + ",value="

        + currEnumMap.get(aLight) + "]");

    }

    }

    /**
     * 
     * 演示EnumSet如何使用，EnumSet是一个抽象类，获取一个类型的枚举类型内容<BR/>
     * 
     * 可以使用allOf方法
     */

    private static void testEnumSet() {

    EnumSet<Light> currEnumSet = EnumSet.allOf(Light.class);

    for (Light aLightSetElement : currEnumSet) {

        System.out.println("当前EnumSet中数据为：" + aLightSetElement);

    }

    }

}
```
执行结果如下：

```
演示枚举类型的遍历 ......

当前灯name：RED

当前灯ordinal：0

当前灯：1

当前灯name：GREEN

当前灯ordinal：1

当前灯：3

当前灯name：YELLOW

当前灯ordinal：2

当前灯：2

演示EnmuMap对象的使用和遍历.....

[key=RED,value=红灯]

[key=GREEN,value=绿灯]

[key=YELLOW,value=黄灯]

演示EnmuSet对象的使用和遍历.....

当前EnumSet中数据为：1

当前EnumSet中数据为：3

当前EnumSet中数据为：2
```