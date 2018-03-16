package  
{
	import com.google.zxing.BarcodeFormat;
	import com.google.zxing.BinaryBitmap;
	import com.google.zxing.BufferedImageLuminanceSource;
	import com.google.zxing.client.result.ParsedResult;
	import com.google.zxing.client.result.ResultParser;
	import com.google.zxing.common.flexdatatypes.HashTable;
	import com.google.zxing.common.GlobalHistogramBinarizer;
	import com.google.zxing.DecodeHintType;
	import com.google.zxing.qrcode.QRCodeReader;
	import com.google.zxing.Result;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.system.System;
	/**
	 * ...
	 * @author sk
	 */
	public class QRreader extends Sprite
	{
		private var _video:Video;
		private var _camera:Camera;
		private var _qrCodeReader:QRCodeReader;
		private var _qrCodeData:String;
		private var _bitmapData:BitmapData;
		
		public function QRreader() 
		{
			if (stage)
			this.addEventListener(Event.ADDED_TO_STAGE, init);
			else init(null);
		}
		private function init(e:Event):void 
		{
			initCamera();
			stage.addEventListener(MouseEvent.CLICK,onClick)
		}
		
		private function onClick(e:MouseEvent):void 
		{
			decodeSnapshot()
		}
		
		private function initCamera():void {
			//this.currentState = 'snapshot';
			
			if( Camera.isSupported ) {
				_video = new Video( 400, 400 );
				_camera = Camera.getCamera();
				
				// Basic settings.
				_camera.setMode( 400, 400, 24 );
				
				// Rotate to work in "portrait" layout.
				_video.rotation = 90;
				
				// Reposition because the rotation will place the video off screen.
				_video.x = 400;
				
				_video.attachCamera( _camera );
				
				this.addChild( _video );
				
				_qrCodeReader = new QRCodeReader();
			} else {
				trace( "Camera not supported"  );
			}
		}
		
		private function closeCamera():void {
			// It is important to set _video and _camera to null
			// otherwise the "Camera" is still active and sucking up
			// battery juice even though we can't see any video.
			_video.clear();
			this.removeChild( _video );
			_video = null;
			_camera = null;
			
			// Just being a good citizen and cleaning up after onesself. :-)
			_bitmapData.dispose();
			_bitmapData = null;
			System.gc();
		}
		
		public function decodeSnapshot():void {
			// STEP 1: Get the BitmapData from the video.
			
			_bitmapData = new BitmapData( 400, 400 );
			// Get the BitmapData from the _video for processing.
			_bitmapData.draw( _video );
			
			// STEP 2: Use the zxing library to convert the BitmapData 
			// into a BinaryBitmap that it needs to work with.
			
			// Use the zxing library to convert the _bitmapData to a BufferedImageLuminanceSource.
			var bufferedImageLum : BufferedImageLuminanceSource = new BufferedImageLuminanceSource( _bitmapData );
			var binaryBmp : BinaryBitmap = new BinaryBitmap( new GlobalHistogramBinarizer( bufferedImageLum ) );
			
			// STEP 3: Create a HashTable of the BareCodeFormat to use.
			// Seems sort of an odd way to do it but what do I know? 
			var hashTable : HashTable = new HashTable();
			hashTable.Add( DecodeHintType.POSSIBLE_FORMATS, BarcodeFormat.QR_CODE );
			
			try {
				// STEP 4: DECODE
				var result : Result = _qrCodeReader.decode( binaryBmp, hashTable );
			} catch (event:Error) { 
				// catch error here
			}
			
			// STEP 5: We're not using the camera any longer so close it down.
			//closeCamera();
			
			if ( result == null ) {
				//this.currentState = 'error';
			} else {
				// STEP 6: Analyze the result.
				//this.currentState = 'result';
				
				var parsedResult : ParsedResult = ResultParser.parseResult( result );
				_qrCodeData = parsedResult.getDisplayResult();
			}
		}
	}

}