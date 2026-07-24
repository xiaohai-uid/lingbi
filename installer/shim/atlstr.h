// Minimal ATL string conversion shim for builds without the full ATL component.
// Provides CA2W (ANSI->wide) and CW2A (wide->ANSI) used by flutter_secure_storage_windows.
#pragma once
#include <windows.h>
#include <stdlib.h>

class CA2W {
public:
    explicit CA2W(LPCSTR pa, int nLength = -1)
        : m_psz(nullptr) {
        if (!pa) return;
        if (nLength == -1) nLength = (int)strlen(pa);
        int nChars = MultiByteToWideChar(CP_ACP, 0, pa, nLength, nullptr, 0);
        m_psz = (LPWSTR)malloc((nChars + 1) * sizeof(WCHAR));
        if (m_psz) {
            MultiByteToWideChar(CP_ACP, 0, pa, nLength, m_psz, nChars);
            m_psz[nChars] = 0;
        }
    }
    ~CA2W() { free(m_psz); }
    operator LPWSTR() { return m_psz; }
    operator LPCWSTR() const { return m_psz; }
    LPWSTR m_psz;
private:
    CA2W(const CA2W&);
    CA2W& operator=(const CA2W&);
};

class CW2A {
public:
    explicit CW2A(LPCWSTR pw, int nLength = -1)
        : m_psz(nullptr) {
        if (!pw) return;
        if (nLength == -1) nLength = (int)wcslen(pw);
        int nBytes = WideCharToMultiByte(CP_ACP, 0, pw, nLength, nullptr, 0, nullptr, nullptr);
        m_psz = (LPSTR)malloc(nBytes + 1);
        if (m_psz) {
            WideCharToMultiByte(CP_ACP, 0, pw, nLength, m_psz, nBytes, nullptr, nullptr);
            m_psz[nBytes] = 0;
        }
    }
    ~CW2A() { free(m_psz); }
    operator LPSTR() { return m_psz; }
    operator LPCSTR() const { return m_psz; }
    LPSTR m_psz;
private:
    CW2A(const CW2A&);
    CW2A& operator=(const CW2A&);
};
