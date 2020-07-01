通过Java的反射机制，可以在程序中访问已经装载到jvm中Java对象的描述，实现访问、检测和修改Java对象本身信息的功能。

## 反射的相关方法

可以通过getClass()方法返回某个类的Class对象，利用Class对象，可以获得类的描述信息，具体有以下几方面：

### 构造方法

利用下列的方法，将返回Constructor的对象或数组，每个Constructor对象代表一个构造方法：

1、getConstructors():获取所有权限为public的构造方法

2、getConstructors(Class<?>...parameterTypes):获取权限为public的指定的构造方法

3、getDeclaredConstructors():获取所有构造方法，按声明次序返回

4、getDeclaredConstructors(Class<?>...parameterTypes):获取指定的构造方法

其中，**Constructor类中的提供的常用方法**如下：

1、isVarArgs():查看该构造方法是否允许带有可变数量的参数(true/false)

2、getParameterTypes():按照声明顺序以Class数组的形式获得该构造方法的各个参数的类型

3、getExceptionTypes():以Class数组的形式获取该构造方法可能抛出的异常类型

4、newInstance(Object...initargs):通过该构造方法利用指定参数创建一个该类的对象，未设置参数表示使用默认的无参构造

5、setAccessable(boolean flag):如果该构造方法的权限为private，则先执行此方法，将参数设为true，则可以用上个方法创建一个对象，否则不能

6、getModifiers():获得可以解析出该构造方法所采用的修饰符的整数

通过java.lang.reflect.Modifier类可以解析出getModifiers()方法的返回值所表示的修饰符信息：isPublic(int mod)/isProtected(int mod)/isPrivate(int mod)/isStatic(int mod)/isFinal(int mod)/toString(int mod)(以字符串的形式返回所有的修饰符)

### 普通方法

返回Method类型的对象或数组：

1、getMethods():获取所有权限为public的方法

2、getMethod(String name,Class<?>...parameterTypes):获取权限为punilc的指定方法

3、getDeclaredMethods():获取所有方法，按声明次序返回

4、getDeclaredMethod(String name,Class<?>...parameterTypes):获取指定方法

**Method中提供的常用方法**为：

1、getName():获取该方法的名称

2、getParameterTypes():按照声明顺序以Class数组的形式获得该构造方法的各个参数的类型

3、getReturnType():以Class对象的形式获取该方法的返回值类型

4、getExceptionTypes():以Class数组的形式获取该构造方法可能抛出的异常类型

5、isVarArgs():查看该构造方法是否允许带有可变数量的参数(true/false)

6、getModifiers():获得可以解析出该构造方法所采用的修饰符的整数

7、invoke(Object obj,Object...args):利用指定参数args执行指定对象obj中的该方法，返回值为Object类型


### 成员变量

访问成员变量时，将返回Field类型的对象或数组。每个Field对象代表一个成员变量

1、getFields():获取所有权限为public的成员变量

2、getField(String name):获取权限为public的指定的成员变量

3、getDeclaredFields():获取所有的成员变量，按声明顺序返回

4、getDeclaredField(String name):获取指定的成员变量

**Field中提供的常用方法**如下：

1、getName():获取成员变量的名称

2、getType():获取成员变量类型的Class对象

3、get(Object obj):获取指定对象obj中的值

4、set(Object obj,Object value):将指定对象obj中成员变量的值设为value

5、getInt(Object obj)/setInt(Object obj,int i):获取/设置指定对象obj中类型为int的成员变量的值(同理的还有Float和Boolean)

6、setAccessible(boolean flag):设置是否可以忽略权限限制去访问private等私有权限的成员变量

7、getModifiers():获取可以解析出该成员变量所采用的修饰符的整数

### 内部类

1、getClasses():获取所有权限为public的内部类

2、getDeclaredClasses():获取所有的内部类

### 内部类的声明类

getDeclaringClass():如果该类为内部类，返回它的成员类，否则，返回null

### 其他

1、getPackage():获取该类的存放路径

2、getName():获取该类的名称

3、getSuperClass():获取该类继承的类

4、getInterfaces():获取该类实现的接口