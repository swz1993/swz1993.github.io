## 1、整体架构

Okhttp 的优点有：

+ 支持HTTPS/HTTP2/WebSocket（在OkHttp3.7中已经剥离对Spdy的支持，转而大力支持HTTP2）
+ 内部维护任务队列线程池，友好支持并发访问
+ 内部维护连接池，支持多路复用，减少连接创建开销
+ socket创建支持最佳路由
+ 提供拦截器链（InterceptorChain），实现request与response的分层处理(如透明GZIP压缩，logging等)

#### 1.1、简单使用

Okhttp 提供了两种调用方式，**同步调用** 和 **异步调用** 。

同步调用为：

```java

  @Override public Response execute() throws IOException {
    synchronized (this) {
      if (executed) throw new IllegalStateException("Already Executed");
      executed = true;
    }
    captureCallStackTrace();
    eventListener.callStart(this);
    try {
      client.dispatcher().executed(this);
      Response result = getResponseWithInterceptorChain();
      if (result == null) throw new IOException("Canceled");
      return result;
    } catch (IOException e) {
      eventListener.callFailed(this, e);
      throw e;
    } finally {
      client.dispatcher().finished(this);
    }
  }

```

首先锁住此代码块，接着使用分配器的 executed 方法将 call 加入到同步队列中，然后调用 getResponseWithInterceptorChain 方法执行 http 请求，最后使用 finishied 方法将 call 从同步队列中删除。

异步调用为：

```java

  @Override public void enqueue(Callback responseCallback) {
    synchronized (this) {
      if (executed) throw new IllegalStateException("Already Executed");
      executed = true;
    }
    captureCallStackTrace();
    eventListener.callStart(this);
    client.dispatcher().enqueue(new AsyncCall(responseCallback));
  }

```
首先锁住此代码块，然后将一个封装好的执行体放入异步执行队列中。这里引入了一个新的类
 AsyncCall ，这个类继承了 NamedRunnable 类，而 NamedRunnable 类实现了 Runnable 接口。

 除了同步调用和异步调用，OkHttp 还提供了一个 **拦截器** 的概念，拦截器提供了拦截请求和拦截服务器应答的接口。

 #### 1.2、总体架构

 ![OkHttp总体架构](https://img-blog.csdn.net/20171105181409025?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvanNvbl9pdA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

 上面就是 OkHttp 的整体架构，大致可以分为以下几层：

 ###### 1.2.1、interface--接口层：接收用户的网络访问请求（同步请求/异步请求），发起实际的网络访问

OkHttpClient是OkHttp框架的客户端，更确切的说是一个用户面板。用户使用OkHttp进行各种设置，发起各种网络请求都是通过OkHttpClient完成的。每个OkHttpClient内部都维护了属于自己的任务队列，连接池，Cache，拦截器等，所以在使用OkHttp作为网络框架时应该全局共享一个OkHttpClient实例。

Call描述一个实际的访问请求，用户的每一个网络请求都是一个Call实例。Call本身只是一个接口，定义了Call的接口方法，实际执行过程中，OkHttp会为每一个请求创建一个RealCall,每一个RealCall内部有一个AsyncCall。AsyncCall继承的NamedRunnable继承自Runnable接口，所以每一个Call就是一个线程，而执行Call的过程就是执行其execute方法的过程。

###### 1.2.2、Protocol——协议层：处理协议逻辑

Protocol层负责处理协议逻辑，OkHttp支持Http1/Http2/WebSocket协议，并在3.7版本中放弃了对Spdy协议，鼓励开发者使用Http/2。

###### 1.2.3、连接层：管理网络连接，发送新的请求，接收服务器访问

负责网络连接。在连接层中有一个连接池，统一管理所有的Socket连接，当用户新发起一个网络请求时，OkHttp会首先从连接池中查找是否有符合要求的连接，如果有则直接通过该连接发送网络请求；否则新创建一个网络连接。

###### 1.2.4、Cache——缓存层：管理本地缓存

Cache层负责维护请求缓存，当用户的网络请求在本地已有符合要求的缓存时，OkHttp会直接从缓存中返回结果，从而节省网络开销。

###### 1.2.5、I/O层：实际数据读写实现

I/O层负责实际的数据读写。OkHttp的另一大有点就是其高效的I/O操作，这归因于其高效的I/O库okio

###### 1.2.6、Inteceptor——拦截器层：拦截网络访问，插入拦截逻辑

拦截器层提供了一个类AOP接口，方便用户可以切入到各个层面对网络访问进行拦截并执行相关逻辑。

## 2、拦截器

接下来我们以一个具体的网络请求来讲述OkHttp进行网络访问的具体过程。由于该部分与OkHttp的拦截器概念紧密联系在一起，所以将这两部分放在一起进行讲解。首先，我们构造一个简单的异步访问的Demo：

```java

OkHttpClient client = new OkHttpClient();
Request request = new Request.Builder()
  .url("https://www.baidu.com")
  .build();

client.newCall(request).enqueue(new Callback() {
  @Override
  public void onFailure(Call call, IOException e) {
    Log.d("OkHttp", "Call Failed:" + e.getMessage());
  }

  @Override
  public void onResponse(Call call, Response response) throws IOException {
    Log.d("OkHttp", "Call succeeded:" + response.message());
  }
});

```
在其中，client.newCall 实际上是创建一个 RealCall 的实例。

```java

@Override public Call newCall(Request request) {
    return RealCall.newRealCall(this, request, false /* for web socket */);
  }

```

RealCall#enqueue实际就是将一个RealCall放入到任务队列中，等待合适的机会执行:

```java

  @Override public void enqueue(Callback responseCallback) {
    synchronized (this) {
      if (executed) throw new IllegalStateException("Already Executed");
      executed = true;
    }
    captureCallStackTrace();
    eventListener.callStart(this);
    client.dispatcher().enqueue(new AsyncCall(responseCallback));
  }

```

从代码中可以看到最终RealCall被转化成一个AsyncCall并被放入到任务队列中,AsyncCall的excute方法最终将会被执行:

```java

@Override protected void execute() {
      boolean signalledCallback = false;
      try {
        Response response = getResponseWithInterceptorChain();
        if (retryAndFollowUpInterceptor.isCanceled()) {
          signalledCallback = true;
          responseCallback.onFailure(RealCall.this, new IOException("Canceled"));
        } else {
          signalledCallback = true;
          responseCallback.onResponse(RealCall.this, response);
        }
      } catch (IOException e) {
        if (signalledCallback) {
          // Do not signal the callback twice!
          Platform.get().log(INFO, "Callback failure for " + toLoggableString(), e);
        } else {
          eventListener.callFailed(RealCall.this, e);
          responseCallback.onFailure(RealCall.this, e);
        }
      } finally {
        client.dispatcher().finished(this);
      }
    }

```

execute方法的逻辑并不复杂，简单的说就是：

+ 调用 getResponseWithInterceptorChain 获取服务器返回
+ 通知任务分发器 client.dispatcher 该任务已结束

getResponseWithInterceptorChain构建了一个拦截器链，通过依次执行该拦截器链中的每一个拦截器最终得到服务器返回。

所以，OkHttp执行网络请求的过程为：

![OkHttp请求过程](https://img-blog.csdn.net/20171101140629030?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvanNvbl9pdA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

> 其中，Dispatcher是保存同步和异步Call的地方，并负责执行异步AsyncCall。Dispatcher使用了一个Deque保存了同步任务；针对异步请求，Dispatcher使用了两个Deque，一个保存准备执行的请求，一个保存正在执行的请求，为什么要用两个呢？因为Dispatcher默认支持最大的并发请求是64个，单个Host最多执行5个并发请求，如果超过，则Call会先被放入到readyAsyncCall中，当出现空闲的线程时，再将readyAsyncCall中的线程移入到runningAsynCalls中，执行请求。

#### 2.1、构建拦截器

首先我们先看一下 getResponseWithInterceptorChain 方法：

```java

  Response getResponseWithInterceptorChain() throws IOException {
    // Build a full stack of interceptors.
    List<Interceptor> interceptors = new ArrayList<>();
    interceptors.addAll(client.interceptors());
    interceptors.add(retryAndFollowUpInterceptor);
    interceptors.add(new BridgeInterceptor(client.cookieJar()));
    interceptors.add(new CacheInterceptor(client.internalCache()));
    interceptors.add(new ConnectInterceptor(client));
    if (!forWebSocket) {
      interceptors.addAll(client.networkInterceptors());
    }
    interceptors.add(new CallServerInterceptor(forWebSocket));

    Interceptor.Chain chain = new RealInterceptorChain(interceptors, null, null, null, 0,
        originalRequest, this, eventListener, client.connectTimeoutMillis(),
        client.readTimeoutMillis(), client.writeTimeoutMillis());

    return chain.proceed(originalRequest);
  }

```

其逻辑为：

+ 创建一系列拦截器，并将其放入一个拦截器数组中。这部分拦截器即包括用户自定义的拦截器也包括框架内部拦截器
+ 创建一个拦截器链RealInterceptorChain,并执行拦截器链的proceed方法

接着，我们看一下 RealInterceptorChain 的实现：

```java

public final class RealInterceptorChain implements Interceptor.Chain {
  private final List<Interceptor> interceptors;
  private final StreamAllocation streamAllocation;
  private final HttpCodec httpCodec;
  private final RealConnection connection;
  private final int index;
  private final Request request;
  private final Call call;
  private final EventListener eventListener;
  private final int connectTimeout;
  private final int readTimeout;
  private final int writeTimeout;
  private int calls;

  public RealInterceptorChain(List<Interceptor> interceptors, StreamAllocation streamAllocation,
      HttpCodec httpCodec, RealConnection connection, int index, Request request, Call call,
      EventListener eventListener, int connectTimeout, int readTimeout, int writeTimeout) {
    this.interceptors = interceptors;
    this.connection = connection;
    this.streamAllocation = streamAllocation;
    this.httpCodec = httpCodec;
    this.index = index;
    this.request = request;
    this.call = call;
    this.eventListener = eventListener;
    this.connectTimeout = connectTimeout;
    this.readTimeout = readTimeout;
    this.writeTimeout = writeTimeout;
  }

  @Override public Connection connection() {
    return connection;
  }

  @Override public int connectTimeoutMillis() {
    return connectTimeout;
  }

  ...

  @Override public Response proceed(Request request) throws IOException {
    return proceed(request, streamAllocation, httpCodec, connection);
  }

  public Response proceed(Request request, StreamAllocation streamAllocation, HttpCodec httpCodec,
      RealConnection connection) throws IOException {
    ...

    // Call the next interceptor in the chain.
    RealInterceptorChain next = new RealInterceptorChain(interceptors, streamAllocation, httpCodec,
        connection, index + 1, request, call, eventListener, connectTimeout, readTimeout,
        writeTimeout);
    Interceptor interceptor = interceptors.get(index);
    Response response = interceptor.intercept(next);

    return response;
  }
}

```

在proceed方法中的核心代码可以看到，proceed实际上也做了两件事：

+ 创建下一个拦截链。传入index + 1使得下一个拦截器链只能从下一个拦截器开始访问
+ 执行索引为index的intercept方法，并将下一个拦截器链传入该方法

而在具体的拦截器中我们可以看到，拦截器都是在 自己的 intercept 方法中完成自己的工作，然后调用 RealInterceptorChain#proceed 方法去调用下一个拦截器的 intercept 方法，最终完成所有拦截器的操作，这就是 OkHttp 拦截器的链式执行逻辑。

而一个拦截器的 intercept 方法所执行的逻辑大致为：

+ 在发起请求前对 request 进行处理
+ 调用下一个拦截器，获取 response
+ 对 response 进行处理，返回给上一个拦截器

这就是OkHttp拦截器机制的核心逻辑。除了用户自定义的拦截器，拦截器执行的先后顺序为：

+ RetryAndFollowUpInterceptor
+ BridgeInterceptor
+ CacheInterceptor
+ ConnectIntercetot
+ CallServerInterceptor

#### 2.2、RetryAndFollowUpInterceptor

RetryAndFollowUpInterceptor负责两部分逻辑：

+ 在网络请求失败后进行重试
+ 当服务器返回当前请求需要进行重定向时直接发起新的请求，并在条件允许情况下复用当前连接

#### 2.3、BridgeInterceptor

BridgeInterceptor主要负责以下几部分内容：

+ 设置内容长度，内容编码
+ 设置gzip压缩，并在接收到内容后进行解压。省去了应用层处理数据解压的麻烦
+ 添加cookie
+ 设置其他报头，如User-Agent,Host,Keep-alive等。其中Keep-Alive是实现多路复用的必要步骤

#### 2.4、CacheInterceptor

CacheInterceptor的职责很明确，就是负责Cache的管理

#### 2.5、ConnectInterceptor

当前请求找到合适的连接，可能复用已有连接也可能是重新创建的连接，返回的连接由连接池负责决定。

整体流程大致为：

![ConnectInterceptor流程](https://img-blog.csdn.net/20171105110555077?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvanNvbl9pdA==/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/Center)

#### 2.6、CallServerInterceptor

负责向服务器发起真正的访问请求，并在接收到服务器返回后读取响应返回。

所以，整个网络访问的核心步骤为：

![OkHttp网络访问的核心步骤](http://ata2-img.cn-hangzhou.img-pub.aliyun-inc.com/e67029972070a7dd84206023b179dbd1.png)


## 3、缓存策略

OkHttp的缓存工作都是在CacheInterceptor中完成的,Cache部分有如下几个关键类：

+ Cache：Cache管理器，其内部包含一个DiskLruCache将cache写入文件系统
+ CacheStrategy：缓存策略。其内部维护一个request和response，通过指定request和response来描述是通过网络还是缓存获取response，抑或二者同时使用
+ CacheStrategy$Factory:缓存策略工厂类根据实际请求返回对应的缓存策略

在 CacheInterceptor 的 intercept 方法中，我们可以看到其操作缓存的过程为：

+ 首先尝试获取缓存，如果有缓存，更新下相关统计指标，如果当前缓存不符合要求，将其close
+ 继续，如果网络不可用并且无可用的有效缓存，则返回504错误
+ 继续，如果有缓存同时又不使用网络，则直接返回缓存结果
+ 继续，尝试通过网络获取回复
+ 继续，如果既有缓存，同时又发起了请求并且服务端返回的是NOT_MODIFIED,说明缓存还是有效的，则合并网络响应和缓存结果。同时更新缓存
+ 继续，如果没有缓存，则写入新的缓存

而缓存策略是怎么生成的？相关的代码实现在 CacheStrategy#Factory.get()方法中，具体流程为：

+ 没有缓存，直接网络请求
+ 如果是https，但没有握手，直接网络请求
+ 不可缓存，直接网络请求
+ 请求头nocache或者请求头包含If-Modified-Since或者If-None-Match，则需要服务器验证本地缓存是不是还能继续使用，直接网络请求
+ 可缓存，并且ageMillis + minFreshMillis < freshMillis + maxStaleMillis（意味着虽过期，但可用，只是会在响应头添加warning），则使用缓存
+ 缓存已经过期，添加请求头：If-Modified-Since或者If-None-Match，进行网络请求

#### 3.1、DiskLruCache

Cache内部通过DiskLruCache管理cache在文件系统层面的创建，读取，清理等等工作

总结起来DiskLruCache主要有以下几个特点：

+ 通过LinkedHashMap实现LRU替换
+ 通过本地维护Cache操作日志保证Cache原子性与可用性，同时为防止日志过分膨胀定时执行日志精简
+ 每一个Cache项对应两个状态副本：DIRTY,CLEAN。CLEAN表示当前可用状态Cache，外部访问到的cache快照均为CLEAN状态；DIRTY为更新态Cache。由于更新和创建都只操作DIRTY状态副本，实现了Cache的读写分离
+ 每一个Cache项有四个文件，两个状态（DIRTY,CLEAN）,每个状态对应两个文件：一个文件存储Cache meta数据，一个文件存储Cache内容数据

## 4、连接池

无论是HTTP/1.1的Keep-Alive机制还是HTTP/2的多路复用机制，在实现上都需要引入连接池来维护网络连接。接下来看下 OkHttp 中的连接池实现。OkHttp内部过 **ConnectionPool** 来管理连接池。 ConnectionPool 的内部成员主要有：

+ Call：对Http请求的封装
+ Connection/RealConnection:物理连接的封装，其内部有List<WeakReference<StreamAllocation>>的引用计数
+ StreamAllocation: okhttp中引入了StreamAllocation负责管理一个连接上的流，同时在connection中也通过一个StreamAllocation的引用的列表来管理一个连接的流，从而使得连接与流之间解耦
+ connections: Deque双端队列，用于维护连接的容器
+ routeDatabase:用来记录连接失败的Route的黑名单，当连接失败的时候就会把失败的线路加进去

一个OkHttpClient只包含一个ConnectionPool，其实例化过程也在OkHttpClient的实例化过程中实现，值得一提的是ConnectionPool各个方法的调用并没有直接对外暴露，而是通过OkHttpClient的Internal接口统一对外暴露。ConnectionPool内部通过一个双端队列(dequeue)来维护当前所有连接。OkHttp的连接池通过计数+标记清理的机制来管理连接池，使得无用连接可以被会回收，并保持多个健康的keep-alive连接。这也是OkHttp的连接池能保持高效的关键原因。

[看大神的博客](https://yq.aliyun.com/articles/78101?spm=a2c4e.11153940.0.0.412d2e38memw3g)
