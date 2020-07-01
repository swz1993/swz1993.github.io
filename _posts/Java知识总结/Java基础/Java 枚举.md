枚举使用enum关键字来定义，枚举的定义如下:

```
enum Constants{

  A,B

}
```
如果把枚举按照类来看待的话，每一个枚举类型成员都可以看成是枚举类型的一个实例，这些枚举类型成员都默认被public、static、final修饰。所有，当使用枚举类型成员时，可以直接使用枚举类型名称调用枚举类型成员。

枚举类型中的常用方法有：

1、values():将枚举类型成员以数组的形式返回

2、valueOf():将普通的字符串转换为枚举实例

3、compareTo():比较两个枚举常量在定义时的顺序，返回结果为正值，代表参数在调用该方法的枚举对象之前的位置，0为相同，负值为后。

4、ordinal():获取枚举常量的位置索引

## 在枚举中添加构造方法

```
public enum Menum {

    GREEN("green"), RED("red"), YELLOW("yellow"), BLACK("black"), WHITE("white");

    private String name;


    //参数类型与enum中枚举常量后面括号中跟着的类型相同
    Menum(String name) {

        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    /**
     * 根据类型的名称，返回类型的枚举实例。
     *
     * @param typeName 类型名称
     */
    public static Menum fromTypeName(String typeName) {
        for (Menum type : Menum.values()) {
            if (type.getName().equals(typeName)) {
                return type;
            }
        }
        return null;
    }
}
```
要注意枚举常量用","隔开，最后一个枚举常量后面还要加";"。枚举类的构造函数强制为private，以防止在代码中实例化一个枚举对象。枚举常量位于枚举类的第一行。

可以定义一个接口，在接口中定义泛型中公用的方法，然后用一个泛型类实现该方法，并在其泛型常量中重写该方法：

```
interface  d{
    void a();
    void b();
}

public enum Menum implements d{

    GREEN{
        @Override
        public void a() {

        }

        @Override
        public void b() {

        }
    };

    Menum() {

    }
}    
```

枚举的优势有：类型安全；紧凑有效的数据定义；可以和程序其他部分完美交互；运行效率高效。


