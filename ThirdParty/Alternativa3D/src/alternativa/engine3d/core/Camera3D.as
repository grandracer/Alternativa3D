/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display3D.Context3D;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getTimer;

	use namespace alternativa3d;

/**
 *
 * Camera - it's three-dimensional object without its own visual representation and intended for visualising  hierarchy of objects.
 * For resource optimization camera draws only visible objects(objects in frustum). The view frustum is the volume that contains
 * everything that is potentially visible on the screen. This volume takes the shape of a truncated pyramid, which defines
 * by 6 planes. The apex of the pyramid is the camera position and the base of the pyramid is the <code>farClipping</code>.
 * The pyramid is truncated at the <code>nearClipping</code>. Current version of Alternativa3D uses Z-Buffer for sorting objects,
 * accuracy of sorting depends on distance between <code>farClipping</code> and <code>nearClipping</code>. That's why necessary to set a minimum
 * distance between them for current scene. nearClipping mustn't be equal zero.
 *
 */
public class Camera3D extends Object3D {

	/**
	 * @private
	 * Key - context, value - properties.
	 */
	alternativa3d static var context3DPropertiesPool:Dictionary = new Dictionary(true);

	/**
	 * The viewport defines part of screen to which renders image seen by the camera.
	 * If viewport is not defined, the camera would not draws anything.
	 */
	public var view:View;

	/**
	 * Field if view. Defines in radians.  Default value is <code>Math.PI/2</code> which considered with 90 degrees.
	 */
	public var fov:Number = Math.PI / 2;

	/**
	 * Near clipping distance. Default value <code>0</code>. It should be as big as possible.
	 */
	public var nearClipping:Number;

	/**
	 * Far distance of clipping. Default value <code>Number.MAX_VALUE</code>.
	 */
	public var farClipping:Number;

	/**
	 * Determines whether orthographic (true) or perspective (false) projection is used. The default value is false.
	 */
	public var orthographic:Boolean = false;

	/**
	 *  Determines whether context 3D is cleared prior to render (e.g. for layering with Starling output)
	 */
	public var renderClearsContext:Boolean = true;

	/**
	 *  Determines whether context 3D is presented after render (e.g. set false if Starling takes responsibilty for that)
	 */
	public var renderPresentsContext:Boolean = true;

	/**
	 * @private
	 */
	alternativa3d var focalLength:Number;
	/**
	 * @private
	 */
	alternativa3d var m0:Number;
	/**
	 * @private
	 */
	alternativa3d var m5:Number;
	/**
	 * @private
	 */
	alternativa3d var m10:Number;
	/**
	 * @private
	 */
	alternativa3d var m14:Number;
	/**
	 * @private
	 */
	alternativa3d var correctionX:Number;
	/**
	 * @private
	 */
	alternativa3d var correctionY:Number;

	/**
	 * @private
	 */
	alternativa3d var lights:Vector.<Light3D> = new Vector.<Light3D>();
	/**
	 * @private
	 */
	alternativa3d var lightsLength:int = 0;
	/**
	 * @private
	 */
	alternativa3d var ambient:Vector.<Number> = new Vector.<Number>(4);
	/**
	 * @private
	 */
	alternativa3d var childLights:Vector.<Light3D> = new Vector.<Light3D>();

	/**
	 * @private
	 */
	alternativa3d var frustum:CullingPlane;

	/**
	 * @private
	 */
	alternativa3d var origins:Vector.<Vector3D> = new Vector.<Vector3D>();
	/**
	 * @private
	 */
	alternativa3d var directions:Vector.<Vector3D> = new Vector.<Vector3D>();
	/**
	 * @private
	 */
	alternativa3d var raysLength:int = 0;

	/**
	 * @private
	 * <code>Context3D</code> which is used for rendering.
	 */
	alternativa3d var context3D:Context3D;

	/**
	 * @private
	 */
	alternativa3d var context3DProperties:RendererContext3DProperties;

	/**
	 * @private
	 * Camera's renderer. If is not defined, the camera will no draw anything.
	 */
	public var renderer:Renderer = new Renderer();

	/**
	 * @private
	 */
	alternativa3d var numDraws:int;

	/**
	 * @private
	 */
	alternativa3d var numTriangles:int;
    public var renderCallId:int = 0;

	/**
	 * Creates a <code>Camera3D</code> object.
	 *
	 * @param nearClipping  Near clipping distance.
	 * @param farClipping  Far clipping distance.
	 */
	public function Camera3D(nearClipping:Number, farClipping:Number) {
		this.nearClipping = nearClipping;
		this.farClipping = farClipping;
		frustum = new CullingPlane();
		frustum.next = new CullingPlane();
		frustum.next.next = new CullingPlane();
		frustum.next.next.next = new CullingPlane();
		frustum.next.next.next.next = new CullingPlane();
		frustum.next.next.next.next.next = new CullingPlane();
	}

	/**
	 * Rendering of objects hierarchy to the given <code>Stage3D</code>.
	 *
	 * @param stage3D  <code>Stage3D</code> to which image will be rendered.
	 */
	public function render(stage3D:Stage3D):void {
		var i:int;
		var j:int;
		var light:Light3D;
		// Error checking
		if (stage3D == null) throw new TypeError("Parameter stage3D must be non-null.");
		// Reset the counters
		numDraws = 0;
		numTriangles = 0;

		// Reset the lights
		lightsLength = 0;
        renderCallId++;
		ambient[0] = 0;
		ambient[1] = 0;
		ambient[2] = 0;
		ambient[3] = 1;
		// Receiving the context
		var currentContext3D:Context3D = stage3D.context3D;
		if (currentContext3D != context3D) {
			if (currentContext3D != null) {
				context3DProperties = context3DPropertiesPool[currentContext3D];
				if (context3DProperties == null) {
					context3DProperties = new RendererContext3DProperties();
					context3DProperties.isConstrained = currentContext3D.driverInfo.lastIndexOf("(Baseline Constrained)") >= 0;
                    context3DProperties.profile = currentContext3D.profile;
					context3DPropertiesPool[currentContext3D] = context3DProperties;
				}
				context3D = currentContext3D;
			} else {
				context3D = null;
				context3DProperties = null;
			}
		}
		if (context3D != null && view != null && renderer != null && (view.stage != null || view._canvas != null)) {
			renderer.camera = this;
			// Projection argument calculating
			calculateProjection(view._width, view._height);
			// Preparing to rendering
			view.configureContext3D(stage3D, context3D, this);
			// Transformations calculating
			if (transformChanged) composeTransforms();
			localToGlobalTransform.copy(transform);
			globalToLocalTransform.copy(inverseTransform);
			// Searching for upper hierarchy point
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				localToGlobalTransform.append(root.transform);
				globalToLocalTransform.prepend(root.inverseTransform);
			}

			// Check if object of hierarchy is visible
			if (root.visible) {
				// Calculating the matrix to transform from the camera space to local space
				root.cameraToLocalTransform.combine(root.inverseTransform, localToGlobalTransform);
				// Calculating the matrix to transform from local space to the camera space
				root.localToCameraTransform.combine(globalToLocalTransform, root.transform);

				// Checking the culling
				if (root.boundBox != null) {
                    calculateFrustum(root.cameraToLocalTransform);
					root.culling = root.boundBox.checkFrustumCulling(frustum, 63);
				} else {
					root.culling = 63;
				}
				// Calculations of content visibility
				if (root.culling >= 0) root.calculateVisibility(this);
				// Calculations  visibility of children
				root.calculateChildrenVisibility(this);

				// Check light influence
				for (i = 0, j = 0; i < lightsLength; i++) {
					light = lights[i];
					light.localToCameraTransform.calculateInversion(light.cameraToLocalTransform);
                    light.red = ((light.color >> 16) & 0xFF) * light.intensity / 255;
                    light.green = ((light.color >> 8) & 0xFF) * light.intensity / 255;
                    light.blue = (light.color & 0xFF) * light.intensity / 255;
                    // Debug
                    light.collectDraws(this, null, 0, false);
                    if (debug && light.boundBox != null && (checkInDebug(light) & Debug.BOUNDS)) Debug.drawBoundBox(this, light.boundBox, light.localToCameraTransform);

                    // Shadows preparing
                    if (light.shadow != null) {
                        light.shadow.process(this);
                    }
                    lights[j] = light;
                    j++;
					light.culling = -1;
				}
				lightsLength = j;
				lights.length = j;

				// Sort lights by types
				sortLights(lights, lightsLength);

				for (i = origins.length; i < view.raysLength; i++) {
					origins[i] = new Vector3D();
					directions[i] = new Vector3D();
				}
				raysLength = view.raysLength;

				if (renderClearsContext) {
					var r:Number = ((view.backgroundColor >> 16) & 0xff)/0xff;
					var g:Number = ((view.backgroundColor >> 8) & 0xff)/0xff;
					var b:Number = (view.backgroundColor & 0xff)/0xff;
					if (view._canvas != null) {
						r *= view.backgroundAlpha;
						g *= view.backgroundAlpha;
						b *= view.backgroundAlpha;
					}
					context3D.clear(r, g, b, view.backgroundAlpha);
				}

				// Check getting in frustum and occluding
				if (root.culling >= 0 && root.boundBox == null)
                {
					// Check if object needs in lightning
					var excludedLightLength:int = root._excludedLights.length;
					if (lightsLength > 0 && root.useLights) {
						// Pass the lights to children and calculate appropriate transformations
						var childLightsLength:int = 0;
						if (root.boundBox != null) {
							for (i = 0; i < lightsLength; i++) {
								light = lights[i];
								// Checking light source for existing in excludedLights
								j = 0;
								while (j<excludedLightLength && root._excludedLights[j]!=light)	j++;
								if (j<excludedLightLength) continue;

								light.lightToObjectTransform.combine(root.cameraToLocalTransform, light.localToCameraTransform);
								// Detect influence
								if (light.boundBox == null || light.checkBound(root)) {
									childLights[childLightsLength] = light;
									childLightsLength++;
								}
							}
						} else {
							// Calculate transformation from light space to object space
							for (i = 0; i < lightsLength; i++) {
								light = lights[i];
								// Checking light source for existing in excludedLights
								j = 0;
								while (j<excludedLightLength && root._excludedLights[j]!=light)	j++;
								if (j<excludedLightLength) continue;

								light.lightToObjectTransform.combine(root.cameraToLocalTransform, light.localToCameraTransform);

								childLights[childLightsLength] = light;
								childLightsLength++;
							}
						}
                        sortLights(childLights, childLightsLength);
						root.collectDraws(this, childLights, childLightsLength, root.useShadow);
					} else {
						root.collectDraws(this, null, 0, root.useShadow);
					}
					// Debug the boundbox
					if (debug && root.boundBox != null && (checkInDebug(root) & Debug.BOUNDS)) Debug.drawBoundBox(this, root.boundBox, root.localToCameraTransform);
				}
				root.collectChildrenDraws(this, lights, lightsLength, root.useShadow);
				renderer.render(context3D);
			}
			// Output
			if (view._canvas == null) {
				if (renderPresentsContext) {
					context3D.present();
				}
			} else {
				context3D.drawToBitmapData(view._canvas);
				context3D.present();
			}
		}
		// Clearing
		lights.length = 0;
		childLights.length = 0;
	}

    public function calculateFrustum(transform:Transform3D):void
    {
        if (orthographic) AlternativaUtils.calculateFrustumOrthographic(frustum, view._width, view._height, nearClipping, farClipping, transform);
        else AlternativaUtils.calculateFrustumPerspective(frustum, correctionX, correctionY, nearClipping, farClipping, transform);
    }

	/**
	 * Setup Camera3D position using x, y, z coordinates
	 */
	public function setPosition(x:Number, y:Number, z:Number):void{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/**
	 *  Camera3D lookAt method
	 */
	public function lookAt(x:Number, y:Number, z:Number):void{
		var deltaX:Number = x - this.x;
		var deltaY:Number = y - this.y;
		var deltaZ:Number = z - this.z;
		var rotX:Number = Math.atan2(deltaZ, Math.sqrt(deltaX * deltaX + deltaY * deltaY));
		rotationX = rotX - 0.5 * Math.PI;
		rotationY = 0;
		rotationZ =  -  Math.atan2(deltaX,deltaY);
	}

	/**
	 * Transforms point from global space to screen space. The <code>view</code> property should be defined.
	 * @param point Point in global space.
	 * @return A Vector3D object containing screen coordinates.
	 */
	public function projectGlobal(point:Vector3D):Vector3D {
		if (view == null) throw new Error("It is necessary to have view set.");
		var viewSizeX:Number = view._width * 0.5;
		var viewSizeY:Number = view._height * 0.5;
		var focalLength:Number = Math.sqrt(viewSizeX * viewSizeX + viewSizeY * viewSizeY) / Math.tan(fov * 0.5);
		var res:Vector3D = globalToLocal(point);
		res.x = res.x * focalLength / res.z + viewSizeX;
		res.y = res.y * focalLength / res.z + viewSizeY;
		return res;
	}

	public function storeGlobalProjection(point:Vector3D, result:Vector3D):void {
		if (view == null) throw new Error("It is necessary to have view set.");
		var viewSizeX:Number = view._width * 0.5;
		var viewSizeY:Number = view._height * 0.5;
		var focalLength:Number = Math.sqrt(viewSizeX * viewSizeX + viewSizeY * viewSizeY) / Math.tan(fov * 0.5);
		storeGlobalToLocal(point, result);
		result.x = result.x * focalLength / result.z + viewSizeX;
		result.y = result.y * focalLength / result.z + viewSizeY;
	}

	/**
	 * Calculates a ray in global space. The ray defines by its <code>origin</code> and <code>direction</code>.
	 * The ray goes like from the global camera position
	 * trough the point corresponding to the viewport point with coordinates <code>viewX</code> Ð¸ <code>viewY</code>.
	 * The ray origin placed within <code>nearClipping</code> plane.
	 * This ray can be used in the <code>Object3D.intersectRay()</code> method.  The result writes to passed arguments.
	 *
	 * @param origin Ray origin will wrote here.
	 * @param direction Ray direction will wrote here.
	 * @param viewX Horizontal coordinate in view plane, through which the ray should go.
	 * @param viewY Vertical coordinate in view plane, through which the ray should go.
	 */
	public function calculateRay(origin:Vector3D, direction:Vector3D, viewX:Number, viewY:Number):void {
		if (view == null) throw new Error("It is necessary to have view set.");
		var viewSizeX:Number = view._width * 0.5;
		var viewSizeY:Number = view._height * 0.5;
		var focalLength:Number = Math.sqrt(viewSizeX * viewSizeX + viewSizeY * viewSizeY) / Math.tan(fov * 0.5);
		var dx:Number = viewX - viewSizeX;
		var dy:Number = viewY - viewSizeY;
		var ox:Number = dx * nearClipping / focalLength;
		var oy:Number = dy * nearClipping / focalLength;
		var oz:Number = nearClipping;
		if (transformChanged) composeTransforms();
		trm.copy(transform);
		var root:Object3D = this;
		while (root.parent != null) {
			root = root.parent;
			if (root.transformChanged) root.composeTransforms();
			trm.append(root.transform);
		}
		origin.x = trm.a * ox + trm.b * oy + trm.c * oz + trm.d;
		origin.y = trm.e * ox + trm.f * oy + trm.g * oz + trm.h;
		origin.z = trm.i * ox + trm.j * oy + trm.k * oz + trm.l;
		direction.x = trm.a * dx + trm.b * dy + trm.c * focalLength;
		direction.y = trm.e * dx + trm.f * dy + trm.g * focalLength;
		direction.z = trm.i * dx + trm.j * dy + trm.k * focalLength;
		var directionL:Number = 1 / Math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z);
		direction.x *= directionL;
		direction.y *= directionL;
		direction.z *= directionL;
	}

	/**
	 * @inheritDoc
	 */
	override public function clone():Object3D {
		var res:Camera3D = new Camera3D(nearClipping, farClipping);
		res.clonePropertiesFrom(this);
		return res;
	}

	/**
	 * @inheritDoc
	 */
	override protected function clonePropertiesFrom(source:Object3D):void {
		super.clonePropertiesFrom(source);
		var src:Camera3D = source as Camera3D;
		fov = src.fov;
		view = src.view;
		nearClipping = src.nearClipping;
		farClipping = src.farClipping;
		orthographic = src.orthographic;
	}

	/**
	 * @private
	 */
	alternativa3d function calculateProjection(width:Number, height:Number):void {
		var viewSizeX:Number = width * 0.5;
		var viewSizeY:Number = height * 0.5;
		focalLength = Math.sqrt(viewSizeX * viewSizeX + viewSizeY * viewSizeY) / Math.tan(fov * 0.5);
		if (!orthographic) {
			m0 = focalLength / viewSizeX;
			m5 = -focalLength / viewSizeY;
			m10 = farClipping / (farClipping - nearClipping);
			m14 = -nearClipping * m10;
		} else {
			m0 = 1 / viewSizeX;
			m5 = -1 / viewSizeY;
			m10 = 1 / (farClipping - nearClipping);
			m14 = -nearClipping * m10;
		}
		correctionX = viewSizeX / focalLength;
		correctionY = viewSizeY / focalLength;
	}

	/**
	 * @private
	 */


	/**
	 * @private
	 * Transform rays in object space.
	 */
	alternativa3d function calculateRays(transform:Transform3D):void {
		for (var i:int = 0; i < raysLength; i++) {
			var o:Vector3D = view.raysOrigins[i];
			var d:Vector3D = view.raysDirections[i];
			var origin:Vector3D = origins[i];
			var direction:Vector3D = directions[i];
			origin.x = transform.a * o.x + transform.b * o.y + transform.c * o.z + transform.d;
			origin.y = transform.e * o.x + transform.f * o.y + transform.g * o.z + transform.h;
			origin.z = transform.i * o.x + transform.j * o.y + transform.k * o.z + transform.l;
			direction.x = transform.a * d.x + transform.b * d.y + transform.c * d.z;
			direction.y = transform.e * d.x + transform.f * d.y + transform.g * d.z;
			direction.z = transform.i * d.x + transform.j * d.y + transform.k * d.z;
		}
	}

	static private const stack:Vector.<int> = new Vector.<int>();

	// DEBUG

	/**
	 * Turns debug mode on if <code>true</code> and off otherwise.
	 * The default value is <code>false</code>.
	 *
	 * @see #addToDebug()
	 * @see #removeFromDebug()
	 */
	public var debug:Boolean = false;

	private var debugSet:Object = {};

	/**
	 * Adds an object or a class to list of debug drawing.
	 * In case of class, all object of this type will drawn in debug mode.
	 *
	 * @param debug The component of object which will draws in debug mode. Should be <code>Debug.BOUND</code> for now. Check <code>Debug</code> for updates.
	 * @param objectOrClass  <code>Object3D</code> or class extended <code>Object3D</code>.
	 * @see alternativa.engine3d.core.Debug
	 * @see #debug
	 * @see #removeFromDebug()
	 */
	public function addToDebug(debug:int, objectOrClass:*):void {
		if (!debugSet[debug]) debugSet[debug] = new Dictionary();
		debugSet[debug][objectOrClass] = true;
	}

	/**
	 * Removed an object or a class from list of debug drawing.
	 *
	 * @param debug The component of object which will draws in debug mode. Should be <code>Debug.BOUND</code> for now. Check <code>Debug</code> for updates.
	 * @param objectOrClass  <code>Object3D</code> or class extended <code>Object3D</code>.
	 *
	 * @see alternativa.engine3d.core.Debug
	 * @see #debug
	 * @see #addToDebug()
	 */
	public function removeFromDebug(debug:int, objectOrClass:*):void {
		if (debugSet[debug]) {
			delete debugSet[debug][objectOrClass];
			var key:*;
			for (key in debugSet[debug]) break;
			if (!key) delete debugSet[debug];
		}
	}

	/**
	 * @private
	 *
	 * Check if the object or its class is in list of debug drawing.
	 */
	alternativa3d function checkInDebug(object:Object3D):int {
		var res:int = 0;
		for (var debug:int = 1; debug <= 512; debug <<= 1) {
			if (debugSet[debug]) {
				if (debugSet[debug][Object3D] || debugSet[debug][object]) {
					res |= debug;
				} else {
					var objectClass:Class = getDefinitionByName(getQualifiedClassName(object)) as Class;
					while (objectClass != Object3D) {
						if (debugSet[debug][objectClass]) {
							res |= debug;
							break;
						}
						objectClass = Class(getDefinitionByName(getQualifiedSuperclassName(objectClass)));
					}
				}
			}
		}
		return res;
	}


	private var _diagram:Sprite = createDiagram();

	/**
	 * The amount of frames which determines the period of FPS value update in <code>diagram</code>.
	 * @see #diagram
	 */
	public var fpsUpdatePeriod:int = 10;

	/**
	 * The amount of frames which determines the period of MS value update in <code>diagram</code>.
	 * @see #diagram
	 */
	public var timerUpdatePeriod:int = 10;

	private var fpsTextField:TextField;
	private var frameTextField:TextField;
	private var memoryTextField:TextField;
	private var drawsTextField:TextField;
	private var trianglesTextField:TextField;
	private var timerTextField:TextField;
	private var graph:Bitmap;
	private var rect:Rectangle;

	private var _diagramAlign:String = "TR";
	private var _diagramHorizontalMargin:Number = 2;
	private var _diagramVerticalMargin:Number = 2;

	private var fpsUpdateCounter:int;
	private var previousFrameTime:int;
	private var previousPeriodTime:int;

	private var maxMemory:int;

	private var timerUpdateCounter:int;
	private var methodTimeSum:int;
	private var methodTimeCount:int;
	private var methodTimer:int;

	/**
	 * Starts time count. <code>startTimer()</code>and <code>stopTimer()</code> are necessary to measure time for code part executing.
	 * The result is displayed in the field MS of the diagram.
	 *
	 * @see #diagram
	 * @see #stopTimer()
	 */
	public function startTimer():void {
		methodTimer = getTimer();
	}

	/**
	 * Stops time count. <code>startTimer()</code> and <code>stopTimer()</code> are necessary to measure time for code part executing.
	 * The result is displayed in the field MS of the diagram.
	 * @see #diagram
	 * @see #startTimer()
	 */
	public function stopTimer():void {
		methodTimeSum += getTimer() - methodTimer;
		methodTimeCount++;
	}

	/**
	 * Diagram where debug information is displayed. To display <code>diagram</code>, you need to add it on the screen.
	 * FPS is an average amount of frames per second.
	 * MS is an average time of executing the code part in milliseconds. This code part is measured with <code>startTimer</code> - <code>stopTimer</code>.
	 * MEM is an amount of memory reserved by player (in megabytes).
	 * DRW is an amount of draw calls in the current frame.
	 * PLG is an amount of visible polygons in the current frame.
	 * TRI is an amount of drawn triangles in the current frame.
	 *
	 * @see #fpsUpdatePeriod
	 * @see #timerUpdatePeriod
	 * @see #startTimer()
	 * @see #stopTimer()
	 */
	public function get diagram():DisplayObject {
		return _diagram;
	}

	/**
	 * Diagram alignment relatively to working space. You can use constants of <code>StageAlign</code> class.
	 *
	 */
	public function get diagramAlign():String {
		return _diagramAlign;
	}

	/**
	 * @private
	 */
	public function set diagramAlign(value:String):void {
		_diagramAlign = value;
		resizeDiagram();
	}

	/**
	 * Diagram margin from the edge of working space in horizontal axis.
	 */
	public function get diagramHorizontalMargin():Number {
		return _diagramHorizontalMargin;
	}

	/**
	 * @private
	 */
	public function set diagramHorizontalMargin(value:Number):void {
		_diagramHorizontalMargin = value;
		resizeDiagram();
	}

	/**
	 * Diagram margin from the edge of working space in vertical axis.
	 */
	public function get diagramVerticalMargin():Number {
		return _diagramVerticalMargin;
	}

	/**
	 * @private
	 */
	public function set diagramVerticalMargin(value:Number):void {
		_diagramVerticalMargin = value;
		resizeDiagram();
	}

	private function createDiagram():Sprite {
		var diagram:Sprite = new Sprite();
		diagram.mouseEnabled = false;
		diagram.mouseChildren = false;
		// FPS
		fpsTextField = new TextField();
		fpsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
		fpsTextField.autoSize = TextFieldAutoSize.LEFT;
		fpsTextField.text = "FPS:";
		fpsTextField.selectable = false;
		fpsTextField.x = -3;
		fpsTextField.y = -5;
		diagram.addChild(fpsTextField);
		// time of frame
		frameTextField = new TextField();
		frameTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
		frameTextField.autoSize = TextFieldAutoSize.LEFT;
		frameTextField.text = "TME:";
		frameTextField.selectable = false;
		frameTextField.x = -3;
		frameTextField.y = 4;
		diagram.addChild(frameTextField);
		// time of method execution
		timerTextField = new TextField();
		timerTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x0066FF);
		timerTextField.autoSize = TextFieldAutoSize.LEFT;
		timerTextField.text = "MS:";
		timerTextField.selectable = false;
		timerTextField.x = -3;
		timerTextField.y = 13;
		diagram.addChild(timerTextField);
		// memory
		memoryTextField = new TextField();
		memoryTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCC00);
		memoryTextField.autoSize = TextFieldAutoSize.LEFT;
		memoryTextField.text = "MEM:";
		memoryTextField.selectable = false;
		memoryTextField.x = -3;
		memoryTextField.y = 22;
		diagram.addChild(memoryTextField);
		// debug draws
		drawsTextField = new TextField();
		drawsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x00CC00);
		drawsTextField.autoSize = TextFieldAutoSize.LEFT;
		drawsTextField.text = "DRW:";
		drawsTextField.selectable = false;
		drawsTextField.x = -3;
		drawsTextField.y = 31;
		diagram.addChild(drawsTextField);
		// triangles
		trianglesTextField = new TextField();
		trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF3300); // 0xFF6600, 0xFF0033
		trianglesTextField.autoSize = TextFieldAutoSize.LEFT;
		trianglesTextField.text = "TRI:";
		trianglesTextField.selectable = false;
		trianglesTextField.x = -3;
		trianglesTextField.y = 40;
		diagram.addChild(trianglesTextField);
		// diagram initialization
		diagram.addEventListener(Event.ADDED_TO_STAGE, function ():void {
			diagram.removeEventListener(Event.ADDED_TO_STAGE, arguments.callee);
			// FPS
			fpsTextField = new TextField();
			fpsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
			fpsTextField.autoSize = TextFieldAutoSize.RIGHT;
			fpsTextField.text = Number(diagram.stage.frameRate).toFixed(2);
			fpsTextField.selectable = false;
			fpsTextField.x = -3;
			fpsTextField.y = -5;
			fpsTextField.width = 85;
			diagram.addChild(fpsTextField);
			// Frame time
			frameTextField = new TextField();
			frameTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCCCC);
			frameTextField.autoSize = TextFieldAutoSize.RIGHT;
			frameTextField.text = Number(1000 / diagram.stage.frameRate).toFixed(2);
			frameTextField.selectable = false;
			frameTextField.x = -3;
			frameTextField.y = 4;
			frameTextField.width = 85;
			diagram.addChild(frameTextField);
			// Time of method performing
			timerTextField = new TextField();
			timerTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x0066FF);
			timerTextField.autoSize = TextFieldAutoSize.RIGHT;
			timerTextField.text = "";
			timerTextField.selectable = false;
			timerTextField.x = -3;
			timerTextField.y = 13;
			timerTextField.width = 85;
			diagram.addChild(timerTextField);
			// Memory
			memoryTextField = new TextField();
			memoryTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xCCCC00);
			memoryTextField.autoSize = TextFieldAutoSize.RIGHT;
			memoryTextField.text = bytesToString(System.totalMemory);
			memoryTextField.selectable = false;
			memoryTextField.x = -3;
			memoryTextField.y = 22;
			memoryTextField.width = 85;
			diagram.addChild(memoryTextField);
			// Draw calls
			drawsTextField = new TextField();
			drawsTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0x00CC00);
			drawsTextField.autoSize = TextFieldAutoSize.RIGHT;
			drawsTextField.text = "0";
			drawsTextField.selectable = false;
			drawsTextField.x = -3;
			drawsTextField.y = 31;
			drawsTextField.width = 72;
			diagram.addChild(drawsTextField);
			// Number of triangles
			trianglesTextField = new TextField();
			trianglesTextField.defaultTextFormat = new TextFormat("Tahoma", 10, 0xFF3300);
			trianglesTextField.autoSize = TextFieldAutoSize.RIGHT;
			trianglesTextField.text = "0";
			trianglesTextField.selectable = false;
			trianglesTextField.x = -3;
			trianglesTextField.y = 40;
			trianglesTextField.width = 72;
			diagram.addChild(trianglesTextField);
			// Graph
			graph = new Bitmap(new BitmapData(80, 40, true, 0x20FFFFFF));
			rect = new Rectangle(0, 0, 1, 40);
			graph.x = 0;
			graph.y = 54;
			diagram.addChild(graph);
			// Reset of parameters
			previousPeriodTime = getTimer();
			previousFrameTime = previousPeriodTime;
			fpsUpdateCounter = 0;
			maxMemory = 0;
			timerUpdateCounter = 0;
			methodTimeSum = 0;
			methodTimeCount = 0;
			// Subscription
			diagram.stage.addEventListener(Event.ENTER_FRAME, updateDiagram, false, -1000);
			diagram.stage.addEventListener(Event.RESIZE, resizeDiagram, false, -1000);
			resizeDiagram();
		});
		// Deinitialization of diagram
		diagram.addEventListener(Event.REMOVED_FROM_STAGE, function ():void {
			diagram.removeEventListener(Event.REMOVED_FROM_STAGE, arguments.callee);
			// Reset
			diagram.removeChild(fpsTextField);
			diagram.removeChild(frameTextField);
			diagram.removeChild(memoryTextField);
			diagram.removeChild(drawsTextField);
			diagram.removeChild(trianglesTextField);
			diagram.removeChild(timerTextField);
			diagram.removeChild(graph);
			fpsTextField = null;
			frameTextField = null;
			memoryTextField = null;
			drawsTextField = null;
			trianglesTextField = null;
			timerTextField = null;
			graph.bitmapData.dispose();
			graph = null;
			rect = null;
			// Unsubscribe
			diagram.stage.removeEventListener(Event.ENTER_FRAME, updateDiagram);
			diagram.stage.removeEventListener(Event.RESIZE, resizeDiagram);
		});
		return diagram;
	}

	private function resizeDiagram(e:Event = null):void {
		if (_diagram.stage != null) {
			var coord:Point = _diagram.parent.globalToLocal(new Point());
			if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.BOTTOM_LEFT) {
				_diagram.x = Math.round(coord.x + _diagramHorizontalMargin);
			}
			if (_diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.BOTTOM) {
				_diagram.x = Math.round(coord.x + _diagram.stage.stageWidth / 2 - graph.width / 2);
			}
			if (_diagramAlign == StageAlign.TOP_RIGHT || _diagramAlign == StageAlign.RIGHT || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
				_diagram.x = Math.round(coord.x + _diagram.stage.stageWidth - _diagramHorizontalMargin - graph.width);
			}
			if (_diagramAlign == StageAlign.TOP_LEFT || _diagramAlign == StageAlign.TOP || _diagramAlign == StageAlign.TOP_RIGHT) {
				_diagram.y = Math.round(coord.y + _diagramVerticalMargin);
			}
			if (_diagramAlign == StageAlign.LEFT || _diagramAlign == StageAlign.RIGHT) {
				_diagram.y = Math.round(coord.y + _diagram.stage.stageHeight / 2 - (graph.y + graph.height) / 2);
			}
			if (_diagramAlign == StageAlign.BOTTOM_LEFT || _diagramAlign == StageAlign.BOTTOM || _diagramAlign == StageAlign.BOTTOM_RIGHT) {
				_diagram.y = Math.round(coord.y + _diagram.stage.stageHeight - _diagramVerticalMargin - graph.y - graph.height);
			}
		}
	}

	private function updateDiagram(e:Event):void {
		var value:Number;
		var mod:int;
		var time:int = getTimer();
		var stageFrameRate:int = _diagram.stage.frameRate;

		// FPS text
		if (++fpsUpdateCounter == fpsUpdatePeriod) {
			value = 1000 * fpsUpdatePeriod / (time - previousPeriodTime);
			if (value > stageFrameRate) value = stageFrameRate;
			mod = value * 100 % 100;
			fpsTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));
			value = 1000 / value;
			mod = value * 100 % 100;
			frameTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));
			previousPeriodTime = time;
			fpsUpdateCounter = 0;
		}
		// FPS plot
		value = 1000 / (time - previousFrameTime);
		if (value > stageFrameRate) value = stageFrameRate;
		graph.bitmapData.scroll(1, 0);
		graph.bitmapData.fillRect(rect, 0x20FFFFFF);
		graph.bitmapData.setPixel32(0, 40 * (1 - value / stageFrameRate), 0xFFCCCCCC);
		previousFrameTime = time;

		// time text
		if (++timerUpdateCounter == timerUpdatePeriod) {
			if (methodTimeCount > 0) {
				value = methodTimeSum / methodTimeCount;
				mod = value * 100 % 100;
				timerTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));
			} else {
				timerTextField.text = "";
			}
			timerUpdateCounter = 0;
			methodTimeSum = 0;
			methodTimeCount = 0;
		}

		// memory text
		var memory:int = System.totalMemory;
		value = memory / 1048576;
		mod = value * 100 % 100;
		memoryTextField.text = int(value) + "." + ((mod >= 10) ? mod.toString() : ((mod > 0) ? ("0" + mod) : "00"));

		// memory plot
		if (memory > maxMemory) maxMemory = memory;
		graph.bitmapData.setPixel32(0, 40 * (1 - memory / maxMemory), 0xFFCCCC00);

		// debug text
		drawsTextField.text = formatInt(numDraws);

			// Triangles (text)
		trianglesTextField.text = formatInt(numTriangles);
	}

	private function formatInt(num:int):String {
		var n:int;
		var s:String;
		if (num < 1000) {
			return "" + num;
		} else if (num < 1000000) {
			n = num % 1000;
			if (n < 10) {
				s = "00" + n;
			} else if (n < 100) {
				s = "0" + n;
			} else {
				s = "" + n;
			}
			return int(num / 1000) + " " + s;
		} else {
			n = (num % 1000000) / 1000;
			if (n < 10) {
				s = "00" + n;
			} else if (n < 100) {
				s = "0" + n;
			} else {
				s = "" + n;
			}
			n = num % 1000;
			if (n < 10) {
				s += " 00" + n;
			} else if (n < 100) {
				s += " 0" + n;
			} else {
				s += " " + n;
			}
			return int(num / 1000000) + " " + s;
		}
	}

	private function bytesToString(bytes:int):String {
		if (bytes < 1024) return bytes + "b";
		else if (bytes < 10240) return (bytes / 1024).toFixed(2) + "kb";
		else if (bytes < 102400) return (bytes / 1024).toFixed(1) + "kb";
		else if (bytes < 1048576) return (bytes >> 10) + "kb";
		else if (bytes < 10485760) return (bytes / 1048576).toFixed(2);// + "mb";
		else if (bytes < 104857600) return (bytes / 1048576).toFixed(1);// + "mb";
		else return String(bytes >> 20);// + "mb";
	}
}
}
