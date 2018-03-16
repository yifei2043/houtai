
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
	
	
	public class SchemeDataProcess
	{
		public var m_iHouse:iHouseSchemeManager = null;
		public var service:HTTPService = new HTTPService();
		public var xmlLoader: URLLoader = new URLLoader();
		
		public var webserviceAddr:String="";
		public var mProductInfo:String  =  "0";  //是否显示产品信息修改项
		
		public var mWebService1:WebService = new WebService;	
		public var mWebService2:WebService = new WebService;	
		
		public var bInitComplete :Boolean = false;
		
		public var mCompanyGroup:ArrayCollection   =new ArrayCollection();
		
		public function SchemeDataProcess(iHouse:iHouseSchemeManager)
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
				
			}
		}
		
		public function LoadFailed(event:IOErrorEvent) :void
		{
			xmlLoader.removeEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.removeEventListener(FaultEvent.FAULT,LoadFailed);
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
			
			//加载公司信息
			GetCompanyList();
		}
		
		private function OnWebService2Fault(e:FaultEvent):void  
		{   
			mWebService2.removeEventListener(Event.COMPLETE, OnWebService2Result);
			mWebService2.removeEventListener(FaultEvent.FAULT,OnWebService2Fault);
		}	
		
		/***
		 * 得到公司列表
		 * 
		 */
		public function GetCompanyList():void
		{
			var op:AbstractOperation = m_iHouse.mDataProcess.mWebService1.getOperation("GetCompanyList");
			m_iHouse.mDataProcess.mWebService1.addEventListener(FaultEvent.FAULT, OnOnCompanyListError);
			m_iHouse.mDataProcess.mWebService1.addEventListener(ResultEvent.RESULT,OnCompanyListResult);
			op.send(m_iHouse.mStrAccountType,m_iHouse.mStrCompanyID); 
		}
		
		private function OnOnCompanyListError(e:FaultEvent):void
		{
			m_iHouse.mDataProcess.mWebService1.removeEventListener(FaultEvent.FAULT,OnOnCompanyListError);
			m_iHouse.mDataProcess.mWebService1.removeEventListener(ResultEvent.RESULT,OnCompanyListResult);
			m_iHouse.mAlertDialog.show("系统繁忙,请重试.");	 
		}			
		
		public function OnCompanyListResult(e:ResultEvent):void
		{
			m_iHouse.mDataProcess.mWebService1.removeEventListener(FaultEvent.FAULT,  OnOnCompanyListError);
			m_iHouse.mDataProcess.mWebService1.removeEventListener(ResultEvent.RESULT,OnCompanyListResult);
			
			var strResult:String = e.result.toString();
			
			//获取到的数据异常
			if("0" == strResult)
				return;
			
			var strArray:Array = strResult.split("#");
			
			//初始显示公司帐号
			var strDefaultCompanyID:String = "";
			//从1开始，因为第一个数据为0
			for( var index:int = 1;index<strArray.length; ++index)  
			{
				var strRecord:String = strArray[index];
				var strRecordArray:Array = strRecord.split("~");
				
				mCompanyGroup.addItem({CompanyID:strRecordArray[0],   //公司ID
									  CompanyName:strRecordArray[1], //公司名称
									  Folder:strRecordArray[2]       //公司名称
				});
			}
			
			//获取所有公司下方案
			m_iHouse.mSchemeView.GetAllCompanyScheme();
		}
		
		//根据公司ID取得公司名称
		public function GetCompanyInfo(strCompanyID:String):Object
		{
			for each(var companyInfo:Object in mCompanyGroup)
			{
				if(companyInfo.CompanyID == strCompanyID)
				{
					return companyInfo;
				}
			}
			
			return null;
		}
	}	
}
