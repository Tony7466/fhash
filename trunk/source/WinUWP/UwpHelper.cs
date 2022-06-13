﻿using System;
using Windows.ApplicationModel.DataTransfer;
using Windows.Foundation;
using Windows.System;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Documents;

namespace FilesHashUwp
{
    class UwpHelper
    {
        public static UIElement GetRootFrame()
        {
            return Window.Current.Content;
        }

        public static Point GetCursorPointRelatedToRootFrame()
        {
            Point cursorPoint = Window.Current.CoreWindow.PointerPosition;
            Rect windowBount = Window.Current.Bounds;
            Point relativePoint = new Point(cursorPoint.X - windowBount.X, cursorPoint.Y - windowBount.Y);
            return relativePoint;
        }

        public static void CopyStringToClipboard(string text)
        {
            DataPackage dataPackage = new DataPackage { RequestedOperation = DataPackageOperation.Copy };
            dataPackage.SetText(text);
            Clipboard.SetContent(dataPackage);
        }

        public static void OpenUrl(string url)
        {
            Uri uri = new Uri(url);
            _ = Launcher.LaunchUriAsync(uri);
        }

        public static Run GenRunFromString(string strContent)
        {
            Run run = new Run();
            run.Text = strContent;
            return run;
        }

        public static Underline GenUnderlineFromString(string strContent)
        {
            Underline underline = new Underline();
            underline.Inlines.Add(GenRunFromString(strContent));
            return underline;
        }

        public static Hyperlink GenHyperlinkFromString(string strContent, TypedEventHandler<Hyperlink, HyperlinkClickEventArgs> clickHandler)
        {
            Hyperlink hyperlink = new Hyperlink();
            hyperlink.Inlines.Add(GenRunFromString(strContent));
            hyperlink.UnderlineStyle = UnderlineStyle.None;
            if (clickHandler != null)
            {
                hyperlink.Click += clickHandler;
            }
            return hyperlink;
        }

        public static string GetTextFromHyperlink(Hyperlink hyperlink)
        {
            if (hyperlink.Inlines.Count == 0)
            {
                return null;
            }
            Run run = (Run)hyperlink.Inlines[0];
            return run.Text;
        }

        public static void ScrollViewerToBottom(ScrollViewer scrollViewer)
        {
            scrollViewer.Measure(scrollViewer.RenderSize);
            scrollViewer.ChangeView(null, scrollViewer.ScrollableHeight, null);
        }
    }
}
