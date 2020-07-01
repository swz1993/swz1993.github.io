# 2.1 Android IPC简介

IPC(Inter-Process Communication)含义为进程间通信或者跨进程通讯，是指两个进程间进行数据交换的过程。

**线程**：CPU调度的最小单元，是一种有限的系统资源

**进程**：是指一个执行单元，在PC和移动设备上指一个程序或者应用

IPC并不是Android所独有的，Linux上可以通过命名管道、共享内容和信号量等来进行进程间通信。Android是一种基于Linux内核的移动操作系统，它的进程间通信方式并不是完全继承自Linux，相反，他有自己的进程间通信方式：Binder和Socket。

# 2.2 Android 中的多进程模式

在Android中，给四大组件指定android:process属性，我们就可以开启多进程模式。

## 2.2.1 开启多进程模式

正常情况下，Android多进程是指一个应用中存在多个进程的情况(还有不同应用之间)。首先，在Android中使用多进程的方式只有一种办法，那就是在AndroidMenifest中指定**android:process**属性。另外一种非常规的多进程方法是通过JNI在native层去fork一个新的进程。

默认进程的名称为**包名**，**android:process**的进程名以":"开头进程属于当前应用的私有进程，其他应用的组件不能和他跑在同一个进程中，而进程名不以":"开头的进程属于全局进程，其他应用通过ShareUID方式可以和它跑在同一个进程中。我们知道Android系统会为每个应用分配一个唯一的UID，具有相同UID的应用才能共享数据。两个应用具有相同的ShareID并且签名相同才能跑在同一个进程中，它们不仅能共享data目录和组件信息等，还可以共享内存数据。

## 2.2.2 多进程模式的运行机制

我们知道Android为每个应用分配了一个独立的虚拟机，或者说为每个进程分配了一个独立的虚拟机，不同的虚拟机在内存分配有不同的地址空间，这就导致在不同的虚拟机中访问同一个类的对象会产生多份副本，每个类的副本互不干扰。一般来说，使用多进程会造成如下几个方面的问题：

- 静态成员和单例模式完全失效
- 线程同步机制完全失效(不在同一块内存中，不同进程锁的不是同一个对象)
- SharePreferences的可靠性下降(SharePreferences不支持两个进程同时执行写操作)
- Application会多次创建(一个组件跑在一个新的进程中，由于系统要在创建新的进程的同时分配独立的虚拟机，所以这个过程就是启动一个应用的过程)

我们不能应为多进程有很多问题就不去重视它，为了解决这个问题，系统提供了很多跨进程通信方法，比如通过Intent来传递数据，共享文件和SharedPreferences，基于Binder的Messenger和AIDL和Socket等。

## 2.3 IPC基础概念介绍

Serializable和Parcelable接口可以完成对象的序列化过程，当我们需要通过Intent和Binder传输数据时就需要使用Parcelable或者Serializable。还有的时候我们需要把对象持久化到存储设备上或者通过网络传输给其他客户端，这个时候也需要使用Serializable来完成对象的持久化。

### 2.3.1 Serializable 接口

Serializable 是Java提供的一个序列化接口，它是一个空接口，为对象提供标准的序列化和反序列化操作。使用 Serializable 来实现序列化只需要在类实现 Serializable 接口，并声明中指定类似下面的标识即可自动实现默认的序列化过程。

```java
public class User implements Serializable{

 private static final long serialVersionUID = xxxxxxxxxxxxxxxxxxxxxL;(数字)

 private int userId;
 private String userName;
 private boolean isMale;
 ...
}
```

序列化和反序列化的过程为：

```java

//序列化过程User
User user = new User();
ObjectOutPutStream out = new ObjectOutPutStream(new FileOutputStream("cache.text"));
out.writeObject(user);
out.close();


//反序列化过程
ObjectInputStream in = new ObjectInputStream(new FileInputStream("cache.text"));
User newUser = (User)in.readObject();
in.close();

```

实际上 serialVersionUID 并不是必须的,，原则上序列化后的数据中的 serialVersionUID 只有和当前类的 serialVersionUID 一致的时候才能正常的被反序列化。其详细的工作机制是：序列化的时候会将当前类的 serialVersionUID 写入序列化的文件中，当反序列化的时候系统会去检测文件中的 serialVersionUID 看他是否和当前类的版本是否相同。如果相同，就说明序列化的类的版本和当前类的版本是相同的，这个时候可以成功反序列化；否则就说明当前类的序列化的类相比发生了某些变化，比如成员变量的数量和类型发生了变化，这个时候无法正常的反序列化，会报错。

一般来说，我们应该手动指定 serialVersionUID 的值，也可以让IDE根据当前类的结构自动去生成它的hash值，这样序列化和反序列化的时候两者的 serialVersionUID 是一样的，这样就可以正常的反序列化。如果不手动指定 serialVersionUID 的值，反序列化的时候，如果类有所改变，系统就会重新计算其hash值并将其赋给 serialVersionUID 值，这样由于 serialVersionUID 不同，就会反序列化失败。当然，如果一个类发生了非常规性变化，比如修改了类名或者修改了成员变量的类型，那么即使 serialVersionUID 验证成功，也会反序列化失败。

> 静态成员属于类但不属于对象，所以不会参与序列化的过程；其次，用transient关键字标记的成员也不会参与序列化的过程

另外，系统的默认序列化过程也是可以改变的，只要重写writeObject()和readObject()方法即可。

### 2.3.2 Parcelable 接口

Parcelable 也是一个接口，类可以实现这个接口来实现序列化。下面是一种典型的示例：

```java
public class User implements Parcelable {

    private int userId;
    private String userName;
    private boolean isMale;

    private Book book;

    public User(int userId, String userName, boolean isMale) {
        this.userId = userId;
        this.userName = userName;
        this.isMale = isMale;
    }

    /**
     * 描述此Parcelable实例的封送处理表示中包含的特殊对象的类型。
     * 例如，如果对象将在{@link#writeToParcel（Parcel，int）}的输出中包含一个文件描述符，
     * 则此方法的返回值必须包含{@link#CONTENTS_file_descriptor}位。
     * */

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {

        dest.writeInt(userId);
        dest.writeString(userName);
        dest.writeInt(isMale ? 1 : 0);
        dest.writeParcelable(book, 0);

    }

    private User(Parcel in) {

        userId = in.readInt();
        userName = in.readString();
        isMale = in.readInt() == 1;
        book = in.readParcelable(Thread.currentThread().getContextClassLoader());

    }

    public static final Parcelable.Creator<User> CREATOR = new Parcelable.Creator<User>() {
        @Override
        public User createFromParcel(Parcel source) {
            return new User(source);
        }

        @Override
        public User[] newArray(int size) {
            return new User[size];
        }
    };

    private class Book implements Parcelable {

        @Override
        public int describeContents() {
            return 0;
        }

        @Override
        public void writeToParcel(Parcel dest, int flags) {

        }
    }
}
```
Parcel内部包装了可序列化的数据，可以在Binder中自由的传输。从上述代码中可以看出，序列化功能由writeToParcel方法来完成，最终是通过Parcel中的一系列write方法来完成的；反序列化功能由CREATOR来完成，其内部标明了如何创建序列化对象和数组，并通过Parcel的一系列read方法来完成；内容描述功能由describeContents方法来完成，几乎在所有的情况下这个方法都应该返回0，仅当当前对象中存在文件描述符时，此方法返回1。

> 在User(Parcel in)方法中，由于book是另一个可序列化对象，所以它的反序列化过程需要传递当前线程的上下文类加载器，否则会报无法找到类的错误。

|方法|功能|标记位|
|:---:|:---:|:---:|
| createFromParcel(Parcel in)| 从序列化后的对象中创建原始对象                                                                                                      |                               |
| newArray(int siez)                  | 创建指定长度的原始对象数组                                                                                                          |                               |
| User(Parcel in)                     | 从序列化后的对象中创建原始对象                                                                                                      |                               |
| writeToParcel(Parcel out,int flags) | 将当前对象写入序列化结构中，其中flags标识有两种值：0或者1，为1时标识当前对象需要作为返回值返回，不能立即释放资源，几乎所有情况都为0 | PARCELABLE_WRITE_RETURN_VALUE |
| describeContents| 返回当前对象的内容描述。如果含有文件描述符，返回1，否则返回0，几乎所有情况都返回0| CONTENTS_FILE_DESCRIPTOR      |

系统已经为我们提供了许多实现了Parcelable接口的类，它们都是可序列化的，比如Intent、Bundle和Bitmap等，同时List和Map也可以序列化，前提是他们里面的每个元素都是可序列化的。

* Parcelable和Serializable都能实现序列化并且都可用于Intent间的数据传递，那么如何选取呢？

Serializable是Java中的序列化接口，使用简单但是开销大，序列化和反序列化过程中需要大量的I/O操作。Parcelable是Android中的序列化方式，缺点是使用起来稍微麻烦点，但是效率很高，这是Android推荐的序列化方式，因此我们要首选Parcelable。Parcelable主要是用在内存序列化上，通过Parcelable将对象序列化到存储设备中或者将对象序列化后通过网络传输也都是可以的，但这个过程会稍显复杂，因此在这两种情况下建议使用Serializable。

### 2.3.3 Binder

Binder是Android中的一个类，它实现了IBinder接口。
