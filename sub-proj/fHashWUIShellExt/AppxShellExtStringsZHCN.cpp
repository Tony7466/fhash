#include "AppxShellExtStringsZHCN.h"

#include <tchar.h>

AppxShlExtStringsZHCN::AppxShlExtStringsZHCN()
{
	// Shell ext
#if defined (_DEBUG)
	m_stringsMap[_T("SHELL_EXT_DISPLAY_NAME")] = _T("ʹ�� fHash DEV �����ϣ");
#else
	m_stringsMap[_T("SHELL_EXT_DISPLAY_NAME")] = _T("ʹ�� fHash �����ϣ");
#endif
}
