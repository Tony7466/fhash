#pragma once

#include <msclr\auto_gcroot.h>

#include "Common/UIBridgeBase.h"
#include "Common/Global.h"

#include "UIBridgeDelegate.h"
#include "ResultDataNet.h"

namespace FilesHashWUI
{
	ResultDataNet ConvertResultDataToNet(const ResultData& result);

	class UIBridgeWUI : public UIBridgeBase
	{
	public:
		UIBridgeWUI(UIBridgeDelegate^ uiBridgeDelegate);
		virtual ~UIBridgeWUI();

		virtual void lockData();
		virtual void unlockData();

		virtual void preparingCalc();
		virtual void removePreparingCalc();
		virtual void calcStop();
		virtual void calcFinish();

		virtual void showFileName(const ResultData& result);
		virtual void showFileMeta(const ResultData& result);
		virtual void showFileHash(const ResultData& result, bool uppercase);
		virtual void showFileErr(const ResultData& result);

		virtual int getProgMax();
		virtual void updateProg(int value);
		virtual void updateProgWhole(int value);

		virtual void fileCalcFinish();
		virtual void fileFinish();

	private:
		msclr::auto_gcroot<UIBridgeDelegate^> m_uiBridgeDelegate;
	};
}
