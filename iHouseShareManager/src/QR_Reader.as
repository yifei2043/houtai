package  
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	/**
	 * ...
	 * @author sk
	 */
	public class QR_Reader extends Sprite
	{
		private var file:FileReference;
		private var _file:FileReference;
		
		public function QR_Reader() 
		{
			file = new FileReference();
			
			
			stage.addEventListener(MouseEvent.CLICK, onClick);
			configureListeners(file);
		}
		
		private function onClick(e:MouseEvent):void 
		{
			 file.browse();

		}
		private function configureListeners(dispatcher:IEventDispatcher):void {
            dispatcher.addEventListener(Event.CANCEL, cancelHandler);
            dispatcher.addEventListener(Event.COMPLETE, completeHandler);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            dispatcher.addEventListener(Event.OPEN, openHandler);
            dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            dispatcher.addEventListener(Event.SELECT, selectHandler);
        }
		
		private function selectHandler(e:Event):void 
		{
			trace("select", e)
			_file = FileReference(e.target);
			trace(_file.name);
			
			//trace(_file.data);
		}
		
		private function securityErrorHandler(e:SecurityErrorEvent):void 
		{
			trace("error",e)
		}
		
		private function progressHandler(e:ProgressEvent):void 
		{
			trace(" progress",e)
		}
		
		private function openHandler(e:Event):void 
		{
			trace(" open",e)
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void 
		{
			
		}
		
		private function completeHandler(e:Event):void 
		{
			trace(" complete",e)
		}
		
		private function cancelHandler(e:Event):void 
		{
			trace("  cancel",e)
		}
	}

}