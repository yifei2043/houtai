// ActionScript file
//package core.scene
package 
{
	import alternativa.engine3d.controllers.*;
	import alternativa.engine3d.core.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.*;
	
	public class OrbitCameraController extends SimpleObjectController
	{
		private var _easingSeparator:Number = 10;
		public var maxDistance:Number = 20000;
		public var maxLatitude:Number = 89.9;
		public var minDistance:Number = 10;
		public var minLatitude:Number = -89.9;
		private var _mouseSensitivityX:Number = -1;
		private var _mouseSensitivityY:Number = 1;
		public var multiplyValue:Number = 10;
		private var _needsRendering:Boolean;
		private var _pitchSpeed:Number = 5;
		public var useHandCursor:Boolean = true;
		private var _yawSpeed:Number = 5;
		private var _angleLatitude:Number = 0;
		private var _angleLongitude:Number = 0;
		private var _distanceSpeed:Number = 5;
		private var _keyEventSource:InteractiveObject;
		private var _lastLatitude:Number = 0;
		private var _lastLength:Number = 700;
		private var _lastLongitude:Number;
		private var _lastLookAtX:Number;
		private var _lastLookAtY:Number;
		private var _lastLookAtZ:Number;
		private var _length:Number = 700;
		private var _lookAtX:Number = 0;
		private var _lookAtY:Number = 0;
		private var _lookAtZ:Number = 0;
		private var _mouseDownEventSource:InteractiveObject;
		private var _mouseMove:Boolean;
		private var _mouseUpEventSource:InteractiveObject;
		private var _mouseX:Number;
		private var _mouseY:Number;
		private var _oldLatitude:Number;
		private var _oldLongitude:Number;
		private var _pitchDown:Boolean;
		private var _pitchUp:Boolean;
		private var _taregetDistanceValue:Number = 0;
		private var _taregetPitchValue:Number = 0;
		private var _taregetYawValue:Number = 0;
		private var _target:Object3D;
		private var _yawLeft:Boolean;
		private var _yawRight:Boolean;
		private var _zoomIn:Boolean;
		private var _zoomOut:Boolean;
		public static const ACTION_FORWARD:String = "actionForward";
		public static const ACTION_BACKWARD:String = "actionBackward";
		private static const ROUND_VALUE:Number = 0.1;
		public function OrbitCameraController(pWnd:iHouse3DView, param1:Object3D, param2:InteractiveObject, param3:InteractiveObject, param4:InteractiveObject, param5:Boolean = true, param6:Boolean = true)
		{
			this._lastLongitude = this._angleLongitude;
			this._lastLookAtX = this._lookAtX;
			this._lastLookAtY = this._lookAtY;
			this._lastLookAtZ = this._lookAtZ;
			this._target = param1;
			super(pWnd,param2, param1, 0, 3, mouseSensitivity);
			super.mouseSensitivity = 0;
			super.unbindAll();
			super.accelerate(true);
			this._mouseDownEventSource = param3;
			this._mouseUpEventSource = param3;
			this._keyEventSource = param4;
			this._mouseDownEventSource.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
			if (param6)
			{
				this._mouseDownEventSource.addEventListener(MouseEvent.MOUSE_WHEEL, this.mouseWheelHandler);
			}
			if (param5)
			{
				this._keyEventSource.addEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
				this._keyEventSource.addEventListener(KeyboardEvent.KEY_UP, this.keyUpHandler);
			}
			return;
		}// end function
		
		public function set easingSeparator(param1:uint) : void
		{
			if (param1)
			{
				this._easingSeparator = param1;
			}
			else
			{
				this._easingSeparator = 1;
			}
			return;
		}// end function
		
		public function set mouseSensitivityX(param1:Number) : void
		{
			this._mouseSensitivityX = param1;
			return;
		}// end function
		
		public function set mouseSensitivityY(param1:Number) : void
		{
			this._mouseSensitivityY = param1;
			return;
		}// end function
		
		public function get needsRendering() : Boolean
		{
			return this._needsRendering;
		}// end function
		
		public function set pitchSpeed(param1:Number) : void
		{
			this._pitchSpeed = param1;
			return;
		}// end function
		
		public function set yawSpeed(param1:Number) : void
		{
			this._yawSpeed = param1 * Math.PI / 180;
			return;
		}// end function
		
		public function set zoomSpeed(param1:Number) : void
		{
			this._distanceSpeed = param1;
			return;
		}// end function
		
		public function pitchUp() : void
		{
			this._taregetPitchValue = this._pitchSpeed * this.multiplyValue;
			return;
		}// end function
		
		public function pitchDown() : void
		{
			this._taregetPitchValue = this._pitchSpeed * (-this.multiplyValue);
			return;
		}// end function
		
		public function yawLeft() : void
		{
			this._taregetYawValue = this._yawSpeed * this.multiplyValue;
			return;
		}// end function
		
		public function yawRight() : void
		{
			this._taregetYawValue = this._yawSpeed * (-this.multiplyValue);
			return;
		}// end function
		
		public function moveForeward() : void
		{
			this._taregetDistanceValue = this._taregetDistanceValue - this._distanceSpeed * this.multiplyValue;
			return;
		}// end function
		
		public function moveBackward() : void
		{
			this._taregetDistanceValue = this._taregetDistanceValue + this._distanceSpeed * this.multiplyValue;
			return;
		}// end function
		
		override public function bindKey(param1:uint, param2:String) : void
		{
			switch(param2)
			{
				case ACTION_FORWARD:
				{
					keyBindings[param1] = this.toggleForward;
					break;
				}
				case ACTION_BACKWARD:
				{
					keyBindings[param1] = this.toggleBackward;
					break;
				}
				case ACTION_YAW_LEFT:
				{
					keyBindings[param1] = this.toggleYawLeft;
					break;
				}
				case ACTION_YAW_RIGHT:
				{
					keyBindings[param1] = this.toggleYawRight;
					break;
				}
				case ACTION_PITCH_DOWN:
				{
					keyBindings[param1] = this.togglePitchDown;
					break;
				}
				case ACTION_PITCH_UP:
				{
					keyBindings[param1] = this.togglePitchUp;
					break;
				}
				default:
				{
					break;
				}
			}
			return;
		}// end function
		
		public function togglePitchDown(param1:Boolean) : void
		{
			this._pitchDown = param1;
			return;
		}// end function
		
		public function togglePitchUp(param1:Boolean) : void
		{
			this._pitchUp = param1;
			return;
		}// end function
		
		public function toggleYawLeft(param1:Boolean) : void
		{
			this._yawLeft = param1;
			return;
		}// end function
		
		public function toggleYawRight(param1:Boolean) : void
		{
			this._yawRight = param1;
			return;
		}// end function
		
		public function toggleForward(param1:Boolean) : void
		{
			this._zoomIn = param1;
			return;
		}// end function
		
		public function toggleBackward(param1:Boolean) : void
		{
			this._zoomOut = param1;
			return;
		}// end function
		
		override public function update() : void
		{
			var _loc_1:* = Math.PI / 180;
			var _loc_2:* = this._angleLatitude;
			var _loc_3:* = this._angleLongitude;
			var _loc_4:* = this._lastLength;
			if (this._zoomIn)
			{
				this._lastLength = this._lastLength - this._distanceSpeed;
			}
			else if (this._zoomOut)
			{
				this._lastLength = this._lastLength + this._distanceSpeed;
			}
			if (this._taregetDistanceValue != 0)
			{
				this._lastLength = this._lastLength + this._taregetDistanceValue;
				this._taregetDistanceValue = 0;
			}
			if (this._lastLength < this.minDistance)
			{
				this._lastLength = this.minDistance;
			}
			else if (this._lastLength > this.maxDistance)
			{
				this._lastLength = this.maxDistance;
			}
			if (this._lastLength - this._length)
			{
				this._length = this._length + (this._lastLength - this._length) / this._easingSeparator;
			}
			if (Math.abs(this._lastLength - this._length) < ROUND_VALUE)
			{
				this._length = this._lastLength;
			}
			if (this._mouseMove)
			{
				this._lastLongitude = this._oldLongitude + (this._mouseDownEventSource.mouseX - this._mouseX) * this._mouseSensitivityX;
			}
			else if (this._yawLeft)
			{
				this._lastLongitude = this._lastLongitude + this._yawSpeed;
			}
			else if (this._yawRight)
			{
				this._lastLongitude = this._lastLongitude - this._yawSpeed;
			}
			if (this._taregetYawValue)
			{
				this._lastLongitude = this._lastLongitude + this._taregetYawValue;
				this._taregetYawValue = 0;
			}
			if (this._lastLongitude - this._angleLongitude)
			{
				this._angleLongitude = this._angleLongitude + (this._lastLongitude - this._angleLongitude) / this._easingSeparator;
			}
			if (Math.abs(this._lastLatitude - this._angleLatitude) < ROUND_VALUE)
			{
				this._angleLatitude = this._lastLatitude;
			}
			if (this._mouseMove)
			{
				this._lastLatitude = this._oldLatitude + (this._mouseDownEventSource.mouseY - this._mouseY) * this._mouseSensitivityY;
			}
			else if (this._pitchDown)
			{
				this._lastLatitude = this._lastLatitude - this._pitchSpeed;
			}
			else if (this._pitchUp)
			{
				this._lastLatitude = this._lastLatitude + this._pitchSpeed;
			}
			if (this._taregetPitchValue)
			{
				this._lastLatitude = this._lastLatitude + this._taregetPitchValue;
				this._taregetPitchValue = 0;
			}
			this._lastLatitude = Math.max(this.minLatitude, Math.min(this._lastLatitude, this.maxLatitude));
			if (this._lastLatitude - this._angleLatitude)
			{
				this._angleLatitude = this._angleLatitude + (this._lastLatitude - this._angleLatitude) / this._easingSeparator;
			}
			if (Math.abs(this._lastLongitude - this._angleLongitude) < ROUND_VALUE)
			{
				this._angleLongitude = this._lastLongitude;
			}
			var _loc_5:* = this.translateGeoCoords(this._angleLatitude, this._angleLongitude, this._length);
			this._target.x = _loc_5.x;
			this._target.y = _loc_5.y;
			this._target.z = _loc_5.z;
			if (this._lastLookAtX - this._lookAtX)
			{
				this._lookAtX = this._lookAtX + (this._lastLookAtX - this._lookAtX) / this._easingSeparator;
			}
			if (this._lastLookAtY - this._lookAtY)
			{
				this._lookAtY = this._lookAtY + (this._lastLookAtY - this._lookAtY) / this._easingSeparator;
			}
			if (this._lastLookAtZ - this._lookAtZ)
			{
				this._lookAtZ = this._lookAtZ + (this._lastLookAtZ - this._lookAtZ) / this._easingSeparator;
			}
			updateObjectTransform();
			lookAtXYZ(this._lookAtX, this._lookAtY, this._lookAtZ);
			this._needsRendering = _loc_2 != this._angleLatitude || _loc_3 != this._angleLongitude || _loc_4 != this._length;
			return;
		}// end function
		
		override public function startMouseLook() : void
		{
			return;
		}// end function
		
		override public function stopMouseLook() : void
		{
			return;
		}// end function
		
		public function lookAtPosition(param1:Number, param2:Number, param3:Number, param4:Boolean = false) : void
		{
			if (param4)
			{
				this._lookAtX = param1;
				this._lookAtY = param2;
				this._lookAtZ = param3;
			}
			this._lastLookAtX = param1;
			this._lastLookAtY = param2;
			this._lastLookAtZ = param3;
			return;
		}// end function
		
		public function setLongitude(param1:Number, param2:Boolean = false) : void
		{
			if (param2)
			{
				this._angleLongitude = param1;
			}
			this._lastLongitude = param1;
			return;
		}// end function
		
		public function setLatitude(param1:Number, param2:Boolean = false) : void
		{
			param1 = Math.max(this.minLatitude, Math.min(this.maxLatitude, param1));
			if (param2)
			{
				this._angleLatitude = param1;
			}
			this._lastLatitude = param1;
			return;
		}// end function
		
		public function setDistance(param1:Number, param2:Boolean = false) : void
		{
			if (param2)
			{
				this._length = param1;
			}
			this._lastLength = param1;
			return;
		}// end function
		
		public function dispose() : void
		{
			if (this._mouseDownEventSource)
			{
				this._mouseDownEventSource.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler);
			}
			if (this._mouseDownEventSource)
			{
				this._mouseDownEventSource.removeEventListener(MouseEvent.MOUSE_WHEEL, this.mouseWheelHandler);
			}
			if (this._keyEventSource)
			{
				this._keyEventSource.removeEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
				this._keyEventSource.removeEventListener(KeyboardEvent.KEY_UP, this.keyUpHandler);
			}
			this._easingSeparator = 0;
			this.maxDistance = 0;
			this.minDistance = 0;
			this._mouseSensitivityX = 0;
			this._mouseSensitivityY = 0;
			this.multiplyValue = 0;
			this._needsRendering = false;
			this._pitchSpeed = 0;
			this.useHandCursor = false;
			this._yawSpeed = 0;
			this._angleLatitude = 0;
			this._angleLongitude = 0;
			this._distanceSpeed = 0;
			this._keyEventSource = null;
			this._lastLatitude = 0;
			this._lastLength = 0;
			this._lastLongitude = 0;
			this._lastLookAtX = 0;
			this._lastLookAtY = 0;
			this._lastLookAtZ = 0;
			this._length = 0;
			this._lookAtX = 0;
			this._lookAtY = 0;
			this._lookAtZ = 0;
			this._mouseDownEventSource = null;
			this._mouseMove = false;
			this._mouseUpEventSource = null;
			this._mouseX = 0;
			this._mouseY = 0;
			this._oldLatitude = 0;
			this._oldLongitude = 0;
			this._pitchDown = false;
			this._pitchUp = false;
			this._taregetDistanceValue = 0;
			this._taregetPitchValue = 0;
			this._taregetYawValue = 0;
			this._target = null;
			this._yawLeft = false;
			this._yawRight = false;
			this._zoomIn = false;
			this._zoomOut = false;
			return;
		}// end function
		
		public function bindBasicKey() : void
		{
			this.bindKey(Keyboard.LEFT, SimpleObjectController.ACTION_YAW_LEFT);
			this.bindKey(Keyboard.RIGHT, SimpleObjectController.ACTION_YAW_RIGHT);
			this.bindKey(Keyboard.DOWN, SimpleObjectController.ACTION_PITCH_DOWN);
			this.bindKey(Keyboard.UP, SimpleObjectController.ACTION_PITCH_UP);
			this.bindKey(Keyboard.W, OrbitCameraController.ACTION_FORWARD);
			this.bindKey(Keyboard.S, OrbitCameraController.ACTION_BACKWARD);
			return;
		}// end function
		
		protected function mouseDownHandler(event:Event) : void
		{
			this._oldLongitude = this._lastLongitude;
			this._oldLatitude = this._lastLatitude;
			this._mouseX = this._mouseDownEventSource.mouseX;
			this._mouseY = this._mouseDownEventSource.mouseY;
			this._mouseMove = true;
		//	if (this.useHandCursor)
		//	{
		//		Mouse.cursor = MouseCursor.HAND;
		//	}
			this._mouseUpEventSource.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
			return;
		}// end function
		
		protected function mouseUpHandler(event:Event) : void
		{
		//	if (this.useHandCursor)
		//	{
		//		Mouse.cursor = MouseCursor.AUTO;
		//	}
			this._mouseMove = false;
			this._mouseUpEventSource.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
			return;
		}// end function
		
		private function keyDownHandler(event:KeyboardEvent) : void
		{
			var _loc_2:String = null;
			for (_loc_2 in keyBindings)
			{
				
				if (String(event.keyCode) == _loc_2)
				{
					var _loc_5:* = keyBindings;
					_loc_5.keyBindings[_loc_2](true);
				}
			}
			return;
		}// end function
		
		private function keyUpHandler(event:KeyboardEvent = null) : void
		{
			var _loc_2:String = null;
			for (_loc_2 in keyBindings)
			{
				
				var _loc_5:* = keyBindings;
				_loc_5.keyBindings[_loc_2](false);
			}
			return;
		}// end function
		
		private function mouseWheelHandler(event:MouseEvent) : void
		{
			this._lastLength = this._lastLength - event.delta * 15;
			if (this._lastLength < this.minDistance)
			{
				this._lastLength = this.minDistance;
			}
			else if (this._lastLength > this.maxDistance)
			{
				this._lastLength = this.maxDistance;
			}
			return;
		}// end function
		
		private function translateGeoCoords(param1:Number, param2:Number, param3:Number) : Vector3D
		{
			var _loc_4:Number = 90;
			var _loc_5:Number = -90;
			param1 = Math.PI * param1 / 180;
			param2 = Math.PI * param2 / 180;
			param1 = param1 - _loc_4 * (Math.PI / 180);
			param2 = param2 - _loc_5 * (Math.PI / 180);
			var _loc_6:* = param3 * Math.sin(param1) * Math.cos(param2);
			var _loc_7:* = param3 * Math.cos(param1);
			var _loc_8:* = param3 * Math.sin(param1) * Math.sin(param2);
			return new Vector3D(_loc_6, _loc_8, _loc_7);
		}// end function
		
	}
}

