; AHK v2脚本示例：调用Rust生成的DLL

; 定义DLL路径
#DllLoad "./target/release/rust_ahk_dll.dll"
dll := "rust_ahk_dll.dll"
#Include polyfill.ahk

isInConsole := DllCall("GetStdHandle", "int", -11, "ptr") > 0

native_println(str*) {
    static stdout := 0
    str := str.join(" ")
    if (stdout) {
        stdout.WriteLine(str)
        return
    }
    ; 先尝试获取标准输出句柄
    hStdOut := DllCall("GetStdHandle", "int", -11, "ptr")
    ; 在Windows中，无效句柄可能是0或-1，需要处理这两种情况
    if hStdOut <= 0 {
        DllCall("AllocConsole")
        ; 获取新分配的控制台句柄
        hStdOut := DllCall("GetStdHandle", "int", -11, "ptr")

        ; 显示控制台窗口
        hConsole := DllCall("GetConsoleWindow", "ptr")
        if hConsole {
            ; 确保控制台窗口可见
            DllCall("ShowWindow", "ptr", hConsole, "int", 5) ; SW_SHOW
        } else {
            return
        }
    }

    if hStdOut > 0 {
        stdout := FileOpen("*", "w")
        stdout.WriteLine(str)
        stdout.Read(0)
    }
}

dll_println(str*) {
    str := str.join(" ")
    DllCall(dll "\println", "Str", str)
}
native_println("hello")
dll_println("world")
println := dll_println

; === 1. 调用整数加法函数 ===
result := DllCall(dll "\add", "Int", 10, "Int", 20, "Int")
println("测试整数加法: add(10, 20) = " result, "整数加法测试")

; === 2. 调用字符串拼接函数 ===
str1 := "Hello, "
str2 := "World!"
; 调用字符串拼接函数
resultStrPtr := DllCall(dll "\concat_strings", "AStr", str1, "AStr", str2, "Ptr")
; 将指针转换为AHK字符串
resultStr := StrGet(resultStrPtr, "UTF-8")
println("测试字符串拼接: `"" str1 "`" + `"" str2 "`" = `"" resultStr "`"", "字符串拼接测试")

; 释放字符串内存
DllCall(dll "\free_string", "Ptr", resultStrPtr)

; === 3. 调用字符串长度函数 ===
testStr := "这是一个测试字符串"
; 使用AHK内置函数获取字符数
ahkCharLen := StrLen(testStr)
; 调用DLL函数获取字节数
rustByteLen := DllCall(dll "\string_length", "AStr", testStr, "Int")
println("测试字符串长度: `"" testStr "`"`n"
    "AHK内置StrLen()字符数: " ahkCharLen "`n"
    "Rust DLL返回字符数: " rustByteLen, "字符串长度测试")

; === 4. 测试结构体操作 ===
; 定义Point结构体（与Rust中的#[repr(C)]对应）
Point := Buffer(8) ; 2个Int，每个4字节
NumPut("Int", 10, Point, 0) ; x = 10
NumPut("Int", 20, Point, 4) ; y = 20

Point2 := Buffer(8)
NumPut("Int", 30, Point2, 0) ; x = 30
NumPut("Int", 40, Point2, 4) ; y = 40

; 计算两点之间的距离
distance := DllCall(dll "\calculate_distance", "Ptr", Point, "Ptr", Point2, "Double")
println("测试结构体：点(10,20)到点(30,40)的距离是 " distance, "结构体操作测试")

; === 5. 测试创建结构体 ===
; 调用create_point函数创建一个新的Point
; 在AHK v2中，结构体返回值需要特殊处理
; 我们可以直接使用结构体大小作为返回类型
; 在C ABI中，小型结构体（如Point，只有8字节）会直接通过寄存器返回，而不是返回指针。
result := DllCall(dll "\create_point", "Int", 50, "Int", 60, "Int64") ; Point结构体大小为8字节，用Int64接收
; 将返回的64位整数转换为Point结构体
newPoint := Buffer(8)
NumPut("Int64", result, newPoint)
; 从Buffer中读取数据
newX := NumGet(newPoint, 0, "Int")
newY := NumGet(newPoint, 4, "Int")
println("测试创建结构体：create_point(50,60) 返回点(" newX "," newY ")", "创建结构体测试")

; 注意：create_point返回的是结构体值，不需要释放内存

; === 6. 测试Unicode字符串长度函数 ===
unicodeStr := "Hello, 世界!"
unicodeAhkCharLen := StrLen(unicodeStr)
unicodeRustCharLen := DllCall(dll "\string_length_unicode", "Str", unicodeStr, "Int")
println("测试Unicode字符串长度: `"" unicodeStr "`"`n"
    "AHK内置StrLen()字符数: " unicodeAhkCharLen "`n"
    "Rust DLL返回字符数: " unicodeRustCharLen "Unicode字符串长度测试")

; === 7. 测试Unicode字符串拼接函数 ===
unicodeStr1 := "你好, "
unicodeStr2 := "Rust!"
unicodeResultPtr := DllCall(dll "\concat_strings_unicode", "Str", unicodeStr1, "Str", unicodeStr2, "Ptr")
unicodeResultStr := StrGet(unicodeResultPtr, "UTF-16")
println("测试Unicode字符串拼接: `"" unicodeStr1 "`" + `"" unicodeStr2 "`" = `"" unicodeResultStr "`"", "Unicode字符串拼接测试")

; 释放Unicode字符串内存
DllCall(dll "\free_string_unicode", "Ptr", unicodeResultPtr)


println("测试设置程序音量: setProgramVolume(`"EM-Win64-Shipping.exe`", 0.0)")
rst := DllCall(dll "\setProgramVolume", "str", "EM-Win64-Shipping.exe", "float", 0.0, "int")
println("setProgramVolume返回值: " rst)
Sleep 2000

println("测试设置程序音量: setProgramVolume(`"EM-Win64-Shipping.exe`", 1.0)")
rst := DllCall(dll "\setProgramVolume", "str", "EM-Win64-Shipping.exe", "float", 1.0, "int")
println("setProgramVolume返回值: " rst)

; 总结：
; 1. 基本类型（Int, Double等）可以直接传递和返回
; 2. 字符串需要使用AStr类型，并注意释放内存
; 3. 结构体需要使用Buffer创建，并使用NumPut/NumGet读写数据
; 4. 从DLL返回的指针（特别是字符串）需要正确释放内存
; 5. Unicode字符串使用Str类型，并调用相应的Unicode版本函数，使用UTF-16编码

if (!isInConsole) {
    ; pause
    println("按任意键退出...")
    FileOpen("*", "r").ReadChar()
}