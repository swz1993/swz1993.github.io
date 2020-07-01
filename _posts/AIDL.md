好久之前学到的一个知识点，今天看书的时候发现忘掉了，所以做个笔记记录一下

# 一、概述
AIDL 意思即 Android Interface Definition Language，翻译过来就是Android接口定义语言，是用于定义服务器和客户端通信接口的一种描述语言，可以拿来生成用于IPC的代码。从某种意义上说AIDL其实是一个模板，因为在使用过程中，实际起作用的并不是AIDL文件，而是据此而生成的一个IInterface的实例代码，AIDL其实是为了避免我们重复编写代码而出现的一个模板

设计AIDL这门语言的目的就是为了实现进程间通信。在Android系统中，每个进程都运行在一块独立的内存中，在其中完成自己的各项活动，与其他进程都分隔开来。可是有时候我们又有应用间进行互动的需求，比较传递数据或者任务委托等，AIDL就是为了满足这种需求而诞生的。通过AIDL，可以在一个进程中获取另一个进程的数据和调用其暴露出来的方法，从而满足进程间通信的需求

通常，暴露方法给其他应用进行调用的应用称为服务端，调用其他应用的方法的应用称为客户端，客户端通过绑定服务端的Service来进行交互

# 二、语法
AIDL的语法十分简单，与Java语言基本保持一致，需要记住的规则有以下几点：

- AIDL文件以 .aidl 为后缀名

- AIDL支持的数据类型分为如下几种：

 - 八种基本数据类型：byte、char、short、int、long、float、double、boolean
String，CharSequence

 - 实现了Parcelable接口的数据类型
 - List 类型。List承载的数据必须是AIDL支持的类型，或者是其它声明的AIDL对象
 - Map类型。Map承载的数据必须是AIDL支持的类型，或者是其它声明的AIDL对象

- AIDL文件可以分为两类。一类用来声明实现了Parcelable接口的数据类型，以供其他AIDL文件使用那些非默认支持的数据类型。还有一类是用来定义接口方法，声明要暴露哪些接口给客户端调用，定向Tag就是用来标注这些方法的参数值

- 定向Tag。定向Tag表示在跨进程通信中数据的流向，用于标注方法的参数值，分为 in、out、inout 三种。其中 in 表示数据只能由客户端流向服务端， out 表示数据只能由服务端流向客户端，而 inout 则表示数据可在服务端与客户端之间双向流通。此外，如果AIDL方法接口的参数值类型是：基本数据类型、String、CharSequence或者其他AIDL文件定义的方法接口，那么这些参数值的定向 Tag 默认是且只能是 in，所以除了这些类型外，其他参数值都需要明确标注使用哪种定向Tag。定向Tag具体的使用差别后边会有介绍

- 明确导包。在AIDL文件中需要明确标明引用到的数据类型所在的包名，即使两个文件处在同个包名下

# 三 服务端编码

1、右键新建一个AIDL文件，命名为Book，创建完成后，系统就会默认创建一个 aidl 文件夹，文件夹下的目录结构即是工程的包名，Book.aidi 文件就在其中。

2、在Java文件下定义一个book类，此book类的路径要与aidl中的路径相同，并且 book 要实现 Parcelable 接口，以方便跨进程传输。

```java

import android.os.Parcel;
import android.os.Parcelable;

public class Book implements Parcelable {

    private String name;

    private int age;


    public Book(String name,int age){
        this.name = name;
        this.age = age;
    }



    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {

        dest.writeString(name);
        dest.writeInt(age);

    }

    /**
     *防止生成的 aidl 报以下错误：
     * 错误: 找不到符号
     * 符号: 方法 readFromParcel(Parcel)
     * 位置: 类型为Book的变量 book
     * */

    public void readFromParcel(Parcel in){
        name = in.readString();
        age = in.readInt();
    }


    private Book(Parcel source){
        name = source.readString();
        age = source.readInt();
    }

    public static final Creator<Book> CREATOR = new Creator<Book>() {
        @Override
        public Book createFromParcel(Parcel source) {
            return new Book(source);
        }

        @Override
        public Book[] newArray(int size) {
            return new Book[size];
        }
    };

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

3、修改 Book.aidl 文件，将之改为声明Parcelable数据类型的AIDL文件,注意此处的 parcelable 为小写

```java
// Book.aidl
package com.tobebest.sj.mydemoapplication;

// Declare any non-default types here with import statements

parcelable Book;
```

> 写到这可以发现Java中的Book类出现了错误，此时重新build一下项目就可以

4、此外，根据一开始的设想，服务端需要暴露给客户端一个获取书籍列表以及一个添加书籍的方法，这两个方法首先要定义在AIDL文件中，命名为 BookController.aidl，注意这里需要明确导包

```Java
// BookController.aidl
package com.tobebest.sj.mydemoapplication;

import com.tobebest.sj.mydemoapplication.Book;

// Declare any non-default types here with import statements

interface BookController {

   List<Book> getBookList();

   void addBookInOut(inout Book book);

}
```
上面说过，在进程间通信中真正起作用的并不是 AIDL 文件，而是系统据此而生成的文件，可以在以下目录中查看系统生成的文件。之后需要使用到当中的内部静态抽象类 Stub

创建或修改过AIDL文件后需要clean下工程，使系统及时生成我们需要的文件

5、 创建一个 Service 供客户端远程绑定，这里命名为 AIDLService

```Java
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;

import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

public class AIDLService extends Service {

    private final String TAG = getClass().getSimpleName();

    private List<Book> bookList;

    private AIDLService(){}

    @Override
    public void onCreate() {
        super.onCreate();
        bookList = new ArrayList<>();
        initData();
    }

    private void initData(){
        Book book1 = new Book("shi",18);
        Book book2 = new Book("wei",20);
        Book book3 = new Book("zhi",27);
        bookList.add(book1);
        bookList.add(book2);
        bookList.add(book3);
    }

    private BookController.Stub stub = new BookController.Stub() {
        @Override
        public List<Book> getBookList() throws RemoteException {
            return bookList;
        }

        @Override
        public void addBookInOut(Book book) throws RemoteException {
            if (book != null) {
                book.setName("服务器改了新书的名字 InOut");
                bookList.add(book);
            } else {
                Log.e(TAG, "接收到了一个空对象 InOut");
            }
        }
    };

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return stub;
    }
}

```
可以看到， onBind 方法返回的就是 BookController.Stub 对象，实现当中定义的两个方法

6、服务端还有一个地方需要注意，因为服务端的Service需要被客户端来远程绑定，所以客户端要能够找到这个Service，可以通过先指定包名，之后再配置Action值或者直接指定Service类名的方式来绑定Service
如果是通过指定Action值的方式来绑定Service，那还需要将Service的声明改为如下所示：

```xml
<service android:name=".AIDLService"
            android:enabled="true"
            android:exported="true"
            android:process=":remote">

            <intent-filter>

                <action android:name="com.tobebest.sj.mydemoapplication.AIDLService"/>
                <category android:name="android.intent.category.DEFAULT"/>

            </intent-filter>

</service>
```
# 四、 客户端编码

客户端需要再创建一个工程，在app文件夹点击右键-->new Modul就行了。然后把服务的AIDL文件以及Book类复制过来，将 aidl 文件夹整个复制到和Java文件夹同个层级下，不需要改动任何代码。之后，需要创建和服务端Book类所在的相同包名来存放 Book 类。修改布局文件，添加两个按钮：

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical">

    <Button
        android:id="@+id/btn_getBookList"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="获取书籍列表" />

    <Button
        android:id="@+id/btn_addBook_inOut"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="InOut 添加书籍" />

</LinearLayout>
```

最后编写代码

```java
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;
import android.view.View;

import com.tobebest.sj.mydemoapplication.Book;
import com.tobebest.sj.mydemoapplication.BookController;

import java.util.List;

public class MainActivity extends AppCompatActivity {

    private final String TAG = "Client";

    private BookController bookController;

    private boolean connected;

    private List<Book> bookList;

    private ServiceConnection serviceConnection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            bookController = BookController.Stub.asInterface(service);
            connected = true;
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            connected = false;
        }
    };

    private View.OnClickListener clickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            switch (v.getId()) {
                case R.id.btn_getBookList:
                    if (connected) {
                        try {
                            bookList = bookController.getBookList();
                        } catch (RemoteException e) {
                            e.printStackTrace();
                        }
                        log();
                    }
                    break;
                case R.id.btn_addBook_inOut:
                    if (connected) {
                        Book book = new Book("sj",27);
                        try {
                            bookController.addBookInOut(book);
                            Log.e(TAG, "向服务器以InOut方式添加了一本新书");
                            Log.e(TAG, "新书名：" + book.getName());
                        } catch (RemoteException e) {
                            e.printStackTrace();
                        }
                    }
                    break;
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        findViewById(R.id.btn_getBookList).setOnClickListener(clickListener);
        findViewById(R.id.btn_addBook_inOut).setOnClickListener(clickListener);
        bindService();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (connected) {
            unbindService(serviceConnection);
        }
    }

    private void bindService() {
        Intent intent = new Intent();
        intent.setPackage("com.tobebest.sj.mydemoapplication");
        intent.setAction("com.tobebest.sj.mydemoapplication.action");
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
    }

    private void log() {
        for (Book book : bookList) {
            Log.e(TAG, book.toString());
        }
    }
}
```
