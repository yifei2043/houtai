
package 
{
	import flash.display3D.IndexBuffer3D;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.charts.chartClasses.DataDescription;
	import mx.messaging.AbstractConsumer;
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.soap.LoadEvent;
	import mx.rpc.soap.WebService;
	import mx.utils.StringUtil;
	
	import org.osmf.events.TimeEvent;
	
	
	public class DataProcess
	{
		public var m_iHouse3DView:iHouse3DView = null;
		public var service:HTTPService = new HTTPService();
		public var xmlLoader: URLLoader = new URLLoader();
		public var webserviceAddr:String="";
		
		public var mWebService1:WebService = new WebService;		
		public var bInitComplete :Boolean = false;
		
		public function DataProcess(house3DView:iHouse3DView)
		{
			m_iHouse3DView = house3DView;
			
			//加载配置文件，读取soap服务地址
			LoadSettingXML();
		}
		
		//加载视频监控配置文件
		private function LoadSettingXML():void
		{
			trace("LoadSettingXML..."); 
			xmlLoader.addEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR,LoadFailed);
			
			try
			{
				xmlLoader.load(new URLRequest("iHouse/setting.xml"));
			} 
			catch(error:Error) 
			{
	//			m_iHouse3DView.mAlertDialog.show(error.toString());
			}			
		}
		
		private function CompleteXMLHandle(e:Event):void
		{
			xmlLoader.removeEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.removeEventListener(FaultEvent.FAULT,LoadFailed);
			
			if("" != e.target.data)
				ParseSettingXML(e.target.data);
		}
		
		public function ParseSettingXML(strXmlData:String):void
		{
			try
			{
				var settingXMlData:XML = XML(strXmlData);
				
				webserviceAddr = settingXMlData.setting.webservice.@addr;	
				
				if(webserviceAddr != "")
				   InitWebService();
					
			}
			catch(error:Error)
			{
		//		m_iHouse3DView.mAlertDialog.show(error.message);
			}
		}
		
		public function InitWebService():void
		{
			mWebService1.wsdl= webserviceAddr+"service1.asmx?wsdl";
			mWebService1.addEventListener(LoadEvent.LOAD, OnWebServiceResult);  
			mWebService1.addEventListener(FaultEvent.FAULT, OnWebServiceFault);
			mWebService1.loadWSDL();   
		} 
		
		private function OnWebServiceResult(e:LoadEvent):void  
		{  
			mWebService1.removeEventListener(Event.COMPLETE, OnWebServiceResult);
			mWebService1.removeEventListener(FaultEvent.FAULT,OnWebServiceFault);
			
			bInitComplete = true;
		}
		
		private function OnWebServiceFault(e:FaultEvent):void  
		{   
			mWebService1.removeEventListener(Event.COMPLETE, OnWebServiceResult);
			mWebService1.removeEventListener(FaultEvent.FAULT,OnWebServiceFault);
			
		//	m_iHouse3DView.mAlertDialog.show("未能连接到WebService，网络错误。");  
		}
		
		public function LoadFailed(event:IOErrorEvent) :void
		{
			xmlLoader.removeEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.removeEventListener(FaultEvent.FAULT,LoadFailed);
			
		//	m_iHouse3DView.mAlertDialog.show("LoadSettingXML failed");
		}
		

		/***
		 * 1. 加载数据到服务器烘培队列
		 * 
		 */
		public var m_bBakeHouse:Boolean = true;
		public var m_strFileID:String;
		public function OnCreateFile(dataByte:ByteArray, bHouse:Boolean = true ):void
		{
			m_bBakeHouse = bHouse;			
			
			var op:AbstractOperation = mWebService1.getOperation("CreateQueue");
			mWebService1.addEventListener(FaultEvent.FAULT, OnErrorRender);
			mWebService1.addEventListener(ResultEvent.RESULT,OnCreateQueueResult);
			op.send(dataByte);    
		}       
		
		/**
		 * 关闭烘培云服务器
		 * 
		 */
		private function OnErrorRender(e:FaultEvent):void
		{
			mWebService1.removeEventListener(FaultEvent.FAULT,OnErrorRender);
			mWebService1.removeEventListener(ResultEvent.RESULT,OnCreateQueueResult);
		//	m_iHouse3DView.mHelpDialog.show("系统繁忙,没申请到渲染服务,请重试.");	
		}
		
		/***
		 * 2. 侦听循环等待 烘培是否完成
		 * 
		 */ 
		private var timer:Timer = new Timer(500, 0);
		private var m_delayTimer:int = 0;
		public function OnCreateQueueResult(e:ResultEvent):void
		{
			mWebService1.removeEventListener(FaultEvent.FAULT,OnErrorRender);
			mWebService1.removeEventListener(ResultEvent.RESULT,OnCreateQueueResult);
			
			m_strFileID = e.result.toString();
			
			m_iCount_Timer = 0;	
			m_delayTimer   = 0;
			
			m_iHouse3DView.mShowRendering.m_ProgressTime.text    = "连接云渲染服务器...";
			m_iHouse3DView.mShowRendering.m_ProgressTime1.text   = "0.0%";
			
			timer.addEventListener(TimerEvent.TIMER, OnWaitForLightmap);//侦听时间
			timer.start();  
		}
		
		/***
		 *  每隔二秒询问是否已经渲染完成
		 * 
		 *  1. 每隔两秒查询一次服务器
		 * 
		 *  2. 10秒后自动停止 
		 * 
		 */
		private function OnWaitForLightmap(event:Event):void            
		{ 
			m_delayTimer++;
			if( m_delayTimer %4 == 0 )	// 每两秒询问一次
			{
				var op:AbstractOperation = mWebService1.getOperation("CheckIsFinish");
				mWebService1.addEventListener(ResultEvent.RESULT,OnCheckIsFinishResult);
				op.send( m_strFileID );
			}
		}	
		
		/**        
		 * 
		 *  更改成完成状态,移出渲染队列
		 */
		public function OnStopBake():void
		{			
			timer.removeEventListener(TimerEvent.TIMER, OnWaitForLightmap);
			timer.stop();	
			m_iCount_Timer = 0;	
					
		}
		
		/***
		 * 结束烘培 
		 */
		public function OnStopBakeResult(e:ResultEvent):void
		{
			mWebService1.removeEventListener(ResultEvent.RESULT,OnStopBakeResult);
		}
		//=================================================================================================
		
		public  var m_strBakePNGPath:String;
		public  var m_strBakeFilePath:String;
		public  var m_iCount_Timer:int = 0;		// 超出20秒 可以渲染第二次
		private function OnCheckIsFinishResult(e:ResultEvent):void
		{
			
			mWebService1.removeEventListener(ResultEvent.RESULT,OnCheckIsFinishResult);				
			
			var str:String = e.result.toString();
			var strArray:Array = str.split("~");
			
			if( strArray[0] == "2")	// 渲染完成
			{
				timer.removeEventListener(TimerEvent.TIMER, OnWaitForLightmap);
				timer.stop();
				
				// 下载已生成烘培图片
				m_strBakePNGPath = webserviceAddr + "uploadfile/"+strArray[3];
				m_strBakeFilePath=webserviceAddr + "uploadfile/"+strArray[4];	
				OnStopBake();
				OnShowRendering(e);
			}
			if( strArray[0] == "0")	// 得到当前排队人数
			{
				var op:AbstractOperation = mWebService1.getOperation("GetCount");
				mWebService1.addEventListener(ResultEvent.RESULT,OnGetCountResult);
				op.send(strArray[1]);
			}
			
			if( strArray[0] == "1")
			{
				if(strArray[2] == "ready" )	
				{
					m_iHouse3DView.mShowRendering.m_ProgressTime.text    = "云渲染服务器初始化...";
					m_iHouse3DView.mShowRendering.m_ProgressTime1.text   = "0.0%";				
				}
				else
				{
					m_iHouse3DView.mShowRendering.m_ProgressTime.text    = "云渲染开始";
					m_iHouse3DView.mShowRendering.m_ProgressTime1.text   = String(strArray[2]);					
				}
			}			
		}
		
		/***
		 * 得到排队人数
		 * 
		 */
		private function OnGetCountResult(e:ResultEvent):void
		{
			mWebService1.removeEventListener(ResultEvent.RESULT,OnGetCountResult);	
			
			var strCount:String = e.result.toString();
			
			if( int(strCount) >= 1 )	// 显示排队人数
			{
				m_iHouse3DView.mShowRendering.m_ProgressTime.text    = "当前有"+strCount+"人在排队等待云渲染";
			}
			else					// 开始3分钟渲染计时
			{
				m_iHouse3DView.mShowRendering.m_ProgressTime.text    = "正在渲染效果图"+m_delayTimer/4;
			}
		}	
		
		/***
		 * 显示效果图
		 * 
		 */
		public function OnShowRendering(e:Event):void
		{
			m_iHouse3DView.mShowRendering.mImage.source   = m_strBakePNGPath;
			m_iHouse3DView.mShowRendering.visible 		  = true;
			m_iHouse3DView.mShowRendering.HideLoading();
			//	gMain.mShowRendering.m_cRenderUI.visible = false;
			m_iHouse3DView.mShowRendering.m_ProgressTime.text = "";	
			m_iHouse3DView.mShowRendering.m_ProgressTime1.text= "";
			m_iCount_Timer = 0;				
		}
		
		public function StopRender():void
		{
			var op:AbstractOperation = mWebService1.getOperation("StopRender");
			mWebService1.addEventListener(FaultEvent.FAULT, OnStopRenderError);
			mWebService1.addEventListener(ResultEvent.RESULT,OnStopRenderResult);
			op.send(m_strFileID);    
		}
		
		private function OnStopRenderError(e:FaultEvent):void
		{
			mWebService1.removeEventListener(FaultEvent.FAULT,OnStopRenderError);
			mWebService1.removeEventListener(ResultEvent.RESULT,OnStopRenderResult);
			m_iHouse3DView.mAlert3DViewDialog.show("系统繁忙,没申请到渲染服务,请重试.");	
		}
		
		public function OnStopRenderResult(e:ResultEvent):void
		{
			mWebService1.removeEventListener(FaultEvent.FAULT,OnStopRenderError);
			mWebService1.removeEventListener(ResultEvent.RESULT,OnStopRenderResult);
			
			var strResult:String = e.result.toString();
			trace(strResult);
		}
	}	
}
