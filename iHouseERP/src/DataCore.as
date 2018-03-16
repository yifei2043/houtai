package  
{

	import com.adobe.crypto.MD5;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.soap.LoadEvent;
	import mx.rpc.soap.WebService;
	
	import org.osmf.events.TimeEvent;

	public class DataCore extends Sprite
	{			
		public var m_iHouse:iHouseERP;		
		public var webService:WebService = new WebService();
		public function DataCore()
		{
			
		}
		
		//初始化数据中心
		public var mWebService1:WebService	= new WebService();
		public var mWebService2:WebService		= new WebService();
		public function InitDataCore():void
		{
			mWebService1.addEventListener(LoadEvent.LOAD, OnInitResult );
			mWebService1.wsdl= m_iHouse.m_strHttp+"service1.asmx?wsdl";
			
			mWebService1.addEventListener(ResultEvent.RESULT, OnService1Result);  
			mWebService1.addEventListener(FaultEvent.FAULT, OnService1Fault);		
			mWebService1.loadWSDL();   
		}     
		
		private function OnService1Result(e:ResultEvent):void  
		{  
			mWebService1.removeEventListener(Event.COMPLETE, OnService1Result);  
			mWebService1.removeEventListener(FaultEvent.FAULT, OnService1Fault);
		}
		
		private function OnService1Fault(e:FaultEvent):void  
		{   
			mWebService1.removeEventListener(Event.COMPLETE, OnService1Result);  
			mWebService1.removeEventListener(FaultEvent.FAULT, OnService1Fault);
			
			m_iHouse.mHelpDialog.show("未能连接到WebService，网络错误。");  
		} 		
		
		public function OnInitResult(e:LoadEvent):void
		{
			mWebService1.removeEventListener(Event.COMPLETE, OnInitResult );
			
			mWebService2.addEventListener(LoadEvent.LOAD, OnService2Result );
			mWebService2.addEventListener(FaultEvent.FAULT, OnService2Fault );
			mWebService2.wsdl= m_iHouse.m_strHttp+"service2.asmx?wsdl";
			mWebService2.loadWSDL(); 			
		}
		
		private function OnService2Result(e:LoadEvent):void  
		{  
			mWebService2.removeEventListener(Event.COMPLETE, OnService2Result );
			mWebService2.removeEventListener(FaultEvent.FAULT, OnService2Fault );
		}
		
		private function OnService2Fault(e:FaultEvent):void  
		{  
			mWebService2.removeEventListener(Event.COMPLETE, OnService2Result );
			mWebService2.removeEventListener(FaultEvent.FAULT, OnService2Fault );
			
			m_iHouse.mHelpDialog.show("未能连接到WebService2，网络错误。");  
		} 		
	}	
}