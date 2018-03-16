
package 
{
	import com.adobe.serialization.json.*;
	import com.adobe.utils.StringUtil;
	
	import flash.display3D.IndexBuffer3D;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.charts.chartClasses.DataDescription;
	import mx.containers.Form;
	import mx.core.IFactory;
	import mx.messaging.AbstractConsumer;
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.rpc.soap.LoadEvent;
	import mx.rpc.soap.WebService;
	import mx.utils.StringUtil;
	
	import org.osmf.events.TimeEvent;
	
	
	public class ResourceDataProcess
	{
		public var m_iHouse:iHouseResourceManager = null;
		public var service:HTTPService = new HTTPService();
		public var xmlLoader: URLLoader = new URLLoader();
		
		public var webserviceAddr:String="";
		public var mProductInfo:String  =  "0";  //是否显示产品信息修改项
		
		public var mWebService1:WebService = new WebService;	
		public var mWebService2:WebService = new WebService;	
		
		public var bInitComplete :Boolean = false;
		
		public function ResourceDataProcess(iHouse:iHouseResourceManager)
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
				//xmlLoader.load(new URLRequest("setting.xml")); //单独使用时测试
			} 
			catch(error:Error) 
			{
				m_iHouse.mAlertDialog.show(error.toString());
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

				if(webserviceAddr != "")
				   InitWebService1();
					
			}
			catch(error:Error)
			{
		    	m_iHouse.mAlertDialog.show(error.message);
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
			
			m_iHouse.mAlertDialog.show("未能连接到WebService，网络错误。");  
		}
		
		///////////////////////////////////////////////////////////////////////////
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
			
			//加载模型数据
			m_iHouse.LoadModelData();

		}
		
		private function OnWebService2Fault(e:FaultEvent):void  
		{   
			mWebService2.removeEventListener(Event.COMPLETE, OnWebService2Result);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnWebService2Fault);
			
			//	m_iHouse3DView.mAlertDialog.show("未能连接到WebService，网络错误。");  
		}
		
		//-------------------------------修改贴图分类 --------------------------------------
		public function OnChangeMaterialcxClass(strUUID:String ,strClass1:String,strClass2:String,strName:String):void
		{
			var op:AbstractOperation = mWebService2.getOperation("ChangeMaterialcxClass");
			mWebService2.addEventListener(ResultEvent.RESULT,OnChangeMaterialResult);
			mWebService2.addEventListener(FaultEvent.FAULT,OnChangeMaterialFault);
			
			op.send( strUUID,strClass1,strClass2,strName);
		}
		
		private function OnChangeMaterialResult(event:ResultEvent):void
		{
			mWebService2.removeEventListener(ResultEvent.RESULT,OnChangeMaterialResult);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnChangeMaterialFault);
			
			m_iHouse.mDataMatView.OnChange(null);
			m_iHouse.mAlertDialog.show("更新成功!");
			m_iHouse.mChangeMaterialClassDlg.visible = false;
		}
		
		private function OnChangeMaterialFault(event:FaultEvent):void
		{
			mWebService2.removeEventListener(ResultEvent.RESULT,OnChangeMaterialResult);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnChangeMaterialFault);
			
			m_iHouse.mAlertDialog.show("更新失败,失败原因：" + event.toString());
		}
		//-------------------------------修改贴图分类 ----------------------------------------------------
		
		//-------------------------------修改模型分类-----------------------------------------------------
		public function OnChangeModelClass(strUUID:String ,strClass1:String,strClass2:String,strClass3:String,strName:String):void
		{
			var op:AbstractOperation = mWebService2.getOperation("ChangeModelClass");
			mWebService2.addEventListener(ResultEvent.RESULT,OnChangeModelResult);
			mWebService2.addEventListener(FaultEvent.FAULT,OnChangeModelFault);
			
			op.send(strUUID,strClass1,strClass2,strClass3,strName);	
		}
		
		private function OnChangeModelResult(event:ResultEvent):void
		{
			mWebService2.removeEventListener(ResultEvent.RESULT,OnChangeModelResult);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnChangeModelFault);
			
			m_iHouse.mDataView.OnChange(null);
			m_iHouse.mAlertDialog.show("更新成功!");
			m_iHouse.mChangeModelClassDlg.visible = false;
		}
		
		private function OnChangeModelFault(event:FaultEvent):void
		{
			mWebService2.removeEventListener(ResultEvent.RESULT,OnChangeModelResult);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnChangeModelFault);
			
			m_iHouse.mAlertDialog.show("更新失败,失败原因：" + event.toString());
		}

		
	}	
}
