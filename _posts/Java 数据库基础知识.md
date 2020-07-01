## 什么是数据库

数据库是一种存储结构，它允许使用各种格式输入、处理和检索数据，不必在每次使用时重新输入。数据库主要有特点有：

1、实现数据共享。数据共享包含所有用户可以同时存取数据库中的数据，也包括用户可以用各种方式通过接口使用数据库，并提供数据共享。

2、减少数据的冗余度。通过数据共享，避免了用户各自建立应用文件

3、数据的独立性。数据库的逻辑结构和应用程序相互独立，其物理结构的变化不会影响数据的逻辑结构

4、数据实现集中控制。

5、数据的一致性和可维护性，以确保数据的安全性和可靠性，主要包括：

  (1)、安全性控制，防止数据丢失、错误更新和越权使用

  (2)、完整性控制，以保证数据的正确性、有效性和相容性

  (3)、并发控制，同一时间周期内，允许对数据实现多路存取

  (4)、故障的发现和恢复
  
数据库的基本结构分为3个层次：

1、物理数据层：数据库的最内层，是物理存储设备上实际存储的数据集合

2、概念数据层：数据库的中间一层，是数据库的整体逻辑表示

3、逻辑数据层：用户所看到的和使用的数据库

## 数据库的种类及功能

数据库的种类有：

1、层次性数据库：类似于树结构，是一组通过链接而相互联系在一起的记录。其特点是记录之间的关系通过指针实现。

2、网状性数据库：使用网络结构表示实体类型和实体间联系的数据模型，多对多。

3、面向对象型数据库：建立在面向对象的基础上

4、关系型数据库：目前最流行的数据库，基于关系模型建立的数据库

## SQL语言

其主要由以下几部分组成：

1、数据定义语言，如create、alter和drop等

2、数据操纵语言，如select、insert、update和delete等

3、数据控制语言，如grant和revoke等

4、事物控制语言，如commit和rollback等

### select 语句

SELECT 所选字段列表 FROM 数据表名 WHRER 条件表达式 GROUP BY 字段名 HAVING 条件表达式(指定分组条件) ORDER BY 字段名[ASC|DESC]

### insert 语句

insert into 表名 [(字段名 1,字段名 2...)] values (属性值 1,属性值 2...)

### update 语句

UPDATE 数据表名 SET 字段名 = 新的字段值 WHERE 条件表达式

### delete 语句

delete from 数据表名 where 条件表达式

## JDBC 概述

JDBC是一种可用于执行SQL语句的Java API，是连接数据库和Java应用程序的纽带

### JDBC-ODBC 桥

它是一个JDBC驱动程序，完成了从JDBC操作到ODBC操作之间的转换工作，允许JDBC驱动程序被用作ODBC的驱动程序。使用步骤为：

1、 首先加载JDBC-ODBC桥的驱动程序

Class.forName("sun,jdbc.odbc.jdbcOdbcDriver");

2、使用Connection接口，并通过DriverManager创建连接对象：

Connection conn = DriverManager.getConnection("jdbc:odbc:数据源名字","user name","password");

数据源必须给出一个简短的描述名，user name和password没有设置，则要与数据源tom交换数据

3、向数据库发送SQL语句

Statement sql = conn.createStatement();

JDBC-ODBC是一种过渡技术，现在已经不怎么用了，现在用的是JDBC技术。

### JDBC 技术

全称为Java DataBase Connectivity，是一套面向对象的应用程序接口，指定了统一的访问各种关系型数据库的标准接口。其主要完成以下几个任务：

1、与数据库建立一个连接

2、向数据库发送SQL语句

3、处理从数据库返回的结果

它不能直接访问数据库，必须依赖于数据库厂商提供的JDBC驱动程序

### JDBC驱动程序类型

JDBC总体结构由4个组件--应用程序、驱动程序管理器、驱动程序和数据源组成。JDBC驱动基本上分为以下4种：

1、JDBC-ODBC桥：依靠ODBC驱动器和数据库通信。这种方式必须将ODBC二进制代码加载到使用该驱动程序的每台客户机上。

2、本地API一部分用Java编写的驱动程序：把客户机的API上的JDBC调用转换为Oracle、DB2或其他DBMS调用。

3、JDBC网络驱动：将JDBC转换为与DBMS无关的网络协议，又被某个服务器转换为一种DBMS协议，是一种利用Java编写的JDBC驱动程序

4、本地协议驱动：纯Java的驱动程序

### JDBC中常用的类和接口

### Connection 接口

代表与特定的数据库的连接，在连接上下文中执行SQL语句并返回结果。常用方法有：

1、createStatement():创建Statement对象

2、createStatement(int resultSetType,int resultSetConcurrency):创建一个Statement对象，该对象将生成具有给定类型、并发性和可保存性的ResultSet对象

3、preparedStatement():创建预处理对象preparedStatement

4、isReadOnly():设置当前Connection对象为只读模式

5、setReadOnly():设置当前Connection对象的读写模式，默认是非只读模式

6、commit():使所有上一次提交/回滚后进行的更改成为持久更改，并释放此Connection对象当前持有的所有数据库锁

7、roolback():取消在当前事务中进行的所有更改，并释放锁

8、close():立即释放此Connection对象的数据库和JDBC资源

### Statement 接口

