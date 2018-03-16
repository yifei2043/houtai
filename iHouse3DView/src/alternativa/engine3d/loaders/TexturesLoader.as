/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.loaders {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.loaders.events.TexturesLoaderEvent;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.ExternalTextureResource;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.CubeTexture;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	use namespace alternativa3d;

	/**
	 * Dispatches after complete loading of all textures.
	 * @eventType flash.events.TexturesLoaderEvent.COMPLETE
	 */
	[Event(name="complete",type="alternativa.engine3d.loaders.events.TexturesLoaderEvent")]

	/**
	 * An object that downloads textures by their reference and upload them into the <code>Context3D</code>
	 */
	public class TexturesLoader extends EventDispatcher {

		/**
		 * A <code>Context3D</code> to which resources wil be loaded.
		 */
		public var context:Context3D;

		private var textures:Object = {};
		private var bitmapDatas:Object = {};
		private var byteArrays:Object = {};

		private var currentBitmapDatas:Vector.<BitmapData>;
		private var currentUrl:String;

		private var resources:Vector.<ExternalTextureResource>;
		private var counter:int = 0;
		private var createTexture3D:Boolean;
		private var needBitmapData:Boolean;

		private var loaderCompressed:URLLoader;
		private var isATF:Boolean;
		private var atfRegExp:RegExp = new RegExp(/\.atf/i);

		/**
		 * Creates a new TexturesLoader instance.
		 * @param context – A <code>Context3D</code> to which resources wil be loaded.
		 */
		
		// chen 
		public function TexturesLoader(context:Context3D, Parent:Object=null) {
			this.context = context;
			m_cPoint = Parent;
		}

		/**
		 * @private
		 */
		public function getTexture(url:String):TextureBase {
			return textures[url];
		}

		private function loadCompressed(url:String):void {
			loaderCompressed = new URLLoader();
			loaderCompressed.dataFormat = URLLoaderDataFormat.BINARY;
			loaderCompressed.addEventListener(Event.COMPLETE, loadNext);
			loaderCompressed.addEventListener(IOErrorEvent.IO_ERROR, loadNext);
			loaderCompressed.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadNext);
			loaderCompressed.load(new URLRequest(url));
		}

		/**
		 * Loads a resource.
		 * @param resource
		 * @param createTexture3D Create texture on uploading
		 * @param needBitmapData If <code>true</code>, keeps <code>BitmapData</code> after uploading textures into a context.
		 */
		public function loadResource(resource:ExternalTextureResource, createTexture3D:Boolean = true, needBitmapData:Boolean = true):void {
			if (resources != null) {
				throw new Error("Cannot start new load while loading");
			}
			this.createTexture3D = createTexture3D;
			this.needBitmapData = needBitmapData;
			resources = Vector.<ExternalTextureResource>([resource]);
			currentBitmapDatas = new Vector.<BitmapData>(1);
			//currentTextures3D = new Vector.<Texture>(1);
			loadNext();
		}

		/**
		 * Loads list of textures
		 * @param resources   List of <code>ExternalTextureResource</code> each of them has link to texture file which needs to be downloaded.
		 * @param createTexture3D Create texture on uploading.
		 * @param needBitmapData If <code>true</code>, keeps <code>BitmapData</code> after uploading textures into a context.
		 */
		public function loadResources(resources:Vector.<ExternalTextureResource>, createTexture3D:Boolean = true, needBitmapData:Boolean = true):void {
			if (this.resources != null) {
				throw new Error("Cannot start new load while loading");
			}
			this.createTexture3D = createTexture3D;
			this.needBitmapData = needBitmapData;
			this.resources = resources;
			currentBitmapDatas = new Vector.<BitmapData>(resources.length);
			loadNext();
		}

		/**
		 * Clears links to all data stored in this <code>TexturesLoader</code> instance. (List of downloaded textures)
		 */
		public function clean():void {
			if (resources != null) {
				throw new Error("Cannot clean while loading");
			}
			textures = {};
			bitmapDatas = {};
		}

		/**
		 * Clears links to all data stored in this <code>TexturesLoader</code> instance and removes it from the context.
		 */
		public function cleanAndDispose():void {
			if (resources != null) {
				throw new Error("Cannot clean while loading");
			}
			textures = {};
			for each (var b:BitmapData in bitmapDatas) {
				b.dispose();
			}
			bitmapDatas = {};
		}

		/**
		 * Removes texture resources from <code>Context3D</code>.
		 * @param urls List of links to resources, that should be removed.
		 */
		public function dispose(urls:Vector.<String>):void {
			for (var i:int = 0; i < urls.length; i++) {
				var url:String = urls[i];
				var bmd:BitmapData = bitmapDatas[url] as BitmapData;
				//if (bmd) {
				delete bitmapDatas[url];
				bmd.dispose();
				//}
			}
		}
		
		/**
		 *  输入一个颜色,将它拆成三个部分:  
		 * 红色,绿色和蓝色  
		 */    
		public static function retrieveRGBComponent( color:uint ):Array    
		{    
			var r:Number = (color >> 16) & 0xff;    
			var g:Number = (color >> 8) & 0xff;    
			var b:Number = color & 0xff;    
			
			return [r, g, b];    
		}    
		
		/**  
		 * 红色,绿色和蓝色三色组合  
		 */    
		public static function generateFromRGBComponent( rgb:Array ):uint    
		{    
			if( rgb == null || rgb.length != 3 ||     
				rgb[0] < 0 || rgb[0] > 255 ||    
				rgb[1] < 0 || rgb[1] > 255 ||    
				rgb[2] < 0 || rgb[2] > 255 )    
				return 0xFFFFFF;    
			return rgb[0] << 16 | rgb[1] << 8 | rgb[2];    
		}  		
		
		/** 
		 *  双线性插值缩放 
		 */  
		public  function OnImageScale(srcBMP:BitmapData,destW:Number,destH:Number):Bitmap  
		{  
			var destBMP:Bitmap = null;  
			var destData:BitmapData = new BitmapData(destW,destH);  
			
			//	var srcData:BitmapData = srcBMP.bitmapData;  
			var srcW:Number = srcBMP.width;  
			var srcH:Number = srcBMP.height;  
			
			var scaleX:Number = srcW/destW;  
			var scaleY:Number = srcH/destH;  
			
			for(var j:int=0;j<destH;++j){       //j为目标图像的纵坐标   
				for(var i:int=0;i<destW;++i){   //i为目标图像的横坐标   
					//坐标进行反向变化   
					var srcX:Number = i*scaleX;  
					var srcY:Number = j*scaleY;     
					
					var m:int = int(srcX); //m为源图像横坐标的整数部分   
					var n:int = int(srcY); //n为源图像纵坐标的整数部分   
					var u:Number = srcX-m; //p为源图像横坐标小数部分   
					var v:Number = srcY-n; //r为源图像纵坐标的小数部分   
					
					//公式  f(m+p,n+r) = (1-p)(1-r)*f(m,n) + (1-p)r*f(m,n+1) + p(1-r)f(m+1,n) + p*r*f(m+1,n+1)   
					var aArray:Array;
					var bArray:Array;
					var cArray:Array;
					var dArray:Array;
					
					/*  aArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					bArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					cArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					dArray = retrieveRGBComponent(srcBMP.getPixel(m,n));	*/		
					
					aArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					bArray = retrieveRGBComponent(srcBMP.getPixel(m,n+1));  
					cArray = retrieveRGBComponent(srcBMP.getPixel(m+1,n));  
					dArray = retrieveRGBComponent(srcBMP.getPixel(m+1,n+1));	
					
					/*		var aArray,bArray,cArray,dArray:Array;
					//将颜色分解成  r,g,b   
					if( j >=destH-2 || i >=destW- 2)
					{
					aArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					bArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					cArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					dArray = retrieveRGBComponent(srcBMP.getPixel(m,n));							
					}
					else
					{
					aArray = retrieveRGBComponent(srcBMP.getPixel(m,n));  
					bArray = retrieveRGBComponent(srcBMP.getPixel(m,n+1));  
					cArray = retrieveRGBComponent(srcBMP.getPixel(m+1,n));  
					dArray = retrieveRGBComponent(srcBMP.getPixel(m+1,n+1));						
					}	
					*/	     			
					
					var r:Number =  (1-u)*(1-v)*aArray[0]+(1-u)*v*bArray[0]+u*(1-v)*cArray[0]+ u*v*dArray[0];  
					var g:Number =  (1-u)*(1-v)*aArray[1]+(1-u)*v*bArray[1]+u*(1-v)*cArray[1]+ u*v*dArray[1];  
					var b:Number =  (1-u)*(1-v)*aArray[2]+(1-u)*v*bArray[2]+u*(1-v)*cArray[2]+ u*v*dArray[2];   
					
					var colorArray:Array = new Array(r,g,b);  
					// r,g,b合成颜色   
					var color:uint = generateFromRGBComponent(colorArray);  
					//设置目标图像某点的颜色                         
					destData.setPixel(i,j,color);  
				}    
			}  
			
			destBMP = new Bitmap(destData);  
			return destBMP;  
		}		

		private function loadNext(e:Event = null):void {
//			trace("[NEXT]", e);
			var bitmapData:BitmapData =null;
			var byteArray:ByteArray;
			var texture3D:TextureBase;

			if (e != null && !(e is ErrorEvent)) {
				if (isATF) {
					byteArray = e.target.data;
					byteArrays[currentUrl] = byteArray;
					try {
						texture3D = addCompressedTexture(byteArray);
						resources[counter - 1].data = texture3D;
					} catch (err:Error) {
						//					throw new Error("loadNext:: " + err.message  + " " + currentUrl);
						trace("loadNext:: " + err.message + " " + currentUrl);
					}
				} else {
					bitmapData = e.target.content.bitmapData;
					
					// chenxiang 纹理大小2的幂		
					//========================================================================================
					if( ( bitmapData.width == 64 && bitmapData.height == 64 )   ||
						
						( bitmapData.width == 512 && bitmapData.height == 128 )  ||
						( bitmapData.width == 128 && bitmapData.height == 512 )  ||
						
						( bitmapData.width == 128 && bitmapData.height == 256 )  ||
						( bitmapData.width == 256 && bitmapData.height == 128 )  ||
						
						( bitmapData.width == 128 && bitmapData.height == 64 )  ||
						( bitmapData.width == 64 && bitmapData.height == 128 )  ||
						
						( bitmapData.width == 256 && bitmapData.height == 64 )  ||
						( bitmapData.width == 64 && bitmapData.height == 256 )  ||
						
						( bitmapData.width == 256 && bitmapData.height == 512 ) ||
						( bitmapData.width == 512 && bitmapData.height == 256 ) ||
						
						( bitmapData.width == 128 && bitmapData.height == 128 ) ||
						( bitmapData.width == 256 && bitmapData.height == 256 ) ||
						
						( bitmapData.width == 1024 && bitmapData.height == 512 ) ||
						( bitmapData.width == 512 && bitmapData.height == 1024 ) ||

						( bitmapData.width == 1024 && bitmapData.height == 256 ) ||
						( bitmapData.width == 256 && bitmapData.height == 1024 ) ||						
	
						( bitmapData.width == 1024 && bitmapData.height == 128 ) ||
						( bitmapData.width == 128 && bitmapData.height == 1024 ) ||	
						
						( bitmapData.width == 1024 && bitmapData.height == 64 ) ||
						( bitmapData.width == 64 && bitmapData.height == 1024 ) ||	
						
						( bitmapData.width == 1024 && bitmapData.height == 1024 ) ||
						( bitmapData.width == 512 && bitmapData.height == 512 )) 
					{
						bitmapData 	= bitmapData;
					}
					else
						bitmapData = OnImageScale(bitmapData,256,256).bitmapData;					
					//========================================================================================
					bitmapDatas[currentUrl] = bitmapData;
					currentBitmapDatas[counter - 1] = bitmapData;
					if (createTexture3D) {
						try {
							// 纹理大小2的幂数
							texture3D = addTexture(bitmapData);
							resources[counter - 1].data = texture3D;
							
							//chen
							resources[counter-1].bitmapData = bitmapData;
						} catch (err:Error) {
							throw new Error("loadNext:: " + err.message + " " + currentUrl);
						}
					}
					if (!needBitmapData) {
						bitmapData.dispose();
					}
				}
				resources[counter - 1].data = texture3D;
			} else if (e is ErrorEvent) {
				trace("Missing: " + currentUrl);
			}

			if (counter < resources.length) {
				currentUrl = resources[counter++].url;
				if (currentUrl != null) {
					atfRegExp.lastIndex = currentUrl.lastIndexOf(".");
					isATF = currentUrl.match(atfRegExp) != null;
				}

				if (isATF) {
					if (createTexture3D) {
						texture3D = textures[currentUrl];
						if (texture3D == null) {
							byteArray = byteArrays[currentUrl];
							if (byteArray) {
								texture3D = addCompressedTexture(byteArray);
								resources[counter - 1].data = texture3D;
								//bitmapDatas[currentUrl] = bitmapData;
								loadNext();
							} else {
								loadCompressed(currentUrl);
							}
						} else {
							resources[counter - 1].data = texture3D;
							loadNext();
						}
					}
				} else {
					if (needBitmapData) {
						bitmapData = bitmapDatas[currentUrl];
						if (bitmapData) {
							currentBitmapDatas[counter - 1] = bitmapData;
							if (createTexture3D) {
								texture3D = textures[currentUrl];
								if (texture3D == null) {
									texture3D = addTexture(bitmapData);
								}
								resources[counter - 1].data = texture3D;
							}
							loadNext();
						} else {
							load(currentUrl);
						}
					} else if (createTexture3D) {
						texture3D = textures[currentUrl];
						if (texture3D == null) {
							bitmapData = bitmapDatas[currentUrl];
							if (bitmapData) {
								texture3D = addTexture(bitmapData);
								resources[counter - 1].data = texture3D;
								loadNext();
							} else {
								load(currentUrl);
							}
						} else {
							resources[counter - 1].data = texture3D;
							loadNext();
						}
					}
				}
			} else {
				onTexturesLoad();
			}
		}

		private function load(url:String):void {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.DISK_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.NETWORK_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.VERIFY_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadNext);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,OnProgress);				// chen
			//loader.load(new URLRequest(url));

			loader.load(new URLRequest(url),new LoaderContext(true));	// chen 跨域访问
		}

		// chen
		//====================================================================================
		public var m_cPoint:Object;
		public function OnProgress(evt : ProgressEvent):void
		{
			if(m_cPoint )
				m_cPoint.OnProgress(evt);
		}
		//====================================================================================
		
		private function onTexturesLoad():void {
//			trace("[LOADED]");
			counter = 0;
			var bmds:Vector.<BitmapData> = currentBitmapDatas;
			var reses:Vector.<ExternalTextureResource> = resources;
			currentBitmapDatas = null;
			resources = null;
			dispatchEvent(new TexturesLoaderEvent(TexturesLoaderEvent.COMPLETE, bmds, reses));
		}

		private function addTexture(value:BitmapData):Texture {
			var texture:Texture = context.createTexture(value.width, value.height, Context3DTextureFormat.BGRA, false);
			texture.uploadFromBitmapData(value, 0);
			BitmapTextureResource.createMips(texture, value);
			textures[currentUrl] = texture;
			return texture;
		}

		private function addCompressedTexture(value:ByteArray):TextureBase {
			value.endian = Endian.LITTLE_ENDIAN;
			value.position = 6;
			var texture:TextureBase
			var type:uint = value.readByte();
			var format:String;
			switch (type & 0x7F) {
				case 0:
					format = Context3DTextureFormat.BGRA;
					break;
				case 1:
					format = Context3DTextureFormat.BGRA;
					break;
				case 2:
					format = Context3DTextureFormat.COMPRESSED;
					break;
			}
			if ((type & ~0x7F) == 0) {
				texture = context.createTexture(1 << value.readByte(), 1 << value.readByte(), format, false);
				Texture(texture).uploadCompressedTextureFromByteArray(value, 0);
			} else {
				texture = context.createCubeTexture(1 << value.readByte(), format, false);
				CubeTexture(texture).uploadCompressedTextureFromByteArray(value, 0)
			}
			textures[currentUrl] = texture;
			return texture;
		}

	}
}
