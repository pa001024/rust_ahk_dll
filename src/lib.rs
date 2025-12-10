use encoding_rs::GBK;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_float, c_int};
use widestring::U16CString;
use windows::Win32::Media::Audio::{
    EDataFlow, ERole, IAudioSessionControl2, IAudioSessionManager2, ISimpleAudioVolume,
};
use windows::Win32::Media::Audio::{IMMDeviceEnumerator, MMDeviceEnumerator};
use windows::Win32::System::Com::{
    CLSCTX_ALL, CoCreateInstance, CoInitialize, CoTaskMemFree, CoUninitialize,
};
use windows::core::{Interface, Result};

// 定义必要的常量
const ERENDER: EDataFlow = EDataFlow(0); // eRender
const ECONSOLE: ERole = ERole(0); // eConsole

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

// Audio API相关导入已在文件顶部定义

// 从会话标识符中提取文件名的辅助函数
#[inline]
fn extract_file_name_from_identifier(identifier: &str) -> Option<String> {
    // 尝试从标识符中提取文件名（通常包含进程名称）
    // 例如: "chrome.exe"
    if let Some(pos) = identifier.rfind('\\') {
        // 包含路径的情况
        identifier[pos + 1..].to_string().into()
    } else if let Some(pos) = identifier.rfind('/') {
        // Linux风格路径
        identifier[pos + 1..].to_string().into()
    } else {
        // 已经是文件名
        identifier.to_string().into()
    }
}

// 设置程序音量函数
#[unsafe(no_mangle)]
pub extern "C" fn setProgramVolume(program_name: *const u16, volume: c_float) -> c_int {
    // 验证音量范围
    if volume < 0.0 || volume > 1.0 {
        return -1; // 参数无效
    }

    // 如果program_name为空，返回错误
    if program_name.is_null() {
        return -1;
    }

    // 将u16指针转换为UTF-16字符串
    let program_name_str = unsafe { U16CString::from_ptr_str(program_name).to_string_lossy() };
    // println!("尝试设置程序 '{}' 的音量为 {}", program_name_str, volume);

    // 初始化COM
    if unsafe { CoInitialize(None).is_err() } {
        println!("COM初始化失败");
        return -1;
    }

    // 用于记录是否成功设置了任何程序的音量
    let mut found = false;

    // 在unsafe块中执行所有COM操作
    unsafe {
        // 创建MMDeviceEnumerator实例
        let enumerator: Result<IMMDeviceEnumerator> =
            CoCreateInstance(&MMDeviceEnumerator, None, CLSCTX_ALL);

        if let Ok(enumerator) = enumerator {
            // 获取默认音频渲染设备
            let device = enumerator.GetDefaultAudioEndpoint(ERENDER, ECONSOLE);

            if let Ok(device) = device {
                // 获取音频会话管理器
                let manager = device.Activate::<IAudioSessionManager2>(CLSCTX_ALL, None);

                if let Ok(manager) = manager {
                    // 获取IAudioSessionEnumerator接口来枚举所有会话
                    let session_enumerator = manager.GetSessionEnumerator();

                    if let Ok(session_enumerator) = session_enumerator {
                        // 获取会话数量
                        let count = session_enumerator.GetCount();

                        if let Ok(count) = count {
                            // 遍历所有会话
                            for i in 0..count {
                                // 获取当前会话
                                let session_control = session_enumerator.GetSession(i);

                                if let Ok(session_control) = session_control {
                                    // 查询IAudioSessionControl2接口
                                    let session_control2: Result<IAudioSessionControl2> =
                                        session_control.cast();

                                    if let Ok(session_control2) = session_control2 {
                                        // 获取会话标识符（通常包含进程名称）
                                        match session_control2.GetSessionIdentifier() {
                                            Ok(name_ptr) => {
                                                // 获取PWSTR的原始指针
                                                let raw_ptr = name_ptr.as_ptr();

                                                if !raw_ptr.is_null() {
                                                    // 转换标识符为Rust字符串
                                                    let str_obj = U16CString::from_ptr_str(raw_ptr);
                                                    let identifier = str_obj.to_string_lossy();

                                                    // 提取文件名并与目标程序名比较
                                                    if let Some(file_name) =
                                                        extract_file_name_from_identifier(
                                                            &identifier,
                                                        )
                                                    {
                                                        // println!("找到会话: {}", file_name);

                                                        // 忽略大小写进行比较
                                                        if file_name.to_lowercase().contains(
                                                            &program_name_str.to_lowercase(),
                                                        ) {
                                                            // 获取ISimpleAudioVolume接口
                                                            match session_control
                                                                .cast::<ISimpleAudioVolume>()
                                                            {
                                                                Ok(simple_volume) => {
                                                                    // 设置音量
                                                                    if simple_volume
                                                                        .SetMasterVolume(
                                                                            volume as f32,
                                                                            std::ptr::null(),
                                                                        )
                                                                        .is_ok()
                                                                    {
                                                                        // println!(
                                                                        //     "成功设置程序 '{}' 的音量为 {}",
                                                                        //     file_name, volume
                                                                        // );
                                                                        found = true;
                                                                    }
                                                                }
                                                                Err(e) => println!(
                                                                    "获取音量控制接口失败: {:?}",
                                                                    e
                                                                ),
                                                            }
                                                        }
                                                    }
                                                }
                                                // 手动调用CoTaskMemFree释放PWSTR内存
                                                CoTaskMemFree(Some(raw_ptr as *mut _))
                                            }
                                            Err(e) => println!("获取会话标识符失败: {:?}", e),
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 清理COM资源
    unsafe {
        CoUninitialize();
    }

    // 如果找到并设置了音量，返回0；否则返回1表示未找到匹配的程序
    if found {
        0
    } else {
        1 // 未找到匹配的程序
    }
}
