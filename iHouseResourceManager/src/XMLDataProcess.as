package
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.FaultEvent;

	public class XMLDataProcess
	{
		public var xmlLoader: URLLoader = new URLLoader();
		
		public var m_iHouse:iHouseResourceManager = null;
		
		//保存颜色数据
		public var m_colorArray:ArrayCollection = new ArrayCollection;
		
		//保存类型数据
		public var m_styleArray:ArrayCollection = new ArrayCollection;
		
		//保存品牌数据
		public var m_brandArray:ArrayCollection = new ArrayCollection;
		
		public function XMLDataProcess(iHouse:iHouseResourceManager)
		{
			m_iHouse = iHouse;
			
			LoadSettingXML();
		}
		
		private function LoadSettingXML():void
		{
			xmlLoader.addEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR,LoadFailed);
			
			try
			{
				var url:String = "iHouse/QueryFilter.xml?" + (new Date).milliseconds;				
				xmlLoader.load(new URLRequest(url));
			} 
			catch(error:Error) 
			{
				m_iHouse.mHelpDialog.show(error.toString());
			}			
		}
		
		private function CompleteXMLHandle(e:Event):void
		{
			xmlLoader.removeEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.removeEventListener(FaultEvent.FAULT,LoadFailed);

			if("" == e.target.data)
			{
				m_iHouse.mHelpDialog.show("QueryFilter.xml文件数据为空");
				return;
			}
			
			ParseSettingXML(e.target.data);
		}
		
		public function ParseSettingXML(strXmlData:String):void
		{
			try
			{
				var xmlData:XML = XML(strXmlData);	
				
				//颜色
				for each(var cItem:XML in xmlData.color.item)
				{
					if(cItem.@name != "不限")
					m_colorArray.addItem({name:cItem.@name,value:cItem.@value});
				}
				
				//类型
				for each(var sItem:XML in xmlData.style.item)
				{
					if(sItem.@name != "不限")
					m_styleArray.addItem({name:sItem.@name});
				}

				//品牌
				for each(var bItem:XML in xmlData.brand.item)
				{
					m_brandArray.addItem({name:bItem.@name});
				}
				
				//创建界面按钮
				m_iHouse.InitQueryDialog();
			}
			catch(error:Error)
			{
				m_iHouse.mHelpDialog.show(error.message);
			}
		}
		
		public function LoadFailed(event:IOErrorEvent) :void
		{
			xmlLoader.removeEventListener(Event.COMPLETE, CompleteXMLHandle);
			xmlLoader.removeEventListener(FaultEvent.FAULT,LoadFailed);
			
			m_iHouse.mHelpDialog.show("加载QueryFilter.xml 失败");
		}
	}
}