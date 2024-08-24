#pragma once

#include "WinCommon/AdvTaskbar.h"

namespace SunJWBase
{
	public ref class AdvTaskbarHelper sealed
	{
	public:
		AdvTaskbarHelper(System::IntPtr hWnd);

	private:
		HWND m_hWnd;
		ITaskbarList3 *m_pTaskbarList3;
	};
}
