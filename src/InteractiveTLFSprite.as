/**
 * Based on source available on : http://wiki.starling-framework.org/extensions/tlfsprite
 * 
 * Simple modification of the tlfsprite in order to get the <a href="...">...</a> touchable
 * @author: Guillaume Nachury (guillaume.nachury@gmail.com)
 * 
 * dispatch a Starling event name 'link_touched' that contains le linked element touched as data
 * */

// =================================================================================================
//
//  based on starling.text.TextField
//  modified to use text layout framework engine for rendering text
//
// =================================================================================================

package {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.engine.FontLookup;
	import flash.text.engine.TextLine;
	
	import flashx.textLayout.compose.IFlowComposer;
	import flashx.textLayout.compose.TextFlowLine;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.LinkElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.factory.TextFlowTextLineFactory;
	import flashx.textLayout.factory.TruncationOptions;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	
	[Event(name="link_touched",type="starling.events.Event")]
	
	/** A TLFSprite displays text, using standard open type or true type fonts.
	 * 
	 * Rendering is done with a backing of the text layout framework engine as opposed
	 * to the classic flash.text.TextField as the standard starling.text.TextField employs.
	 * 
	 * If relying on embedded font use ensure TextLayoutFormat.fontLookup is set to FontLookup.EMBEDDED_CFF,
	 * this defaults to FontLookup.DEVICE, expecting device fonts.
	 * 
	 * Additionally, note that TLF expects embedded fonts with CFF, embedAsCFF="true" unlike
	 * classic TextField which uses embedded fonts with CFF disabled, embedAsCFF="false"
	 * 
	 * Download and find out more about the latest Text Layout Framework at
	 * <a href="http://sourceforge.net/adobe/tlf/home/Home/">Text Layout Framework</a>
	 */
	public class InteractiveTLFSprite extends starling.display.Sprite
	{
		
		private var mTextFlow:TextFlow;
		private var mFormat:TextLayoutFormat;
		
		private var mRequiresRedraw:Boolean;
		private var mType:String;
		private var mBorder:DisplayObjectContainer;
		
		private var mImage:Image;
		private var mSmoothing:String;
		
		private var mTruncationOptions:TruncationOptions;
		private var mCompositionBounds:Rectangle;
		
		// TLF rendering objects
		private static var sTextLineFactory:TextFlowTextLineFactory;
		private static var sTextLinesOrShapes:Vector.<flash.display.DisplayObject>;
		
		private static var sHelperMatrix:Matrix  = new Matrix();
		
		//Link management
		private var savedTLF:TextFlow;
		private var _linkMap:Array;
		public var showBoundaries:Boolean = false;
		public var oversizeClickArea:Boolean = false;
		public var overSizeInPx:int = 10;
		private var txtBounds:Rectangle;
		private static var _sTextLineFactory:TextFlowTextLineFactory;
		private var _savedTLF:TextFlow;
		
		
		/** Creates a TLFSprite from plain text. 
		 *  Optionally providing default formatting with TextLayoutFormat and composition
		 * width and height to limit active drawing area for rendering text 
		 * */
		public static function fromPlainText(text:String, format:TextLayoutFormat = null, 
											 compositionWidth:Number = 2048, compositionHeight:Number = 2048):InteractiveTLFSprite
		{
			return fromFormat(text, TextConverter.PLAIN_TEXT_FORMAT, format, compositionWidth, compositionHeight);
		}
		
		/** Creates a TLFSprite from a string of HTML text, limited by the HTML tags the TLF engine supports.
		 *  See the Text Layout Framework documentation for supported tags.
		 * 
		 *  Optionally providing default formatting with TextLayoutFormat and composition
		 * width and height to limit active drawing area for rendering text 
		 * */
		public static function fromHTML(htmlString:String, format:TextLayoutFormat = null, 
										compositionWidth:Number = 2048, compositionHeight:Number = 2048):InteractiveTLFSprite
		{
			return fromFormat(htmlString, TextConverter.TEXT_FIELD_HTML_FORMAT, format, compositionWidth, compositionHeight);
		}
		
		/** Creates a TLFSprite from a string of text layout XML text, limited by the XML tags the TLF engine supports.
		 *  See the Text Layout Framework documentation for supported tags.
		 * 
		 *  Optionally providing default formatting with TextLayoutFormat and composition
		 * width and height to limit active drawing area for rendering text 
		 * */
		public static function fromTextLayout(layoutXMLString:String, format:TextLayoutFormat = null, 
											  compositionWidth:Number = 2048, compositionHeight:Number = 2048):InteractiveTLFSprite
		{
			return fromFormat(layoutXMLString, TextConverter.TEXT_LAYOUT_FORMAT, format, compositionWidth, compositionHeight);
		}
		
		
		
		private static function fromFormat(text:String, type:String, format:TextLayoutFormat = null, 
										   compositionWidth:Number = 2048, compositionHeight:Number = 2048):InteractiveTLFSprite
		{
			
			var tlfSprite:InteractiveTLFSprite = null;
			var textFlow:TextFlow = TextConverter.importToFlow(text ? text : "", type);
			

			
			if (textFlow)
				tlfSprite = new InteractiveTLFSprite(textFlow, format, compositionWidth, compositionHeight, type);
			
			
			
			
			return tlfSprite;
		}
		
		/**
		 * Basic constructor that takes an already constructed TLF TextFlow with optional
		 * default format and composition limits
		 * 
		 * See the static helper methods for quickly instantiating a TLFSprite from
		 * a simple plain text unformatted string, HTML or TLF text layout markup.
		 * */
		public function InteractiveTLFSprite(textFlow:TextFlow, format:TextLayoutFormat = null, 
								  compositionWidth:Number = 2048, compositionHeight:Number = 2048, type:String="")
		{
			var links:Array = [];
			super();
			
			initTLF();
			
			mType = type;
			mTextFlow = textFlow;
			
			if(type == TextConverter.TEXT_FIELD_HTML_FORMAT){
				savedTLF = mTextFlow.deepCopy() as TextFlow;
				_savedTLF = mTextFlow.deepCopy() as TextFlow;
			}
			mTruncationOptions = new TruncationOptions();
			mCompositionBounds = new Rectangle( 0, 0, compositionWidth, compositionHeight);
			
			if (format) mFormat = format;
			else {
				mFormat = new TextLayoutFormat();
			}
			
			mSmoothing = TextureSmoothing.BILINEAR;
			addEventListener(Event.FLATTEN, onFlatten);
			
			mRequiresRedraw = true;
			
			
		}
		
		/** Disposes the underlying texture data. */
		public override function dispose():void
		{
			removeEventListener(Event.FLATTEN, onFlatten);
			if (mImage) mImage.texture.dispose();
			super.dispose();
		}
		
		private function onFlatten(event:Event):void
		{
			if (mRequiresRedraw) redrawContents();
		}
		
		/** @inheritDoc */
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			if (mRequiresRedraw) redrawContents();
			super.render(support, parentAlpha);
		}
		
		private function redrawContents():void
		{
			createRenderedContents();
			mRequiresRedraw = false;
		}
		
		private function createRenderedContents():void
		{
			var scale:Number  = Starling.contentScaleFactor;
			
			var bitmapData:BitmapData = createRenderedBitmap();
			if (!bitmapData) return;
			
			var texture:Texture = Texture.fromBitmapData(bitmapData, false, false, scale);
			
			if (mImage == null) 
			{
				mImage = new Image(texture);
				mImage.touchable = false;
				mImage.smoothing = mSmoothing;
				addChild(mImage);
			}
			else 
			{ 
				if (mImage.texture) mImage.texture.dispose();
				mImage.texture = texture; 
				mImage.readjustSize(); 
			}
			updateBorder();
			dispatchEvent(new Event("tlf_ready"));
			
		}
		
		private function findBounds():void{
			var scale:Number  = Starling.contentScaleFactor;
			
			
			
			_sTextLineFactory.compositionBounds = mCompositionBounds;
			_sTextLineFactory.truncationOptions = mTruncationOptions;
			
			// NOTE: so that we function similar to Starling's TextField that hides
			// the fontSize scaling of Starling.contentScaleFactor internally,
			// we temporarily also scale up the format's fontSize setting only 
			// to then reset it when finished
			if (scale != 1.0) {
				var origFontSize:* = mFormat.fontSize;
				mFormat.fontSize = Math.max(1, Math.min(720, 
					(origFontSize == undefined ? 12 : origFontSize as Number)*scale));
			}
			
			savedTLF.hostFormat = mFormat;
			_sTextLineFactory.createTextLines( inop, _savedTLF);
			txtBounds = sTextLineFactory.getContentBounds();
		}
		
		private function inop(lineOrShape:flash.display.DisplayObject ):void{
			
		}
		
		/** public in case one wants to use this class as a pipeline for
		 * creating bitmap data outside the typical end use of a sprite's texture
		 * */
		public function createRenderedBitmap():BitmapData 
		{
			if (!mTextFlow) return null;
			
			var scale:Number  = Starling.contentScaleFactor;
			
			// clear out any existing text lines or shapes
			sTextLinesOrShapes.length = 0;
			
			sTextLineFactory.compositionBounds = mCompositionBounds;
			sTextLineFactory.truncationOptions = mTruncationOptions;
			
			// NOTE: so that we function similar to Starling's TextField that hides
			// the fontSize scaling of Starling.contentScaleFactor internally,
			// we temporarily also scale up the format's fontSize setting only 
			// to then reset it when finished
			if (scale != 1.0) {
				var origFontSize:* = mFormat.fontSize;
				mFormat.fontSize = Math.max(1, Math.min(720, 
					(origFontSize == undefined ? 12 : origFontSize as Number)*scale));
			}
			
			mTextFlow.hostFormat = mFormat;
			sTextLineFactory.createTextLines( generatedTextLineOrShape, mTextFlow);
			
			// after lines are generated we can ask the factory for the content
			// bounds that encompasses the current line renderings
			var contentBounds:Rectangle = sTextLineFactory.getContentBounds();
			
			// Reset modified fontSize value
			if (scale != 1.0) mFormat.fontSize = origFontSize;
			
			var textWidth:Number  = Math.min(2048, contentBounds.width*scale);
			var textHeight:Number = Math.min(2048, contentBounds.height*scale);
			
			textWidth = textWidth ==0 ?compositionWidth: textWidth;
			textHeight = textHeight ==0 ?compositionHeight: textHeight;
			
			
			var bitmapData:BitmapData = new BitmapData(textWidth, textHeight, true, 0x0);
			
			// draw each text line or shape into bitmap
			var lineOrShape:flash.display.DisplayObject;
			for (var i:int = 0; i < sTextLinesOrShapes.length; ++i) {
				lineOrShape = sTextLinesOrShapes[i];
				sHelperMatrix.setTo(scale, 0, 0, scale, 
					(lineOrShape.x - contentBounds.x)*scale, (lineOrShape.y - contentBounds.y)*scale);
				bitmapData.draw(lineOrShape, sHelperMatrix);
				
			}
			//let's create a map of all the clickable areas
			if(mType == TextConverter.TEXT_FIELD_HTML_FORMAT){
				createLinkMap(textWidth, textHeight);
			}
			
			// finished need for generated lines or shapes
			sTextLinesOrShapes.length = 0;
			
					
			return bitmapData;
		}
		
		
		
		/**
		 * 
		 * 
		 */
		private function createLinkMap(textW:Number, textH:Number):void{
			var ctrlr:ContainerController = new ContainerController(new flash.display.Sprite(), textW,textH);	
			savedTLF.flowComposer.addController(ctrlr);
			savedTLF.flowComposer.updateAllControllers();
			
			var composer:IFlowComposer = savedTLF.flowComposer;
			composer.compose();
			var links:Array = [];
			
			
			links = savedTLF.getElementsByTypeName("a");	
			_linkMap = new Array();
			
			for each (var le:LinkElement in links){				
				_linkMap=_linkMap.concat(createClickableZone(le, composer));
			}
			
			for (var i:int = 0; i < _linkMap.length; i++) 
			{
				var rec:Rectangle = _linkMap[i].area as Rectangle;
				var qd:Quad = new Quad(rec.width, rec.height, 0xaa0000);
				qd.x = rec.x;
				qd.y = rec.y;
				qd.alpha = showBoundaries?0.3:0;
				addChild(qd);
			}
			
		}
		
		
		private function createClickableZone(le:LinkElement, composer:IFlowComposer):Array{
			var area:Array = [];
			var absStart:int = le.getAbsoluteStart();
			var textFlowLine:TextFlowLine= composer.findLineAtPosition(absStart);
			var textLine:TextLine = textFlowLine.getTextLine(true);
			
			var lineLength:int = textFlowLine.textLength;
			var rectBoundary:Rectangle = textLine.getAtomBounds(textLine.getAtomIndexAtCharIndex(le.parentRelativeStart));
			rectBoundary.y = textFlowLine.y;
			if(oversizeClickArea){
				rectBoundary.y -= overSizeInPx;
				rectBoundary.height +=(overSizeInPx*2);
				rectBoundary.x -=overSizeInPx;
			}
			
			var linkLength:int = le.getText().length;
			
			var ptr:int = textLine.getAtomIndexAtCharIndex(le.parentRelativeStart);
			ptr++;
			absStart++;
			for (var i:int = 1; i < linkLength; i++) //start a idx=1 because we already got the 1st bound
			{
				if(ptr>lineLength){
					if(oversizeClickArea){
						rectBoundary.width +=(overSizeInPx*2);
					}
					area.push({linkElem:le,area:rectBoundary});
					textFlowLine = composer.findLineAtPosition(absStart);
					lineLength = textFlowLine.textLength;
					ptr=0;
					rectBoundary = textLine.getAtomBounds(ptr);
				}
				else{
					var newCharBounds:Rectangle = textLine.getAtomBounds(ptr);
					rectBoundary = new Rectangle(rectBoundary.x, rectBoundary.y, rectBoundary.width+newCharBounds.width, rectBoundary.height);
				}
				ptr++;
				absStart++;
			}
			if(oversizeClickArea){
				rectBoundary.width +=(overSizeInPx*2);
			}
			area.push({linkElem:le,area:rectBoundary});
			
			
			return area;
		}		
		
		public function hitLinkDetection(touchX:Number, touchY:Number):void{
			for each (var o:Object in _linkMap) 
			{
				var rect:Rectangle = o.area;
				if(rect.contains(touchX, touchY)){
					dispatchEvent(new Event("link_touched",true, o.linkElem));
					return;
				}
			}
			
		}

		
		private function displayBoundaries(rect:Rectangle):void{
			var quad:Quad = new Quad(rect.width, rect.height, 0xaa56321);
			quad.x = rect.top;
			quad.y = rect.left;
			addChild(quad);
		}
		
		private function findLinkElement(group:FlowGroupElement, arr:Array):Array {
			var childGroups:Array = [];
			for (var i:int = 0; i < group.numChildren; i++) {
				var element:FlowElement = group.getChildAt(i);
				if (element is LinkElement) {
					arr.push(element as LinkElement);
				} else if (element is FlowGroupElement) {
					childGroups.push(element);
				}
			}
			for (i = 0; i < childGroups.length; i++) {
				var childGroup:FlowGroupElement = childGroups[i];
				findLinkElement(childGroup, arr);				
			}
			return arr;
		}
		
		private static function initTLF():void
		{
			if (sTextLineFactory == null) {	
				sTextLineFactory = new TextFlowTextLineFactory();
				_sTextLineFactory = new TextFlowTextLineFactory();
				sTextLinesOrShapes = new <flash.display.DisplayObject>[];
			}
		}
		
		/** generated TextLines or Shapes (from background colors etc..)
		 *  get added to a collected vector of results
		 * */
		private function generatedTextLineOrShape( lineOrShape:flash.display.DisplayObject ):void
		{
			sTextLinesOrShapes.push(lineOrShape);
		}
		
		private function updateBorder():void
		{
			if (mBorder == null || mImage == null) return;
			
			var width:Number  = mImage.width;
			var height:Number = mImage.height;
			
			var topLine:Quad    = mBorder.getChildAt(0) as Quad;
			var rightLine:Quad  = mBorder.getChildAt(1) as Quad;
			var bottomLine:Quad = mBorder.getChildAt(2) as Quad;
			var leftLine:Quad   = mBorder.getChildAt(3) as Quad;
			
			topLine.width    = width; topLine.height    = 1;
			bottomLine.width = width; bottomLine.height = 1;
			leftLine.width   = 1;     leftLine.height   = height;
			rightLine.width  = 1;     rightLine.height  = height;
			rightLine.x  = width  - 1;
			bottomLine.y = height - 1;
			topLine.color = rightLine.color = bottomLine.color = leftLine.color = mFormat.color;
		}
		
		/** @inheritDoc */
		public override function getBounds(targetSpace:starling.display.DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			if(mImage){
				return mImage.getBounds(targetSpace, resultRect);
			}
			else{
				return txtBounds;
			}
			
		}
		
		/** Calling set text makes the assumption that you now expect only
		 *  simple content with external formats and completely replace any
		 * previously set content, plain text, html or otherwise
		 * */
		public function set text(value:String):void
		{
			mTextFlow = TextConverter.importToFlow(value ? value : "", TextConverter.PLAIN_TEXT_FORMAT);
			mRequiresRedraw = true;
		}
		
		/** Calling set html makes the assumption that you now expect
		 *  HTML content and completely replace any
		 * previously set content, plain text, html or otherwise
		 * */
		public function set html(value:String):void
		{
			mTextFlow = TextConverter.importToFlow(value ? value : "", TextConverter.TEXT_FIELD_HTML_FORMAT);
			mRequiresRedraw = true;
		}
		
		/** Calling set textLayout makes the assumption that you now expect
		 *  Text layout markup content and completely replace any
		 * previously set content, plain text, html or otherwise
		 * */
		public function set textLayout(value:String):void
		{
			mTextFlow = TextConverter.importToFlow(value ? value : "", TextConverter.TEXT_LAYOUT_FORMAT);
			mRequiresRedraw = true;
		}
		
		public function get compositionWidth():Number {return mCompositionBounds.width;}
		public function set compositionWidth(value:Number):void
		{
			if (value != mCompositionBounds.width) {
				mCompositionBounds.width = value;
				mRequiresRedraw = true;
			}
		}
		
		public function get compositionHeight():Number {return mCompositionBounds.height;}
		public function set compositionHeight(value:Number):void
		{
			if (value != mCompositionBounds.height) {
				mCompositionBounds.height = value;
				mRequiresRedraw = true;
			}
		}
		
		public function get truncationOptions():TruncationOptions {return mTruncationOptions;}
		public function set truncationOptions(value:TruncationOptions):void 
		{
			mTruncationOptions = value;
			mRequiresRedraw = true;
		}
		
		/** Draws a border around the edges of the text field. Useful for visual debugging. 
		 *  @default false */
		public function get border():Boolean { return mBorder != null; }
		public function set border(value:Boolean):void
		{
			if (value && mBorder == null)
			{                
				mBorder = new starling.display.Sprite();
				addChild(mBorder);
				
				for (var i:int=0; i<4; ++i)
					mBorder.addChild(new Quad(1.0, 1.0));
				
				updateBorder();
			}
			else if (!value && mBorder != null)
			{
				mBorder.removeFromParent(true);
				mBorder = null;
			}
		}
		
		/** The smoothing filter that is used for the image texture. 
		 *   @default bilinear
		 *   @see starling.textures.TextureSmoothing */ 
		public function get smoothing():String { return mSmoothing; }
		public function set smoothing(value:String):void 
		{
			if (TextureSmoothing.isValid(value)) {
				mSmoothing = value;
				if (mImage) mImage.smoothing = mSmoothing;
			}
			else
				throw new ArgumentError("Invalid smoothing mode: " + value);
		}
		
		/** Returns the value of the style specified by the <code>styleProp</code> parameter, which specifies
		 * the style name from the text's TextLayoutFormat.
		 *
		 * @param styleProp The name of the style whose value is to be retrieved.
		 *
		 * @return The value of the specified style. The type varies depending on the type of the style being
		 * accessed. Returns <code>undefined</code> if the style is not set.
		 */
		public function getStyle(styleProp:String):*
		{
			return mFormat.getStyle(styleProp);
		}
		
		/** Sets the style specified by the <code>styleProp</code> parameter to the value specified by the
		 * <code>newValue</code> parameter. 
		 *
		 * Contents are redrawn with the updated property changes on the next render.
		 * 
		 * @param styleProp The name of the style to set.
		 * @param newValue The value to which to set the style.
		 */
		public function setStyle(styleProp:String,newValue:*):void
		{
			mFormat.setStyle(styleProp, newValue);
			mRequiresRedraw = true;
		}
		
		/** Returns the styles on this text's TextLayoutFormat.  Note that the getter makes a copy of the  
		 * styles dictionary. The coreStyles object encapsulates all styles set in the format property including core and user styles. The
		 * returned object consists of an array of <em>stylename-value</em> pairs.
		 * 
		 * @see flashx.textLayout.formats.TextLayoutFormat
		 */
		public function get styles():Object
		{
			return mFormat.styles;
		}
		
		/**
		 * Replaces property values in this text's TextLayoutFormat object with the values of properties that are set in
		 * the <code>incoming</code> ITextLayoutFormat instance. Properties that are <code>undefined</code> in the <code>incoming</code>
		 * ITextLayoutFormat instance are not changed in this object.
		 * 
		 * Contents are redrawn with the updated property changes on the next render.
		 * 
		 * @param incoming instance whose property values are applied to this text's TextLayoutFormat object.
		 */
		public function apply(incoming:ITextLayoutFormat):void
		{
			mFormat.apply(incoming);
			mRequiresRedraw = true;
		}
		
		/**
		 * Concatenates the values of properties in the <code>incoming</code> ITextLayoutFormat instance
		 * with the values of this text's TextLayoutFormat object. In this (the receiving) TextLayoutFormat object, properties whose values are <code>FormatValue.INHERIT</code>,
		 * and inheriting properties whose values are <code>undefined</code> will get new values from the <code>incoming</code> object.
		 * Non-inheriting properties whose values are <code>undefined</code> will get their default values.
		 * All other property values will remain unmodified.
		 * 
		 * Contents are redrawn with the updated property changes on the next render.
		 * 
		 * @param incoming instance from which values are concatenated.
		 */
		public function concat(incoming:ITextLayoutFormat):void
		{
			mFormat.concat(incoming);
			mRequiresRedraw = true;
		}
		
		/**
		 * Concatenates the values of properties in the <code>incoming</code> ITextLayoutFormat instance
		 * with the values of this text's TextLayoutFormat object. In this (the receiving) TextLayoutFormat object, properties whose values are <code>FormatValue.INHERIT</code>,
		 * and inheriting properties whose values are <code>undefined</code> will get new values from the <code>incoming</code> object.
		 * All other property values will remain unmodified.
		 * 
		 * Contents are redrawn with the updated property changes on the next render.
		 * 
		 * @param incoming instance from which values are concatenated.
		 */
		public function concatInheritOnly(incoming:ITextLayoutFormat):void
		{
			mFormat.concatInheritOnly(incoming);
			mRequiresRedraw = true;
		}
		
		/**
		 * Copies TextLayoutFormat settings from the <code>values</code> ITextLayoutFormat instance into this text's TextLayoutFormat object.
		 * If <code>values</code> is <code>null</code>, this TextLayoutFormat object is initialized with undefined values for all properties.
		 * 
		 * Contents are redrawn with the updated property changes on the next render.
		 * 
		 * @param values optional instance from which to copy values.
		 */
		public function copy(incoming:ITextLayoutFormat):void
		{
			mFormat.copy(incoming);
			mRequiresRedraw = true;
		}
		
		/**
		 * Sets properties in this text's TextLayoutFormat object to <code>undefined</code> if they do not match those in the
		 * <code>incoming</code> ITextLayoutFormat instance.
		 * 
		 * Contents are redrawn with the updated property changes on the next render.
		 * 
		 * @param incoming instance against which to compare this TextLayoutFormat object's property values.
		 */
		public function removeClashing(incoming:ITextLayoutFormat):void
		{
			mFormat.removeClashing(incoming);
			mRequiresRedraw = true;
		}
		
		/**
		 * Sets properties in this text's TextLayoutFormat object to <code>undefined</code> if they match those in the <code>incoming</code>
		 * ITextLayoutFormat instance.
		 * 
		 * Contents are redrawn with the updated property changes on the next render.
		 * 
		 * @param incoming instance against which to compare this TextLayoutFormat object's property values.
		 */
		public function removeMatching(incoming:ITextLayoutFormat):void
		{
			mFormat.removeMatching(incoming);
			mRequiresRedraw = true;
		}
		
	}
}