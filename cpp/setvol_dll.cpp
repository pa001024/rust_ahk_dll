// 必要的头文件引入
#include <Mmdeviceapi.h>    // 音频设备管理API
#include <Audiopolicy.h>    // 音频策略管理API
#include <string>           // 字符串处理

// 配置编译环境使用UTF-8编码
#pragma 
#pragma execution_character_set("utf-8")

// DLL导出符号定义
#define DLL_EXPORT extern "C" __declspec(dllexport) // 构建DLL时导出函数

#pragma comment(lib, "ole32.lib")

// 从会话标识符中提取文件名
std::wstring ExtractFileNameFromIdentifier(WCHAR *identifier)
{
    std::wstring str(identifier);
    // 找到最后一个反斜杠的位置
    size_t lastBackslashPos = str.rfind(L'\\');
    if (lastBackslashPos == std::wstring::npos)
    {
        return L""; // 如果没找到返回空字符串
    }

    // 提取最后一个反斜杠后面的文件名
    std::wstring fileName = str.substr(lastBackslashPos + 1);

    // 找到第一个百分号的位置（参数开始）
    size_t paramPos = fileName.find(L'%');
    if (paramPos != std::wstring::npos)
    {
        // 去除参数部分
        fileName = fileName.substr(0, paramPos);
    }

    return fileName;
}

// 设置指定程序的音量
DLL_EXPORT int SetProgramVolume(WCHAR *programName, float volumeLevel)
{
    // 验证音量范围
    if (volumeLevel < 0.0f || volumeLevel > 1.0f)
    {
        return -1; // 无效的音量值
    }

    // 初始化COM库
    HRESULT hr = CoInitialize(NULL);
    if (FAILED(hr))
    {
        return -2; // COM initialization failed
    }

    int result = 1; // 默认未找到程序

    IMMDeviceEnumerator *deviceEnumerator = NULL;
    hr = CoCreateInstance(
        __uuidof(MMDeviceEnumerator), NULL,
        CLSCTX_ALL, __uuidof(IMMDeviceEnumerator),
        reinterpret_cast<void **>(&deviceEnumerator));
    if (SUCCEEDED(hr))
    {
        IMMDevice *defaultDevice = NULL;
        hr = deviceEnumerator->GetDefaultAudioEndpoint(eRender, eConsole, &defaultDevice);
        if (SUCCEEDED(hr))
        {
            IAudioSessionManager2 *sessionManager = NULL;
            hr = defaultDevice->Activate(__uuidof(IAudioSessionManager2), CLSCTX_ALL,
                                        NULL, reinterpret_cast<void **>(&sessionManager));
            if (SUCCEEDED(hr))
            {
                IAudioSessionEnumerator *sessionEnumerator = NULL;
                hr = sessionManager->GetSessionEnumerator(&sessionEnumerator);
                if (SUCCEEDED(hr))
                {
                    int sessionCount = 0;
                    hr = sessionEnumerator->GetCount(&sessionCount);
                    if (SUCCEEDED(hr))
                    {
                        for (int i = 0; i < sessionCount; ++i)
                        {
                            IAudioSessionControl *sessionControl = NULL;
                            hr = sessionEnumerator->GetSession(i, &sessionControl);
                            if (SUCCEEDED(hr))
                            {
                                IAudioSessionControl2 *sessionControl2 = NULL;
                                hr = sessionControl->QueryInterface(__uuidof(IAudioSessionControl2),
                                                                    (void **)&sessionControl2);
                                if (SUCCEEDED(hr))
                                {
                                    WCHAR *sessionInstanceIdentifier = NULL;
                                    hr = sessionControl2->GetSessionInstanceIdentifier(&sessionInstanceIdentifier);
                                    if (SUCCEEDED(hr) && sessionInstanceIdentifier)
                                    {
                                        auto programNameFound = ExtractFileNameFromIdentifier(sessionInstanceIdentifier);
                                        
                                        if (programNameFound == programName)
                                        {
                                            // 获取简单音频音量接口
                                            ISimpleAudioVolume *simpleAudioVolume = NULL;
                                            hr = sessionControl2->QueryInterface(__uuidof(ISimpleAudioVolume),
                                                                                (void **)&simpleAudioVolume);
                                            if (SUCCEEDED(hr))
                                            {
                                                hr = simpleAudioVolume->SetMasterVolume(volumeLevel, NULL);
                                                if (SUCCEEDED(hr))
                                                {
                                                    result = 0; // 成功设置音量
                                                }
                                                simpleAudioVolume->Release();
                                            }
                                        }
                                        
                                        CoTaskMemFree(sessionInstanceIdentifier);
                                    }
                                    sessionControl2->Release();
                                }
                                sessionControl->Release();
                            }
                        }
                    }
                    sessionEnumerator->Release();
                }
                sessionManager->Release();
            }
            defaultDevice->Release();
        }
        deviceEnumerator->Release();
    }

    // 清理COM库
    CoUninitialize();
    
    return result; // 0: 成功, 1: 未找到程序, 负数: 错误
}

// DLL入口点
BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        // DLL加载时执行初始化
        break;
    case DLL_THREAD_ATTACH:
        break;
    case DLL_THREAD_DETACH:
        break;
    case DLL_PROCESS_DETACH:
        // DLL卸载时执行清理
        break;
    }
    return TRUE;
}
