# Rust AHK DLL

这是一个用Rust编写的AutoHotkey v2动态链接库(DLL)示例，提供了多种功能和字符串处理能力，包括Unicode支持。

## 功能特性

- ✅ 整数加法 (`add_integers`)
- ✅ 字符串长度计算 (支持ANSI和Unicode)
- ✅ 字符串拼接 (支持ANSI和Unicode)
- ✅ 结构体操作 (Point结构体示例)
- ✅ 内存管理 (安全释放DLL分配的内存)
- ✅ UTF-8/ANSI字符串支持
- ✅ UTF-16 Unicode字符串支持

## 构建方法

### 前置要求

- [Rust](https://www.rust-lang.org/zh-CN/) (1.60+)
- [Cargo](https://doc.rust-lang.org/cargo/)

### 编译发布版本

```bash
cd rust_ahk_dll
cargo build --release
```

编译结果将生成在 `target/release/` 目录下，文件名为 `rust_ahk_dll.dll`。

## 使用示例

### 基本类型操作

```ahk
; 整数加法
result := DllCall("rust_ahk_dll.dll\add_integers", "int", 5, "int", 3, "int")
MsgBox "整数加法结果: " result
```

### ANSI字符串操作

```ahk
; 字符串长度
str := "测试字符串"
len := DllCall("rust_ahk_dll.dll\string_length", "AStr", str, "int")

; 字符串拼接
str1 := "Hello, "
str2 := "World!"
ptr := DllCall("rust_ahk_dll.dll\concat_strings", "AStr", str1, "AStr", str2, "Ptr")
result := StrGet(ptr, "UTF-8")
DllCall("rust_ahk_dll.dll\free_string", "Ptr", ptr) ; 释放内存
```

### Unicode字符串操作

```ahk
; Unicode字符串长度
str := "Hello, 世界!"
len := DllCall("rust_ahk_dll.dll\string_length_unicode", "Str", str, "int")

; Unicode字符串拼接
str1 := "你好, "
str2 := "Rust!"
ptr := DllCall("rust_ahk_dll.dll\concat_strings_unicode", "Str", str1, "Str", str2, "Ptr")
result := StrGet(ptr, "UTF-16")
DllCall("rust_ahk_dll.dll\free_string_unicode", "Ptr", ptr) ; 释放内存
```

### 结构体操作

```ahk
; 创建Point结构体
point1 := Buffer(8, 0)  ; 2个4字节整数
NumPut("uint", 0, point1, 0)
NumPut("uint", 0, point1, 4)

point2 := Buffer(8, 0)
NumPut("uint", 3, point2, 0)
NumPut("uint", 4, point2, 4)

; 计算两点距离
distance := DllCall("rust_ahk_dll.dll\calculate_distance", "Ptr", point1, "Ptr", point2, "double")
```

## 内存管理注意事项

- **从DLL返回的字符串指针必须手动释放**，否则会导致内存泄漏
- ANSI字符串使用 `free_string` 释放
- Unicode字符串使用 `free_string_unicode` 释放
- 基本类型和结构体不需要额外的内存管理

## API参考

### 整数运算

```rust
pub extern "C" fn add_integers(a: c_int, b: c_int) -> c_int
```

### ANSI字符串

```rust
pub extern "C" fn string_length(s: *const c_char) -> c_int
pub extern "C" fn concat_strings(s1: *const c_char, s2: *const c_char) -> *mut c_char
pub extern "C" fn free_string(s: *mut c_char)
```

### Unicode字符串

```rust
pub extern "C" fn string_length_unicode(s: *const u16) -> c_int
pub extern "C" fn concat_strings_unicode(s1: *const u16, s2: *const u16) -> *mut u16
pub extern "C" fn free_string_unicode(s: *mut u16)
```

### 结构体

```rust
pub extern "C" fn create_point(x: c_int, y: c_int) -> Point
pub extern "C" fn calculate_distance(p1: *const Point, p2: *const Point) -> f64
```

## 项目结构

```
rust_ahk_dll/
├── src/
│   └── lib.rs          # Rust源代码
├── target/             # 构建输出目录
├── Cargo.toml          # Cargo配置文件
├── Cargo.lock          # 依赖锁定文件
├── rust_dll_example_v2.ahk  # AHK示例脚本
└── README.md           # 项目说明
```
