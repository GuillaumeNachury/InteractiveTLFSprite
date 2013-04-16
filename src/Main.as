package
{
	import feathers.controls.ScrollContainer;
	import feathers.controls.Scroller;
	
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.OverflowPolicy;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class Main extends Sprite
	{
		private var iTLFs:InteractiveTLFSprite;
		private var iTLFs2:InteractiveTLFSprite;
		private var sc:ScrollContainer;
		
		public function Main()
		{
			super();
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			
		}
		
		private function addedToStageHandler(e:Event):void
		{
			iTLFs = InteractiveTLFSprite.fromHTML("<font size=28 color=0x360112><b>InteractiveTLFSprite</b> </font><br>links active - no option<br> <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eget libero vel elit commodo posuere. Suspendisse bibendum, urna sit <a href='http://google.com'>amet</a> tempor cursus, purus dui pharetra sem, id congue turpis velit quis arcu. Donec vestibulum eros id risus auctor non mattis elit gravida. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nam augue nulla, porta vel lobortis in, tristique at arcu. Nam euismod congue libero, iaculis aliquam mauris aliquet quis. Etiam ornare sodales adipiscing. <a href='innerURL'>Duis cursus</a> malesuada mi ut facilisis.Nulla id lacus vitae nunc bibendum posuere. Nam venenatis ullamcorper risus nec rutrum. In hac <a href='innerURL'>habitasse</a> platea dictumst. Fusce venenatis nisi a mauris elementum quis pellentesque lorem congue."
			,null, 400);			
			iTLFs.x = 10;
			iTLFs.y = 10;
			iTLFs.addEventListener(TouchEvent.TOUCH, onTxtTouch);
			iTLFs.addEventListener("link_touched", onLinkTouched);
			addChild(iTLFs);
			
			sc = new ScrollContainer();
			sc.x = 10;
			sc.y = 300;
			sc.scrollerProperties.horizontalScrollPolicy = Scroller.SCROLL_POLICY_OFF;
			sc.scrollerProperties.verticalScrollPolicy = Scroller.SCROLL_POLICY_ON;
			sc.width = 410;
			sc.height = 200;
			
			iTLFs2 = InteractiveTLFSprite.fromHTML("<font size=28 color=0x360112><b>InteractiveTLFSprite</b> </font><br>links active + options : <li>inside a Feather ScrollContainer</li><li>showBoundaries</li><li>oversizeClickArea</li><br> <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam eget libero vel elit commodo posuere. Suspendisse bibendum, urna sit <a href='http://google.com'>amet</a> tempor cursus, purus dui pharetra sem, id congue turpis velit quis arcu. Donec vestibulum eros id risus auctor non mattis elit gravida. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nam augue nulla, porta vel lobortis in, tristique at arcu. Nam euismod congue libero, iaculis aliquam mauris aliquet quis. Etiam ornare sodales adipiscing. <a href='innerURL'>Duis cursus</a> malesuada mi ut facilisis.Nulla id lacus vitae nunc bibendum posuere. Nam venenatis ullamcorper risus nec rutrum. In hac <a href='innerURL'>habitasse</a> platea dictumst. Fusce venenatis nisi a mauris elementum quis pellentesque lorem congue.rcu. Nam euismod congue libero, iaculis aliquam mauris aliquet quis. Etiam ornare sodales adipiscing. <a href='innerURL'>Duis cursus</a> malesuada mi ut facilisis.Nulla id lacus vitae nunc bibendum posuere. Nam venenatis ullamcorper risus nec rutrum. In hac <a href='innerURL'>habitasse</a> platea dictumst. Fusce venenatis nisi a mauris elementum quis pellentesque lorem congue."
				,null, 400);			
			
			iTLFs2.showBoundaries = true;
			iTLFs2.oversizeClickArea = true;
			iTLFs2.overSizeInPx = 10;
			iTLFs2.addEventListener(TouchEvent.TOUCH, onTxtInSCTouch);
			iTLFs2.addEventListener("link_touched", onLinkTouched);
			iTLFs2.flatten();
			sc.addChild(iTLFs2);
			
			addChild(sc);
		}
		
		/* *************************
		* Hit test
		*************************** */
		private function callHitTest(target:InteractiveTLFSprite, hitX:Number, hitY:Number):void{
			target.hitLinkDetection(hitX, hitY);			
		}
		
		/* **************************
		*  Event Handlers
		****************************/
		private function onTxtTouch(te:TouchEvent):void
		{
			var txt:InteractiveTLFSprite = te.currentTarget as InteractiveTLFSprite;
			var touches:Vector.<Touch> = te.touches;
			if(touches[0].phase == TouchPhase.BEGAN){
				callHitTest(txt,touches[0].globalX-txt.x,touches[0].globalY-txt.y);
			}
		}
		
		private function onTxtInSCTouch(te:TouchEvent):void
		{
			var txt:InteractiveTLFSprite = te.currentTarget as InteractiveTLFSprite;
			var touches:Vector.<Touch> = te.touches;
			if(touches[0].phase == TouchPhase.BEGAN){
				callHitTest(txt,touches[0].globalX-sc.x+sc.horizontalScrollPosition,touches[0].globalY-sc.y+sc.verticalScrollPosition);
			}
		}
		
		private function onLinkTouched(e:Event):void
		{
			var le:LinkElement = e.data as LinkElement;
			trace("Clicked on "+le.getText()+" ==> link :"+le.href);
		}
	}
}