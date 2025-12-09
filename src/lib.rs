use encoding_rs::GBK;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use widestring::U16CString;

// 示例：接受结构体参数
#[repr(C)]
pub struct Point {
    x: c_int,
    y: c_int,
}

// 简单的整数加法函数 - 安全函数
#[unsafe(no_mangle)]
pub extern "C" fn add(a: c_int, b: c_int) -> c_int {
    a + b
}

// 字符串拼接函数 - 处理指针，需要unsafe
#[unsafe(no_mangle)]
pub extern "C" fn concat_strings(s1: *const c_char, s2: *const c_char) -> *mut c_char {
    unsafe {
        let str1 = CStr::from_ptr(s1).to_str().unwrap_or("");
        let str2 = CStr::from_ptr(s2).to_str().unwrap_or("");
        let result = format!("{}{}", str1, str2);
        CString::new(result).unwrap().into_raw()
    }
}

// 释放字符串内存 - 处理指针，需要unsafe
#[unsafe(no_mangle)]
pub extern "C" fn free_string(s: *mut c_char) {
    unsafe {
        if !s.is_null() {
            let _ = CString::from_raw(s);
        }
    }
}

// 计算字符串长度 - 处理ANSI字符串（与AHK的AStr对应）
#[unsafe(no_mangle)]
pub extern "C" fn string_length(s: *const c_char) -> c_int {
    unsafe {
        if s.is_null() {
            0
        } else {
            // AHK的AStr使用系统默认ANSI编码，在中文Windows上是GBK
            // 使用encoding_rs库来正确解码GBK字符串并获取字符数
            let bytes = CStr::from_ptr(s).to_bytes();
            let (decoded, _, _) = GBK.decode(bytes);
            decoded.chars().count() as c_int
        }
    }
}

// 计算Unicode字符串长度 - 处理UTF-16字符串（与AHK的Str对应）
#[unsafe(no_mangle)]
pub extern "C" fn string_length_unicode(s: *const u16) -> c_int {
    unsafe {
        if s.is_null() {
            0
        } else {
            // AHK的Str使用UTF-16编码
            let utf16_str = U16CString::from_ptr_str(s);
            utf16_str.to_string_lossy().chars().count() as c_int
        }
    }
}

// Unicode字符串拼接函数 - 处理UTF-16字符串
#[unsafe(no_mangle)]
pub extern "C" fn concat_strings_unicode(s1: *const u16, s2: *const u16) -> *mut u16 {
    unsafe {
        let str1 = U16CString::from_ptr_str(s1).to_string_lossy();
        let str2 = U16CString::from_ptr_str(s2).to_string_lossy();
        let result = format!("{}{}", str1, str2);
        U16CString::from_str(&result).unwrap().into_raw()
    }
}

// 释放Unicode字符串内存
#[unsafe(no_mangle)]
pub extern "C" fn free_string_unicode(s: *mut u16) {
    unsafe {
        if !s.is_null() {
            let _ = U16CString::from_raw(s);
        }
    }
}

// 计算两点之间的距离 - 处理指针，需要unsafe
#[unsafe(no_mangle)]
pub extern "C" fn calculate_distance(p1: *const Point, p2: *const Point) -> f64 {
    unsafe {
        if p1.is_null() || p2.is_null() {
            return 0.0;
        }
        let dx = (*p1).x - (*p2).x;
        let dy = (*p1).y - (*p2).y;
        ((dx as f64).powi(2) + (dy as f64).powi(2)).sqrt()
    }
}

// 创建点结构体 - 安全函数
#[unsafe(no_mangle)]
pub extern "C" fn create_point(x: c_int, y: c_int) -> Point {
    Point { x, y }
}

// 打印Unicode字符串 - 处理UTF-16字符串
#[unsafe(no_mangle)]
pub extern "C" fn println(s: *mut u16) {
    unsafe {
        if !s.is_null() {
            let str = U16CString::from_ptr_str(s).to_string_lossy();
            println!("{}", str);
        }
    }
}

const DLL_PROCESS_ATTACH: u32 = 1;
const DLL_PROCESS_DETACH: u32 = 0;

// DLL 入口点 (可选)
#[unsafe(no_mangle)]
pub extern "system" fn DllMain(
    _module: isize,
    call_reason: u32,
    _reserved: *mut std::ffi::c_void,
) -> i32 {
    match call_reason {
        DLL_PROCESS_ATTACH => {
            println!("DLL 加载成功");
            1
        }
        DLL_PROCESS_DETACH => 1,
        _ => 1,
    }
}
