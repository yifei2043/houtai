package
{	
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.loaders.Parser3DS;
	import alternativa.engine3d.loaders.ParserA3D;
	import alternativa.engine3d.loaders.ParserMaterial;
	import alternativa.engine3d.loaders.TexturesLoader;
	import alternativa.engine3d.loaders.events.TexturesLoaderEvent;
	import alternativa.engine3d.materials.LightMapMaterial;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.StandardMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Surface;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.Plane;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.ExternalTextureResource;
	import alternativa.engine3d.resources.Geometry;
	
	import flash.display.BitmapData;
	import flash.display.Stage3D;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Vector3D;
	import flash.media.Camera;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import mx.controls.Alert;
	
	import spark.core.SpriteVisualElement;
	
	public class RenderOBJ3New extends SpriteVisualElement
	{
		
		public var stage3D:Stage3D;
		public var controller:OrbitCameraController;
		public var camera:Camera3D;
		private var rootContainer:Object3D;
		private var spaceContainer:Object3D;
		
		private static var _instance:RenderOBJ3New;
		private var cameraContainer:Object3D;
		
		public var gMain:iHouse3DView;
		public var m_CoordCross:WireFrame;
		public var m_coordinate:WireFrame;
		public var m_strPath:String;			//路径
		public var m_strPathFile:String;		//路径加文件名
		public var m_MeshArray:Vector.<Mesh>  	= new Vector.<Mesh>;
		
		private var m_fLengthOld:Number = 1;
		private var m_fWidthOld:Number  = 1;
		private var m_fHeightOld:Number = 1;
		
		public var flength:Number;
		public var fWidth:Number;   
		public var fHeight:Number;  
		public var m_picSize:String;
		public var m_strPathThumbnail:String;
		
		public function RenderOBJ3New(v:Single)
		{
			if(!stage)
			{
				this.addEventListener(Event.ADDED_TO_STAGE, addToStage);
			}else{
				
				addToStage(null);
			}
		}
		
		private function addToStage(e:Event):void
		{
			stage3D = this.stage.stage3Ds[3]; 
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, initSpace3D);
			stage3D.requestContext3D();
		}
		
		public function initSpace3D(e:Event):void
		{	
			if(stage == null)
				return;
			
			camera=new Camera3D(1, 40000);
			camera.view=new View(400,300, false,0x000000,1,4 );
			//camera.view=new View(gMain.mShow3DView.width,gMain.mShow3DView.height, false,0x000000,1,4 );
			controller = new OrbitCameraController(gMain, camera, stage,this.parent,this.parent);
			controller.disableKey();
			controller.maxDistance = 15000;
			controller.setLatitude(10);
			
	
			addChild(camera.view);
			addChild(camera.diagram);  
			
			camera.view.hideLogo();
			camera.diagram.visible = true;
			rootContainer   = new Object3D();
			rootContainer.addChild(camera);
			
			m_coordinate = CreateReferenceLines(100, 100, 0xCCCCCC);
			m_coordinate.name = "coord";			
			rootContainer.addChild(m_coordinate);
			
			m_CoordCross = CreateCrossLines(100, 100, 0xff0000);
			m_CoordCross.name = "coord";			
			rootContainer.addChild(m_CoordCross);			
			
			for each (var resource:Resource in rootContainer.getResources(true)) {
				resource.upload(stage3D.context3D);
			}
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public  var m_bL3D:Boolean = false;
		public  var m_loader:URLLoader = new URLLoader();
		public  var m_strFile:String;
		public function OnLoadA3D(strPathA3D:String, strFile:String):void
		{
			m_MeshArray.length = 0;
			var k:int = strPathA3D.lastIndexOf("/");
			
			m_strPath = strPathA3D.slice(0,k+1);
			m_strFile = strFile;
			
			var times:Date = new Date;
			m_strPathFile = strPathA3D+"?"+String(times.milliseconds);	
			m_loader.dataFormat = URLLoaderDataFormat.BINARY;

			m_loader.load(new URLRequest(m_strPathFile));  
			m_loader.addEventListener(ProgressEvent.PROGRESS, OnProgress);
			m_loader.addEventListener(Event.COMPLETE,loadModelComplete);
		}	
		
		public function OnProgress(evt : ProgressEvent):void
		{	
			var off:uint = evt.bytesLoaded/evt.bytesTotal *100;
			gMain.mShow3DView.m_cProgressGroup.visible    = true;	
			gMain.mShow3DView.m_cProgress.label = "下载资源进度:" + off.toFixed(2);	
			gMain.mShow3DView.m_cProgress.setProgress(int(off.toFixed(2)), 100);		
		}		
		
		public function LoadA3D(e:Event):void
		{
			var flength:Number;
			var fWidth:Number;   
			var fHeight:Number; 
			var bbox:BoundBox = new BoundBox();
			bbox.maxX = bbox.maxY = bbox.maxZ = - 99999;
			bbox.minX = bbox.minY = bbox.minZ =   99999;
			var textures:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>();			
			var parser:ParserA3D = new ParserA3D();   
			
			//加密数据
			//========================================================================================
			var OutByteArray:ByteArray = (e.target as URLLoader).data;
			OutByteArray.position = 0;
			OutByteArray.endian   = Endian.LITTLE_ENDIAN;			
			var strMM:String 	  = OutByteArray.readUTFBytes(3);
			var iVerison:int 	  = OutByteArray.readInt();
			if( strMM == "MM?" && iVerison == 2013 ) 
			{
				var InByteArray:ByteArray  = new ByteArray;
				InByteArray.position = 0;  
				InByteArray.endian   = Endian.LITTLE_ENDIAN;	//高低位互换		
				InByteArray.writeBytes((e.target as URLLoader).data,11);
				parser.parse(InByteArray);
			}
			else		
				parser.parse((e.target as URLLoader).data);	
			//========================================================================================			
			
			if( parser == null )
				return;		
			
			for each (var object:Object3D in parser.objects) 		// 计算长宽
			{
				var mesh:Mesh = object as Mesh;
				if( mesh != null )
				{
					mesh.calculateBoundBox();				
					if( bbox.maxX < mesh.boundBox.maxX ) bbox.maxX = mesh.boundBox.maxX;
					if( bbox.maxY < mesh.boundBox.maxY ) bbox.maxY = mesh.boundBox.maxY;
					if( bbox.maxZ < mesh.boundBox.maxZ ) bbox.maxZ = mesh.boundBox.maxZ;
					
					if( bbox.minX > mesh.boundBox.minX ) bbox.minX = mesh.boundBox.minX;
					if( bbox.minY > mesh.boundBox.minY ) bbox.minY = mesh.boundBox.minY;
					if( bbox.minZ > mesh.boundBox.minZ ) bbox.minZ = mesh.boundBox.minZ;				
				}
			}   
			
			flength = Math.abs(bbox.maxX-bbox.minX);
			fWidth  = Math.abs(bbox.maxY-bbox.minY);
			fHeight = Math.abs(bbox.maxZ-bbox.minZ);
			
			if(flength >= fWidth  &&  flength >= fHeight )
				controller.setDistance(flength);
			
			if(fWidth >= flength  &&  fWidth >= fHeight )
				controller.setDistance(fWidth);
			
			if(fHeight >= flength  &&  fHeight >= fWidth )
				controller.setDistance(fHeight);
			
			//============================================================================================================
			for( var m:int = 0 ; m<parser.objects.length; m++ )		// 普通家具
			{
				var mesh:Mesh = parser.objects[m] as Mesh;
				if( mesh != null )
				{
					var bTextureMaterial:Boolean =true;
					
					mesh.z    =0;//fHeight/2;
					mesh.x 	  =0;
					mesh.y 	  =0;
					
					rootContainer.addChild(mesh);
					m_MeshArray.push(mesh);	
					uploadResources(mesh.getResources(false, Geometry));
					
					for (var i:int = 0; i < mesh.numSurfaces; i++) 
					{
						var surface:Surface = mesh.getSurface(i);
						var material:ParserMaterial = surface.material as ParserMaterial;
						if (material != null)
						{
							
							var trans:ExternalTextureResource = material.textures["emission"];
							if( trans == null )
							{
								trans = material.textures["transparent"];
								bTextureMaterial = true;
							}
							else
								bTextureMaterial = false;
							
							var diffuse:ExternalTextureResource = material.textures["diffuse"];	
							if( trans != null )
							{
								var str1:String = trans.url;
								str1.toLocaleLowerCase();
								trans.url =OnSetHttp(str1);				
								textures.push(trans);
							}   
							if (diffuse != null) {   
								
								var str:String = diffuse.url;
								str.toLocaleLowerCase();
								diffuse.url =OnSetHttp(str);									
								
								textures.push(diffuse);
								
								var mat2:LightMapMaterial 	= new LightMapMaterial(diffuse,trans)
								mat2.lightMapChannel    = 1;
								mat2.diffuseMap
								var mat1:TextureMaterial 	= new TextureMaterial(diffuse, trans);
								mat1.alphaThreshold 		= 0.9;
								mat1.transparentPass 		= true;
								mat1.opaquePass 			= true;
								
								if( bTextureMaterial == false )
									surface.material 			= mat2;
								else
									surface.material 			= mat1;						
							}
						}						
					}
					mesh.name ="1";
				}  
			}				
			
			var texturesLoader:TexturesLoader = new TexturesLoader(stage3D.context3D);
			texturesLoader.loadResources(textures);	
			texturesLoader.addEventListener(TexturesLoaderEvent.COMPLETE, OnUpdateMesh);
			m_loader.close();			
		}
		
		public function Load3DS(e:Event):void
		{
			var flength:Number;
			var fWidth:Number;   
			var fHeight:Number; 
			var bbox:BoundBox = new BoundBox();
			bbox.maxX = bbox.maxY = bbox.maxZ = - 99999;
			bbox.minX = bbox.minY = bbox.minZ =   99999;
			var textures:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>();		
			var parser:Parser3DS = new Parser3DS();
			//加密数据
			//========================================================================================
			/*			var OutByteArray:ByteArray = (e.target as URLLoader).data;
			OutByteArray.position = 0;
			OutByteArray.endian   = Endian.LITTLE_ENDIAN;			
			var strMM:String 	  = OutByteArray.readUTFBytes(3);
			var iVerison:int 	  = OutByteArray.readInt();
			if( strMM == "MM?" && iVerison == 2013 ) 
			{
			var InByteArray:ByteArray  = new ByteArray;
			InByteArray.position = 0;  
			InByteArray.endian   = Endian.LITTLE_ENDIAN;	//高低位互换		
			InByteArray.writeBytes((e.target as URLLoader).data,11);
			parser.parse(InByteArray);
			}
			else*/		
			parser.parse((e.target as URLLoader).data);	
			//========================================================================================			
			
			if( parser == null )
				return;		
			
			for each (var object:Object3D in parser.objects) 		// 计算长宽
			{
				var mesh:Mesh = object as Mesh;
				if( mesh != null )
				{
					mesh.calculateBoundBox();				
					if( bbox.maxX < mesh.boundBox.maxX ) bbox.maxX = mesh.boundBox.maxX;
					if( bbox.maxY < mesh.boundBox.maxY ) bbox.maxY = mesh.boundBox.maxY;
					if( bbox.maxZ < mesh.boundBox.maxZ ) bbox.maxZ = mesh.boundBox.maxZ;
					
					if( bbox.minX > mesh.boundBox.minX ) bbox.minX = mesh.boundBox.minX;
					if( bbox.minY > mesh.boundBox.minY ) bbox.minY = mesh.boundBox.minY;
					if( bbox.minZ > mesh.boundBox.minZ ) bbox.minZ = mesh.boundBox.minZ;				
				}
			}   
			
			flength = Math.abs(bbox.maxX-bbox.minX);
			fWidth  = Math.abs(bbox.maxY-bbox.minY);
			fHeight = Math.abs(bbox.maxZ-bbox.minZ);
			
			if(flength >= fWidth  &&  flength >= fHeight )
				controller.setDistance(flength);
			
			if(fWidth >= flength  &&  fWidth >= fHeight )
				controller.setDistance(fWidth);
			
			if(fHeight >= flength  &&  fHeight >= fWidth )
				controller.setDistance(fHeight);
			
			//============================================================================================================
			for( var m:int = 0 ; m<parser.objects.length; m++ )		// 普通家具
			{
				var mesh:Mesh = parser.objects[m] as Mesh;
				if( mesh != null )
				{
					var bTextureMaterial:Boolean =true;
					
					mesh.z    =0;//fHeight/2;
					mesh.x 	  =0;
					mesh.y 	  =0;
					
					rootContainer.addChild(mesh);
					m_MeshArray.push(mesh);	
					uploadResources(mesh.getResources(false, Geometry));
					
					for (var i:int = 0; i < mesh.numSurfaces; i++) 
					{
						var surface:Surface = mesh.getSurface(i);
						var material:ParserMaterial = surface.material as ParserMaterial;
						if (material != null)
						{
							
							var trans:ExternalTextureResource = material.textures["emission"];
							if( trans == null )
							{
								trans = material.textures["transparent"];
								bTextureMaterial = true;
							}
							else
								bTextureMaterial = false;
							
							var diffuse:ExternalTextureResource = material.textures["diffuse"];	
							if( trans != null )
							{
								var str1:String = trans.url;
								str1.toLocaleLowerCase();
								trans.url =OnSetHttp(str1);				
								textures.push(trans);
							}   
							if (diffuse != null) {   
								
								var str:String = diffuse.url;
								str.toLocaleLowerCase();
								diffuse.url =OnSetHttp(str);									
								
								textures.push(diffuse);
								
								var mat2:LightMapMaterial 	= new LightMapMaterial(diffuse,trans)
								mat2.lightMapChannel    = 1;
								mat2.diffuseMap
								var mat1:TextureMaterial 	= new TextureMaterial(diffuse, trans);
								mat1.alphaThreshold 		= 0.9;
								mat1.transparentPass 		= true;
								mat1.opaquePass 			= true;
								
								if( bTextureMaterial == false )
									surface.material 			= mat2;
								else
									surface.material 			= mat1;						
							}
						}						
					}
					mesh.name ="1";
				}  
			}				
			
			var texturesLoader:TexturesLoader = new TexturesLoader(stage3D.context3D);
			texturesLoader.loadResources(textures);	
			texturesLoader.addEventListener(TexturesLoaderEvent.COMPLETE, OnUpdateMesh);
			m_loader.close();			
		}
		
		public function loadModelComplete(e:Event):void 
		{
			m_loader.removeEventListener(Event.COMPLETE,loadModelComplete);
			
			for(var m:int = rootContainer.numChildren-1; m>=0; m--)
			{
				if( rootContainer.getChildAt(m).name =="1" )				
					rootContainer.removeChildAt(m);	
			}
			
			m_strPathFile = m_strPathFile.toLocaleLowerCase();
			
			if( -1 != m_strPathFile.indexOf(".a3d") )
			{
				LoadA3D(e);
			}
			
			if( -1 != m_strPathFile.indexOf(".3ds"))
			{
				Load3DS(e);
			}	
		}
		
		/*
		public function loadModelComplete(e:Event):void 
		{
			m_loader.removeEventListener(ProgressEvent.PROGRESS, OnProgress);
			m_loader.removeEventListener(Event.COMPLETE,loadModelComplete);
			
			for(var m:int = rootContainer.numChildren-1; m>=0; m--)
			{
				if( rootContainer.getChildAt(m).name =="1" )				
					rootContainer.removeChildAt(m);	
			}

			var iCount:int = m_strPathFile.lastIndexOf(".");		
			var str:String = m_strPathFile.slice(iCount+1);
		
			var bbox:BoundBox = new BoundBox();
			bbox.maxX = bbox.maxY = bbox.maxZ = - 99999;
			bbox.minX = bbox.minY = bbox.minZ =   99999;
			var textures:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>();
			

			var parser:ParserA3D = new ParserA3D();   
			
			//加密数据
			//========================================================================================
			var OutByteArray:ByteArray = (e.target as URLLoader).data;
			OutByteArray.position = 0;
			OutByteArray.endian   = Endian.LITTLE_ENDIAN;			
			var strMM:String 	  = OutByteArray.readUTFBytes(3);
			var iVerison:int 	  = OutByteArray.readInt();
			if( strMM == "MM?" && iVerison == 2013 ) 
			{
				var InByteArray:ByteArray  = new ByteArray;
				InByteArray.position = 0;  
				InByteArray.endian   = Endian.LITTLE_ENDIAN;	//高低位互换		
				InByteArray.writeBytes((e.target as URLLoader).data,11);
				parser.parse(InByteArray);
			}
			else		
				parser.parse((e.target as URLLoader).data);	
			//========================================================================================			

			if( parser == null )
				return;		
			
			for each (var object:Object3D in parser.objects) 		// 计算长宽
			{
				var mesh:Mesh = object as Mesh;
				if( mesh != null )
				{
					mesh.calculateBoundBox();				
					if( bbox.maxX < mesh.boundBox.maxX ) bbox.maxX = mesh.boundBox.maxX;
					if( bbox.maxY < mesh.boundBox.maxY ) bbox.maxY = mesh.boundBox.maxY;
					if( bbox.maxZ < mesh.boundBox.maxZ ) bbox.maxZ = mesh.boundBox.maxZ;
					
					if( bbox.minX > mesh.boundBox.minX ) bbox.minX = mesh.boundBox.minX;
					if( bbox.minY > mesh.boundBox.minY ) bbox.minY = mesh.boundBox.minY;
					if( bbox.minZ > mesh.boundBox.minZ ) bbox.minZ = mesh.boundBox.minZ;				
				}
			}   
			
			flength = Math.abs(bbox.maxX-bbox.minX);
			fWidth  = Math.abs(bbox.maxY-bbox.minY);
			fHeight = Math.abs(bbox.maxZ-bbox.minZ); 
			gMain.mShow3DView.mSize.text = flength.toFixed(2) + "X" + fWidth.toFixed(2) + "X" + fHeight.toFixed(2);

						
			if(flength >= fWidth  &&  flength >= fHeight )
				controller.setDistance(flength);
			
			if(fWidth >= flength  &&  fWidth >= fHeight )
				controller.setDistance(fWidth);
	
			if(fHeight >= flength  &&  fHeight >= fWidth )
				controller.setDistance(fHeight);
			m_coordinate.z =-fHeight/2;
			m_CoordCross.z =-fHeight/2;
			//============================================================================================================
			for( var m:int = 0 ; m<parser.objects.length; m++ )		// 普通家具
			{
				var mesh:Mesh = parser.objects[m] as Mesh;
				if( mesh != null )
				{
					var bTextureMaterial:Boolean =true;
					
					mesh.z    =-fHeight/2;
					mesh.x 	  =0;
					mesh.y 	  =0;
					
					rootContainer.addChild(mesh);
					m_MeshArray.push(mesh);	
					uploadResources(mesh.getResources(false, Geometry));
										
					for (var i:int = 0; i < mesh.numSurfaces; i++) 
					{
						var surface:Surface = mesh.getSurface(i);
						var material:ParserMaterial = surface.material as ParserMaterial;
						if (material != null)
						{

							var trans:ExternalTextureResource = material.textures["emission"];
							if( trans == null )
							{
								trans = material.textures["transparent"];
								bTextureMaterial = true;
							}
							else
								bTextureMaterial = false;
							
							var diffuse:ExternalTextureResource = material.textures["diffuse"];	
							if( trans != null )
							{
								var str1:String = trans.url;
								str1.toLocaleLowerCase();
								trans.url =OnSetHttp(str1);				
								textures.push(trans);
							}   
							if (diffuse != null) {   
								
								var str:String = diffuse.url;
								str.toLocaleLowerCase();
								diffuse.url =OnSetHttp(str);									
								
								textures.push(diffuse);
								
								var mat2:LightMapMaterial 	= new LightMapMaterial(diffuse,trans)
								mat2.lightMapChannel    = 1;
								
								var mat1:TextureMaterial 	= new TextureMaterial(diffuse, trans);
								mat1.alphaThreshold 		= 0.9;
								mat1.transparentPass 		= true;
								mat1.opaquePass 			= true;
								
								if( bTextureMaterial == false )
									surface.material 			= mat2;
								else
									surface.material 			= mat1;						
							}
						}						
					}
					mesh.name ="1";
				}  
			}				

			var texturesLoader:TexturesLoader = new TexturesLoader(stage3D.context3D,this);
			texturesLoader.loadResources(textures);	
			texturesLoader.addEventListener(TexturesLoaderEvent.COMPLETE, OnUpdateMesh);
			m_loader.close();	
		}
		*/
			
		public function CreateReferenceLines(lines:Number, interval:Number, color:uint):WireFrame
		{
			var points:Vector.<Vector3D> = new Vector.<Vector3D>;
			
			var i:Number;
			for(i=-lines/2; i<=lines/2; i++)
			{
				points.push(new Vector3D(-lines/2*interval, i*interval, -10));
				points.push(new Vector3D( lines/2*interval, i*interval, -10));
				
				points.push(new Vector3D(i*interval, -lines/2*interval, -10));
				points.push(new Vector3D(i*interval,  lines/2*interval, -10));
			}
			
			points.push(new Vector3D(-lines/2*interval, 0, -10));
			points.push(new Vector3D( lines/2*interval, 0, -10));
			
			points.push(new Vector3D(0, -lines/2*interval, -10));
			points.push(new Vector3D(0,  lines/2*interval, -10));		
			
			return WireFrame.createLinesList(points, color, 1, 1);//0xF0F0F0FF
		}	
		
		public function CreateCrossLines(lines:Number, interval:Number, color:uint):WireFrame
		{
			var points:Vector.<Vector3D> = new Vector.<Vector3D>;
			points.push(new Vector3D(-lines/2*interval, 0, -10));
			points.push(new Vector3D( lines/2*interval, 0, -10));
			
			points.push(new Vector3D(0, -lines/2*interval, -10));
			points.push(new Vector3D(0,  lines/2*interval, -10));		
			
			return WireFrame.createLinesList(points, color, 1, 2);//0xF0F0F0FF
		}			
		
		private function OnSetHttp(str:String):String
		{	
			
			var strHttp:String;
			var iIndex:int = str.lastIndexOf("/");
			
			if( str.search("http:/") != -1 || str.search("../") !=-1 || str.search(":") !=-1 )			// 同一模型,调用两次以上相同材质				
				return str;	
			
			var times:Date = new Date;

			if( iIndex !== -1 )
			{				
				strHttp = m_strPath+str+"?"+String(times.milliseconds);					
			}
			else  
				strHttp = m_strPath+str+"?"+String(times.milliseconds);
			
			return strHttp;
		}		
				
		private function OnUpdateMesh(event:TexturesLoaderEvent):void
		{						
			for each (var resource:Resource in this.rootContainer.getResources(true))
			{
				resource.upload(stage3D.context3D);
			}	
			gMain.mShow3DView.m_cProgressGroup.visible = false;
		}	
				
		private function uploadResources(resources:Vector.<Resource>):void {
			for each (var resource:Resource in resources) {
				resource.upload(stage3D.context3D);
			}
		}
		
		protected function onMouseDownView(event:MouseEvent):void
		{
			if(stage == null)
				return;
			
			stage.focus = camera.view;
		}
		
		private function onEnterFrame(e:Event):void 
		{
			camera.view.width=this.parent.width;
			camera.view.height=this.parent.height;			
			controller.update();
			camera.render(stage3D);
		}
		
		public static function getInstance():RenderOBJ3New
		{
			if(_instance==null) _instance = new RenderOBJ3New(new Single());
			return _instance;
		}
	}
}

class Single{}