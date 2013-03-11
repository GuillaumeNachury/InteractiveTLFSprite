package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	import starling.core.Starling;
	[SWF(width="960",height="640",frameRate="60",backgroundColor="#bdc3c7")]
	public class TestInteractiveTLF extends Sprite
	{
		
		private var _starling:Starling;
		public function TestInteractiveTLF()
		{
			super();
			
			// support autoOrients
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			this.loaderInfo.addEventListener(Event.COMPLETE, onLoadingComplete);
		}
		
		protected function onLoadingComplete(event:Event):void
		{
			
			_starling = new Starling(Main, this.stage);
			_starling.start();
		}
	}
}