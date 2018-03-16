
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
	import mx.collections.ArrayCollection;
	import mx.messaging.AbstractConsumer;
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.soap.LoadEvent;
	import mx.rpc.soap.WebService;
	import mx.utils.StringUtil;
	
	import org.osmf.events.TimeEvent;
	
	
	public class UserDataProcess
	{
		public var m_iHouse:iHouseUserManager = null;
		public var service:HTTPService = new HTTPService();
		public var xmlLoader: URLLoader = new URLLoader();
		
		public var webserviceAddr:String="";
		public var mProductInfo:String  =  "0";  //是否显示产品信息修改项
		public var mCompanyInfo:String = "";     //针对指定公司特殊处理
		
		public var mWebService1:WebService = new WebService;	
		public var mWebService2:WebService = new WebService;	
		
		public var bInitComplete :Boolean = false;
		
		public var mCompanyGroup:ArrayCollection   =new ArrayCollection();
		
		public function UserDataProcess(iHouse:iHouseUserManager)
		{
			m_iHouse = iHouse;
			
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
				mProductInfo = settingXMlData.setting.show.@productinfo;
				mCompanyInfo = settingXMlData.setting.company.@info;
				
				if(webserviceAddr != "")
				   InitWebService1();
					
			}
			catch(error:Error)
			{
		//		m_iHouse3DView.mAlertDialog.show(error.message);
			}
		}
		
		public function LoadFailed(event:IOErrorEvent) :void
		{
			xmlLoader.removeEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.removeEventListener(FaultEvent.FAULT,LoadFailed);
			
			//	m_iHouse3DView.mAlertDialog.show("LoadSettingXML failed");
		}
		
		public function InitWebService1():void
		{
			mWebService1.wsdl= webserviceAddr+"service1.asmx?wsdl";
			mWebService1.addEventListener(LoadEvent.LOAD, OnWebService1Result);  
			mWebService1.addEventListener(FaultEvent.FAULT, OnWebService1Fault);
			mWebService1.loadWSDL();   
		} 
		
		private function OnWebService1Result(e:LoadEvent):void  
		{  
			mWebService1.removeEventListener(Event.COMPLETE, OnWebService1Result);
			mWebService1.removeEventListener(FaultEvent.FAULT,OnWebService1Fault);
			
			InitWebService2();
		}
		
		private function OnWebService1Fault(e:FaultEvent):void  
		{   
			mWebService1.removeEventListener(Event.COMPLETE, OnWebService1Result);
			mWebService1.removeEventListener(FaultEvent.FAULT,OnWebService1Fault);
			
		//	m_iHouse3DView.mAlertDialog.show("未能连接到WebService，网络错误。");  
		}
		
		
		public function InitWebService2():void
		{
			mWebService2.wsdl= webserviceAddr+"service2.asmx?wsdl";
			mWebService2.addEventListener(LoadEvent.LOAD, OnWebService2Result);  
			mWebService2.addEventListener(FaultEvent.FAULT, OnWebService2Fault);
			mWebService2.loadWSDL();   
		} 
		
		private function OnWebService2Result(e:LoadEvent):void  
		{  
			mWebService2.removeEventListener(Event.COMPLETE, OnWebService2Result);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnWebService2Fault);
			
			bInitComplete = true;
						
			m_iHouse.mUserView.GetCompanyList();	
		}
		
		private function OnWebService2Fault(e:FaultEvent):void  
		{   
			mWebService2.removeEventListener(Event.COMPLETE, OnWebService2Result);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnWebService2Fault);
			
			//	m_iHouse3DView.mAlertDialog.show("未能连接到WebService，网络错误。");  
		}	
	}	
}
