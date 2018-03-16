package
{
	import flash.display3D.IndexBuffer3D;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.charts.chartClasses.DataDescription;
	import mx.messaging.AbstractConsumer;
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.soap.LoadEvent;
	import mx.rpc.soap.WebService;
	import mx.utils.StringUtil;
	
	import org.osmf.events.LoaderEvent;
	
	public class SoapService
	{
		private var webserviceAddr:String="";
		public var mWebService1:WebService = new WebService;		
		public var bInitComplete :Boolean = false;
		public var m_iHousePanoramic:iHousePanoramic;
		private var xmlLoader: URLLoader = new URLLoader();
		
		//加载视频监控配置文件
		private function LoadSettingXML():void
		{
			xmlLoader.addEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR,LoadFailed);
			
			try
			{
				xmlLoader.load(new URLRequest("iHouse/setting.xml"));
			} 
			catch(error:Error) 
			{
				m_iHousePanoramic.mAlertDialog.show(error.toString());
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
				m_iHousePanoramic.mAlertDialog.show(error.message);
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
			
			m_iHousePanoramic.mAlertDialog.show("未能连接到WebService，网络错误。");  
		}
		
		public function LoadFailed(event:IOErrorEvent) :void
		{
			xmlLoader.removeEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.removeEventListener(FaultEvent.FAULT,LoadFailed);
			
			m_iHousePanoramic.mAlertDialog.show("LoadSettingXML failed");
		}
		public function SoapService(tParent:iHousePanoramic)
		{
			m_iHousePanoramic = tParent;
			
			//加载配置文件，读取soap服务地址
			LoadSettingXML();
		}
		
		public function WebServiceLoaded():Boolean
		{
			return bInitComplete;
		}
		
		public function OnBuildPanoramic(panoramicData:String):void
		{
			mWebService1.addEventListener(ResultEvent.RESULT, BuildPanoramicResponse);
			mWebService1.addEventListener(FaultEvent.FAULT, BuildPanoramicFailed);
			
			var op:AbstractOperation = mWebService1.getOperation("BuildHotspotPanoramic");	
			
			op.send(panoramicData);		
		}
		
		private function BuildPanoramicResponse(event:ResultEvent):void 
		{
			mWebService1.removeEventListener(Event.COMPLETE, BuildPanoramicResponse);
			mWebService1.removeEventListener(FaultEvent.FAULT,BuildPanoramicFailed);
			
			var strResult:String = event.result.toString();
			var url:URLRequest = new URLRequest("http://"+strResult);	
			flash.net.navigateToURL(url);
		}
		
		public function BuildPanoramicFailed(event:FaultEvent):void 
		{ 
			mWebService1.removeEventListener(Event.COMPLETE, BuildPanoramicResponse);
			mWebService1.removeEventListener(FaultEvent.FAULT,BuildPanoramicFailed);
			
			m_iHousePanoramic.mAlertDialog.show("生成全景失败.");
		} 
	}
}