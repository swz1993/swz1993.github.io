本篇来自慕课网"悟空"视频的笔记。先简单介绍一下。

在Java中，每个对象有且仅有一个同步锁。不同的线程对同步锁的访问是互斥的，即同一时刻，仅有一个线程可以得到该锁。所以，我们可以以同步锁为基础，实现多线程间对共享数据操作的可见性和原子性。使用同步锁有几种方式，synchronized就是其中之一。

## 简单介绍

synchronized是Java的一个关键字，是学习并发编程绕不开的一个知识点。它可以防止线程干扰和内存一致性错误，保证同一时刻最多只有一个线程执行某段被锁住的代码，以保证并发安全。

## 用法

### 对象锁

包括方法锁(默认对象为this当前实例对象)和同步代码块锁。

#### 同步代码块锁：

```
synchronized(this) {
            System.out.println("对象锁中的同步代码块锁。线程名为：" + Thread.currentThread().getName());
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(Thread.currentThread().getName() + "运行结束");
}
```
此处，通过this锁住当前对象。有一点要注意：此处如果是通过继承Thread的方式创建了线程，那么每次都会有不同的this对象。因此，此处的synchronized没有作用。

#### 方法锁：

```
public synchronized void test(){

System.out.println("对象锁中的方法锁。线程名为：" + Thread.currentThread().getName());
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(Thread.currentThread().getName() + "运行结束");

}
```
方法锁的默认锁对象为this。

以上就是对象锁的两种形式，其中，在同步代码块锁中，我们不仅可以使用this，还可以自定义一个锁对象，比如：

```
Object obj = new Object();
synchronized(obj) {
            System.out.println("对象锁中的同步代码块锁。线程名为：" + Thread.currentThread().getName());
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(Thread.currentThread().getName() + "运行结束");
}
```

### 类锁

指synchronized修饰静态的方法或者指定锁为Class对象。

### 静态锁

```
 private static synchronized void test() {
            System.out.println("我是类锁中的静态锁。线程名为：" + Thread.currentThread().getName());
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println(Thread.currentThread().getName() + "运行结束");
    }
```

与方法锁不同的是，此方法为static修饰的静态方法。

### Class对象锁

```
//此处假设我们有一个MyTest类
synchronized(MyTest.class) {
            System.out.println("对象锁中的同步代码块锁。线程名为：" + Thread.currentThread().getName());
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
```
以上就是类锁的两种形式，与方法锁不同的地方在于，类锁的对象为当前类。


>注意：
>
>1、一把锁只能同时被一个线程获取，没有拿到锁的线程只能等待
>
>2、每个实例都对应有自己的一把锁，不同实例之间互不影响
>
>3、在方法执行完毕或者抛出异常后，会释放锁

## 性质

### 可重入性

指同一线程的外层函数获得锁后，内层函数可以直接再次获取该锁

好处：避免死锁，提升封装性

粒度：与线程相关，与调用无关

### 不可中断性

一旦一个锁被其他线程获得，其他的线程如果想获得该锁，就会等待或被阻塞，直到锁被释放。如果锁没有被释放，等待的线程会永远等待下去。

## 加锁和释放锁的原理

可重入原理：加锁次数计数器。JVM负责跟踪对象被加锁的次数；线程第一次给对象加锁的时候，计数变为1.每当这个相同的线程再次获得该锁时，计数器会递增；每当任务离开，计数递减，当技术为0的时候，锁被释放。

保证可见性的原理：内存模型

通过反编译看字节码：javap -verbose hello.class

synchronized有个加锁的monitorenter和解锁的monitorexit，读到指令，会让monitor计数器加一或者减一。

## 缺陷

1、效率低，锁的释放情况少，一种是正常执行任务完释放，一种是异常JVM释放，不能设置超时时间；

2、不够灵活，读的话可能不需要加锁，例如读写锁就比较灵活；

3、无法判断状态，是否获取到锁

