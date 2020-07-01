流是一组有序的数据序列，根据操作类型，可以分为输入流和输出流。在Java中，负责流的类都位于java.io包中，其中，所有输入流的类都是抽象类InputStream(字节输入流)和抽象类Reader(字符输入流)的子类。所有的输出流都是抽象类OutputStream(字节输出流)和抽象类Writer(字符输出流)的子类。

## 输入输出流

### 输入流

InputStream是字节输入流的抽象类，也是所有字节输入流的父类。该类的所有方法遇到异常时会抛出IOException异常。该类的部分方法如下：

1、read():从输入流中读取下个字节，返回0～255间的int字节值，如果到达流末尾，则返回-1

2、read(byte[] b):从输入流中读取一定长度的字节

3、mark(int readlimit):在输入流的当前位置放置一个标记，readlimit告知此输入流在标记位置失效之前允许读取的字节数

4、reset():将输入指针返回当前所做的标记处

5、skip(long n):跳过输入流上的n个字节，并且返回实际跳过的字节数

6、markSupported():如果当前流支持mark()/reset()操作就返回true

7、close():关闭此输入流并释放资源

>skip()、mark()及reset()等方法只对某些子类有用

Java中的字符时Unicode编码的，是双字节。InputStream用来处理字节，Java中用Reader处理字符。方法跟InputStream类似。

## 输出流

OutputStream是字节输出流的抽象类，是所有字节输出流的父类。方法有:

1、write(int b):将指定的字节写入此输入流

2、write(byte [] b):将b个字节从指定的byte数组中写入此输入流

3、write(byte [] b,int off,int len):将指定的数组从off开始的len个字节写入此输出流

4、flush():彻底完成输出且清空缓冲区

5、close():关闭输出流

Writer是字符输出流

## File类

主要用来获取文件本身的一些信息。

### 文件的创建和删除

可以使用File类创建一个文件对象，通常有以下几种方式：

1、File(String pathname):使用指定路径名来创建一个File

2、File(String parent,String child):根据定一个父路径和子路径来创建一个File

3、File(File e,String child):根据e的抽象路径名和child路径名创建一个File

如果当前不存在某个文件，可以通过createNewFile()方法创建一个文件，如果文件存在，可以用delete()将其删除

### 获取文件信息

1、getName():获取文件的名称

2、canRead()/canWrite():判断文件是否为可读/可写

3、exits():判断文件是否存在

4、length():获取文件的长度，以字节为单位

5、getAbsolutePath():获取文件的绝对路径

6、getParent():获取文件的父路径

7、isFile():判断文件是否存在

8、isDirectory():判断文件是否为一个目录(文件夹)

9、isHidden():判断是否为隐藏文件

10、lastModified():获取文件的最后修改时间

## 文件输入/输出流

可以使用文件输入/输出流与指定文件建立连接，将需要的数据永久保存到文件中。

### FileInputStreeam/FileOutputStream

负责字节类型的文件。

FileInputStreeam的构造方法：

1、FileInputStreeam(String name):使用指定的name创建一个文件

2、FileInputStreeam(File file):使用file对象创建一个文件

FileOutputStream构造方法与其相同，但是，FileOutputStream可以指定一个不存在的文件名，但此文件不能是一个已被其他程序打开的文件。

### FileReader/FileWriter

用来处理字符构造方法与上面的相同，FileReader顺序读取文件，只要不关闭流，每次调用read()方法就顺序的读取源中剩余的内容，直到末尾或者流关闭。

## 带缓存的输入/输出流

缓存流为I/O流增加了内存缓存区，使得在流上执行skip、mark和reset方法成为可能。

### BufferedInputStream/BufferOutputStream

BufferedInputStream构造方法：

1、BufferedInputStream(InputStream in):创建一个带有32位字节的缓存流

2、BufferedInputStream(InputStream in,int size):按指定大小创建缓存区

BufferOutputStream与其类似。BufferedInputStream位于InputStream之前，BufferOutputStream与OutputStream输出一样，不过可以用flush 方法将缓存区的数据强制输出完。

### BufferReader/BufferWriter

BufferReader常用方法：

1、read():读取单个字符

2、readLine():读取一个文本行，并返回字符串。

BufferWriter常用方法：

1、write(String s,int off,int len):写入字符串的某一部分

2、flush():刷新该流的缓存

3、newLine():写入一个行分隔符

在使用BufferWriter时，方法并没有立刻被写入输入流，而是首先写入缓存区中。如果想立刻写入，需要用flush方法。

## 数据输入/输出流

DataInputStream/DataOutputStream允许以机器无关的方式从底层读取基本的**Java**类型。

DataInputStream构造方法：

DataInputStream(InputStream in):使用基础的InputStream创建一个DataInputStream

DataOutputStream构造方法：

DataOutputStream(OutputStream out):创建一个新的数据输入流，将数据写入基础的数据输入流

DataOutputStream提供了以下写入字符串的方法：

1、writeBytes(String s):将每个字符串中的低字节内容写入目标设备

2、writeChars(String s):将每个字符的两个字节都写入目标设备

3、writeUTF(String s):按UTF编码后的字节长度写入目标设备

DataInputStream提供一个readUTF()方法返回字符串，DataOutputStream提供writeUTF()方法写入字符串。

## ZIP压缩输入/输出流

使用位于java.util.zip包中的ZipInputStream和ZipOutputStream实现文件的解压缩或压缩。

### 压缩文件

利用ZipOutputStream对象，可以将文件压缩为.zip文件。其构造方法为：

ZipOutputStream(OutputStream out)

常用的方法有：

1、putNextEntry(ZipEntry e):开始写入一个新的ZipEntry，并将流内的位置移至此entry所指的数据开头

2、write(byte[] b,int off,int len):将字节数组写入当前的ZIP条目数据

3、finish():完成写入ZIP输入流的内容，无需关闭它所配合的OutputStream

4、setComment(String comment):设置ZIP文件的注释文字

### 解压缩文件

ZipInputStream可读取Zip压缩格式的文件，包括以压缩和未压缩的条目。

构造方法为：

ZipInputStream(InputStream in)

常用方法有：

1、read(byte[] b,int off,int len):读取b数组内off偏移量位置，长度为len的字节

2、available():判断是否读完目前entry所指定的数据，读完返回0，其他返回1

3、closeEntry():关闭当前ZIP条目并定位流以读取下个条目

4、skip(long n):跳过当前ZIP条目中指定的字节数

5、getNextEntry():读取下个ZipEntry，并将流内的位置指向该entry的数据的开头

6、createZipEntry(String name):以指定的name新建一个ZipEntry。





