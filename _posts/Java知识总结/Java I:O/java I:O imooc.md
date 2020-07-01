gbk编码中，中文占用2个字节，英文占用1个字节

ANSI 中文2字节 英文1字节

utf-8编码中，中文占用3个字节，英文占用1个字节

java是双字节编码 utf-16be，中文占用2个字节，英文占用2个字节

当你的字节序列使用某种编码时，这个时候想把字节序列变成字符串，也需要用这种编码方式，否则会出现乱码，不写的话会使用项目默认的编码方式

文本文件就是字节序列，可以是任意编码的字节序列，如果我们在中文机器上创建文本文件，那么该文本文件只认识ansi编码

```
String str=new String(数组，编码方式)；//使数组转换成按照编码格式的字符串。
[]bytes =str.getbyte("编码方式")；//使str转换成按照编码方式的字节数组。
```

```
byte[] bytes1 = s.getBytes();
//byte[] bytes1 = s.getBytes("gbk"); 此处可更换编码方式
for(byte b : bytes1){
System.out.print(Integer.toHexString(b & 0xff) + " ");
```