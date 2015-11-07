/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/
 * */

package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.compiler.Linker;
	import alternativa.engine3d.materials.compiler.Procedure;
	import alternativa.engine3d.objects.Surface;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	use namespace alternativa3d;

	public class Object3D
    {
		protected static const trm:Transform3D = new Transform3D();

        public var userData:Object = {};
        public var useShadow:Boolean = true;
        public var _excludedLights:Vector.<Light3D> = new Vector.<Light3D>();
		public var name:String;
		public var visible:Boolean = true;
		public var boundBox:BoundBox;
        public var includeInRayIntersect:Boolean = true;
		public var _x:Number = 0;
		public var _y:Number = 0;
		public var _z:Number = 0;
		public var _rotationX:Number = 0;
		public var _rotationY:Number = 0;
		public var _rotationZ:Number = 0;
		public var _scaleX:Number = 1;
		public var _scaleY:Number = 1;
		public var _scaleZ:Number = 1;
		public var parent:Object3D; // read-only
		public var childrenList:Object3D;
		public var next:Object3D;
		public var transform:Transform3D = new Transform3D();
		public var inverseTransform:Transform3D = new Transform3D();
		public var transformChanged:Boolean = true;
		public var cameraToLocalTransform:Transform3D = new Transform3D();
		public var localToCameraTransform:Transform3D = new Transform3D();
		public var localToGlobalTransform:Transform3D = new Transform3D();
		public var globalToLocalTransform:Transform3D = new Transform3D();
		public var localToLightTransform:Transform3D = new Transform3D();
		public var culling:int;
		public var distance:Number;
		public var transformProcedure:Procedure;
		public var deltaTransformProcedure:Procedure;

		/**
		 * X coordinate.
		 */
		public function get x():Number {
			return _x;
		}

		public function set x(value:Number):void {
			if (_x != value) {
				_x = value;
				transformChanged = true;
			}
		}

		/**
		 * Y coordinate.
		 */
		public function get y():Number {
			return _y;
		}

		public function set y(value:Number):void {
			if (_y != value) {
				_y = value;
				transformChanged = true;
			}
		}

		/**
		 *  Z coordinate.
		 */
		public function get z():Number {
			return _z;
		}

		public function set z(value:Number):void {
			if (_z != value) {
				_z = value;
				transformChanged = true;
			}
		}

		/**
		 *  The  angle of rotation of <code>Object3D</code> around the X-axis expressed in radians.
		 */
		public function get rotationX():Number {
			return _rotationX;
		}

		public function set rotationX(value:Number):void {
			if (_rotationX != value) {
				_rotationX = value;
				transformChanged = true;
			}
		}

		/**
		 * The  angle of rotation of <code>Object3D</code> around the Y-axis expressed in radians.
		 */
		public function get rotationY():Number {
			return _rotationY;
		}

		public function set rotationY(value:Number):void {
			if (_rotationY != value) {
				_rotationY = value;
				transformChanged = true;
			}
		}

		/**
		 * The  angle of rotation of <code>Object3D</code> around the Z-axis expressed in radians.
		 */
		public function get rotationZ():Number {
			return _rotationZ;
		}

		public function set rotationZ(value:Number):void {
			if (_rotationZ != value) {
				_rotationZ = value;
				transformChanged = true;
			}
		}

		/**
		 * The scale of the <code>Object3D</code> along the X-axis.
		 */
		public function get scaleX():Number {
			return _scaleX;
		}

		public function set scaleX(value:Number):void {
			if (_scaleX != value) {
				_scaleX = value;
				transformChanged = true;
			}
		}

		/**
		 * The scale of the <code>Object3D</code> along the Y-axis.
		 */
		public function get scaleY():Number {
			return _scaleY;
		}

		public function set scaleY(value:Number):void {
			if (_scaleY != value) {
				_scaleY = value;
				transformChanged = true;
			}
		}

		/**
		 * The scale of the <code>Object3D</code> along the Z-axis.
		 */
		public function get scaleZ():Number {
			return _scaleZ;
		}

		public function set scaleZ(value:Number):void {
			if (_scaleZ != value) {
				_scaleZ = value;
				transformChanged = true;
			}
		}

		/**
		 * The <code>matrix</code> property represents a transformation matrix that determines the position
		 * and orientation of an <code>Object3D</code>.
		 */
		public function get matrix():Matrix3D {
			if (transformChanged) composeTransforms();
			return new Matrix3D(Vector.<Number>([transform.a, transform.e, transform.i, 0, transform.b, transform.f, transform.j, 0, transform.c, transform.g, transform.k, 0, transform.d, transform.h, transform.l, 1]));
		}

		public function set matrix(value:Matrix3D):void {
			var v:Vector.<Vector3D> = value.decompose();
			var t:Vector3D = v[0];
			var r:Vector3D = v[1];
			var s:Vector3D = v[2];
			_x = t.x;
			_y = t.y;
			_z = t.z;
			_rotationX = r.x;
			_rotationY = r.y;
			_rotationZ = r.z;
			_scaleX = s.x;
			_scaleY = s.y;
			_scaleZ = s.z;
			transformChanged = true;
		}

		/**
		 * Searches for the intersection of an <code>Object3D</code> and given ray, defined by <code>origin</code> and <code>direction</code>.
		 *
		 * @param origin Origin of the ray.
		 * @param direction Direction of the ray.
		 * @return The result of searching given as <code>RayIntersectionData</code>. <code>null</code> will returned in case of intersection was not found.
		 * @see RayIntersectionData
		 * @see alternativa.engine3d.objects.Sprite3D
		 * @see alternativa.engine3d.core.Camera3D#calculateRay()
		 */
		public function intersectRay(origin:Vector3D, direction:Vector3D, rayIntersectionContext:RayIntersectionContext = null):RayIntersectionData {
            if (rayIntersectionContext == null) rayIntersectionContext = new RayIntersectionContext();
            if (rayIntersectionContext.invisibleObjectsAreTransparentForRays && !visible) return null;
            if (rayIntersectionContext.childrenCallStack != null) {
                if (rayIntersectionContext.childrenCallStack[0] == this) {
                    rayIntersectionContext.childrenCallStack.shift();
                    if (rayIntersectionContext.childrenCallStack.length == 0) rayIntersectionContext.childrenCallStack = null;
                } else {
                    rayIntersectionContext.reset();
                }
            }
            var data:RayIntersectionData = includeInRayIntersect ? intersectRayChildren(origin, direction, rayIntersectionContext) : null;
            if (rayIntersectionContext.childrenCallStack != null) rayIntersectionContext.childrenCallStack.unshift(this);
            return data;
		}

		alternativa3d function intersectRayChildren(origin:Vector3D, direction:Vector3D, rayIntersectionContext:RayIntersectionContext = null):RayIntersectionData {
			var minTime:Number = Number.MAX_VALUE;
			var minData:RayIntersectionData = rayIntersectionContext.rayIntersectionData;
			var childOrigin:Vector3D = null;
			var childDirection:Vector3D = null;
            var stopped:Boolean = false;
            if (rayIntersectionContext.childrenCallStack != null && rayIntersectionContext.childrenCallStack[0].parent != this) {
                rayIntersectionContext.reset();
            }
            var list:Object3D = rayIntersectionContext.childrenCallStack == null ? childrenList : rayIntersectionContext.childrenCallStack[0];
			for (var child:Object3D = list; !stopped && child != null; child = child.next) {
                if (rayIntersectionContext.childrenCallStack == null || child == rayIntersectionContext.childrenCallStack[0]) {
                    if (child.transformChanged) child.composeTransforms();
                    if (childOrigin == null) {
                        childOrigin = new Vector3D();
                        childDirection = new Vector3D();
                    }
                    childOrigin.x = child.inverseTransform.a*origin.x + child.inverseTransform.b*origin.y + child.inverseTransform.c*origin.z + child.inverseTransform.d;
                    childOrigin.y = child.inverseTransform.e*origin.x + child.inverseTransform.f*origin.y + child.inverseTransform.g*origin.z + child.inverseTransform.h;
                    childOrigin.z = child.inverseTransform.i*origin.x + child.inverseTransform.j*origin.y + child.inverseTransform.k*origin.z + child.inverseTransform.l;
                    childDirection.x = child.inverseTransform.a*direction.x + child.inverseTransform.b*direction.y + child.inverseTransform.c*direction.z;
                    childDirection.y = child.inverseTransform.e*direction.x + child.inverseTransform.f*direction.y + child.inverseTransform.g*direction.z;
                    childDirection.z = child.inverseTransform.i*direction.x + child.inverseTransform.j*direction.y + child.inverseTransform.k*direction.z;
                    var data:RayIntersectionData = child.intersectRay(childOrigin, childDirection, rayIntersectionContext);
                    if (data != null && data.time < minTime) {
                        minData = data;
                        minTime = data.time;
                    }
                    stopped = rayIntersectionContext.childrenCallStack != null;
                }
			}
            rayIntersectionContext.rayIntersectionData = minData;
			return minData;
		}

		/**
		 * A <code>Matrix3D</code> object representing the combined transformation matrices of the <code>Object3D</code>
		 * and all of its parent objects, back to the root level.
		 */
		public function get concatenatedMatrix():Matrix3D {
			if (transformChanged) composeTransforms();
			trm.copy(transform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.append(root.transform);
			}
			return new Matrix3D(Vector.<Number>([trm.a, trm.e, trm.i, 0, trm.b, trm.f, trm.j, 0, trm.c, trm.g, trm.k, 0, trm.d, trm.h, trm.l, 1]));
		}

		private static var _storeConcatenatedMatrix$buffer:Vector.<Number> = new Vector.<Number>(16, true);
        public var meshMergerLastRenderCallId:int;
		public function storeConcatenatedMatrix(result:Matrix3D):void {
			if (transformChanged) composeTransforms();
			trm.copy(transform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.append(root.transform);
			}
			_storeConcatenatedMatrix$buffer[0] = trm.a;
			_storeConcatenatedMatrix$buffer[1] = trm.e;
			_storeConcatenatedMatrix$buffer[2] = trm.i;
			_storeConcatenatedMatrix$buffer[3] = 0;
			_storeConcatenatedMatrix$buffer[4] = trm.b;
			_storeConcatenatedMatrix$buffer[5] = trm.f;
			_storeConcatenatedMatrix$buffer[6] = trm.j;
			_storeConcatenatedMatrix$buffer[7] = 0;
			_storeConcatenatedMatrix$buffer[8] = trm.c;
			_storeConcatenatedMatrix$buffer[9] = trm.g;
			_storeConcatenatedMatrix$buffer[10] = trm.k;
			_storeConcatenatedMatrix$buffer[11] = 0;
			_storeConcatenatedMatrix$buffer[12] = trm.d;
			_storeConcatenatedMatrix$buffer[13] = trm.h;
			_storeConcatenatedMatrix$buffer[14] = trm.l;
			_storeConcatenatedMatrix$buffer[15] = 1;
            result.copyRawDataFrom(_storeConcatenatedMatrix$buffer);
		}

		/**
		 * Converts the <code>Vector3D</code> object from the <code>Object3D</code>'s own (local) coordinates to the root <code>Object3D</code> (global) coordinates.
		 * @param point Point in local coordinates of <code>Object3D</code>.
		 * @return Point in coordinates of root <code>Object3D</code>.
		 */
		public function localToGlobal(point:Vector3D):Vector3D {
			if (transformChanged) composeTransforms();
			trm.copy(transform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.append(root.transform);
			}
			var res:Vector3D = new Vector3D();
			res.x = trm.a*point.x + trm.b*point.y + trm.c*point.z + trm.d;
			res.y = trm.e*point.x + trm.f*point.y + trm.g*point.z + trm.h;
			res.z = trm.i*point.x + trm.j*point.y + trm.k*point.z + trm.l;
			return res;
		}

		public function storeLocalToGlobal(point:Vector3D, result:Vector3D):void {
			if (transformChanged) composeTransforms();
			trm.copy(transform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.append(root.transform);
			}
			result.x = trm.a*point.x + trm.b*point.y + trm.c*point.z + trm.d;
			result.y = trm.e*point.x + trm.f*point.y + trm.g*point.z + trm.h;
			result.z = trm.i*point.x + trm.j*point.y + trm.k*point.z + trm.l;
		}

		/**
		 * Converts the <code>Vector3D</code> object from the root <code>Object3D</code> (global) coordinates to the local <code>Object3D</code>'s own coordinates.
		 * @param point Point in coordinates of root <code>Object3D</code>.
		 * @return Point in local coordinates of <code>Object3D</code>.
		 */
		public function globalToLocal(point:Vector3D):Vector3D {
			if (transformChanged) composeTransforms();
			trm.copy(inverseTransform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.prepend(root.inverseTransform);
			}
			var res:Vector3D = new Vector3D();
			res.x = trm.a*point.x + trm.b*point.y + trm.c*point.z + trm.d;
			res.y = trm.e*point.x + trm.f*point.y + trm.g*point.z + trm.h;
			res.z = trm.i*point.x + trm.j*point.y + trm.k*point.z + trm.l;
			return res;
		}

		public function storeGlobalToLocal(point:Vector3D, result:Vector3D):void {
			if (transformChanged) composeTransforms();
			trm.copy(inverseTransform);
			var root:Object3D = this;
			while (root.parent != null) {
				root = root.parent;
				if (root.transformChanged) root.composeTransforms();
				trm.prepend(root.inverseTransform);
			}
			result.x = trm.a*point.x + trm.b*point.y + trm.c*point.z + trm.d;
			result.y = trm.e*point.x + trm.f*point.y + trm.g*point.z + trm.h;
			result.z = trm.i*point.x + trm.j*point.y + trm.k*point.z + trm.l;
		}

		alternativa3d function get useLights():Boolean {
			return false;
		}

		/**
		 * Calculates object's bounds in its own coordinates
		 */
		public function calculateBoundBox():void {
			if (boundBox != null) {
				boundBox.reset();
			} else {
				boundBox = new BoundBox();
			}
			// Fill values of th boundBox
			updateBoundBox(boundBox, null);
		}

		alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
		}


		/**
		 *  Adds given <code>Object3D</code> instance as a child to the end of this <code>Object3D</code>'s children list.
		 *  If the given object was added to another <code>Object3D</code> already, it removes from it's old place.
		 * @param child The <code>Object3D</code> instance to add.
		 * @return The <code>Object3D</code> instance that you pass in the <code>child</code> parameter.
		 */
		public function addChild(child:Object3D):Object3D {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child == this) throw new ArgumentError("An object cannot be added as a child of itself.");
			for (var container:Object3D = parent; container != null; container = container.parent) {
				if (container == child) throw new ArgumentError("An object cannot be added as a child to one of it's children (or children's children, etc.).");
			}
			// Adding
			if (child.parent != this) {
				// Removing from old place
				if (child.parent != null) child.parent.removeChild(child);
				// Adding
				addToList(child);
				child.parent = this;
			} else {
				child = removeFromList(child);
				if (child == null) throw new ArgumentError("Cannot add child.");
				// Adding
				addToList(child);
			}
			return child;
		}

		/**
		 * Removes the specified child <code>Object3D</code> instance from the child list of the
		 * this <code>Object3D</code> instance. The <code>parent</code> property of the removed child is set to <code>null</code>.
		 *
		 * @param child The <code>Object3D</code> instance to remove.
		 * @return The <code>Object3D</code> instance that you pass in the <code>child</code> parameter.
		 */
		public function removeChild(child:Object3D):Object3D {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child.parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			child = removeFromList(child);
			if (child == null) throw new ArgumentError("Cannot remove child.");
			// Dispatching the event
			child.parent = null;
			return child;
		}

		/**
		 * Removes child objects in given range of indexes.
		 * @param beginIndex Index, starts from which objects should be removed.
		 * @param endIndex Index, till which objects should be removed.
		 */
		public function removeChildren(beginIndex:int = 0, endIndex:int = 2147483647):void {
			// Error checking
			if (beginIndex < 0) throw new RangeError("The supplied index is out of bounds.");
			if (endIndex < beginIndex) throw new RangeError("The supplied index is out of bounds.");
			var i:int = 0;
			var prev:Object3D = null;
			var begin:Object3D = childrenList;
			while (i < beginIndex) {
				if (begin == null) {
					if (endIndex < 2147483647) {
						throw new RangeError("The supplied index is out of bounds.");
					} else {
						return;
					}
				}
				prev = begin;
				begin = begin.next;
				i++;
			}
			if (begin == null) {
				if (endIndex < 2147483647) {
					throw new RangeError("The supplied index is out of bounds.");
				} else {
					return;
				}
			}
			var end:Object3D = null;
			if (endIndex < 2147483647) {
				end = begin;
				while (i <= endIndex) {
					if (end == null) throw new RangeError("The supplied index is out of bounds.");
					end = end.next;
					i++;
				}
			}
			if (prev != null) {
				prev.next = end;
			} else {
				childrenList = end;
			}
			// Removing
			while (begin != end) {
				var next:Object3D = begin.next;
				begin.next = null;
				begin.parent = null;
				begin = next;
			}
		}

		/**
		 * Returns the child <code>Object3D</code> instance that exists at the specified index.
		 * @param index Position of wished child.
		 * @return Child object at given position.
		 */
		public function getChildAt(index:int):Object3D {
			// Error checking
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Search for element by index
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			if (current == null) throw new RangeError("The supplied index is out of bounds.");
			return current;
		}

		/**
		 * Returns index of given child  <code>Object3D</code> instance.
		 * @param child Child  <code>Object3D</code> instance.
		 * @return Index of given child  <code>Object3D</code> instance.
		 */
		public function getChildIndex(child:Object3D):int {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child.parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Search for index
			var index:int = 0;
			for (var current:Object3D = childrenList; current != null; current = current.next) {
				if (current == child) return index;
				index++;
			}
			throw new ArgumentError("Cannot get child index.");
		}

		/**
		 * Sets index for child  <code>Object3D</code> instance.
		 * @param child Child  <code>Object3D</code> instance.
		 * @param index Index should be set.
		 */
		public function setChildIndex(child:Object3D, index:int):void {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			if (child.parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			if (index < 0) throw new RangeError("The supplied index is out of bounds.");
			// Search for element by index
			var current:Object3D = childrenList;
			for (var i:int = 0; i < index; i++) {
				if (current == null) throw new RangeError("The supplied index is out of bounds.");
				current = current.next;
			}
			// Removing
			child = removeFromList(child);
			if (child == null) throw new ArgumentError("Cannot set child index.");
			// Adding
			addToList(child, current);
		}

		/**
		 * Swaps index positions of two specified child objects.
		 * @param child1 The first object to swap.
		 * @param child2 The second object to swap.
		 */
		public function swapChildren(child1:Object3D, child2:Object3D):void {
			// Error checking
			if (child1 == null || child2 == null) throw new TypeError("Parameter child must be non-null.");
			if (child1.parent != this || child2.parent != this) throw new ArgumentError("The supplied Object3D must be a child of the caller.");
			// Swapping
			if (child1 != child2) {
				if (child1.next == child2) {
					child2 = removeFromList(child2);
					if (child2 == null) throw new ArgumentError("Cannot swap children.");
					addToList(child2, child1);
				} else if (child2.next == child1) {
					child1 = removeFromList(child1);
					if (child1 == null) throw new ArgumentError("Cannot swap children.");
					addToList(child1, child2);
				} else {
					var count:int = 0;
					for (var child:Object3D = childrenList; child != null; child = child.next) {
						if (child == child1) count++;
						if (child == child2) count++;
						if (count == 2) break;
					}
					if (count < 2) throw new ArgumentError("Cannot swap children.");
					var nxt:Object3D = child1.next;
					removeFromList(child1);
					addToList(child1, child2);
					removeFromList(child2);
					addToList(child2, nxt);
				}
			}
		}

		/**
		 * Swaps index positions of two child objects by its index.
		 * @param index1 Index of the first object to swap.
		 * @param index2 Index of the second object to swap.
		 */
		public function swapChildrenAt(index1:int, index2:int):void {
			// Error checking
			if (index1 < 0 || index2 < 0) throw new RangeError("The supplied index is out of bounds.");
			// Swapping
			if (index1 != index2) {
				// Search for element by index
				var i:int;
				var child1:Object3D = childrenList;
				for (i = 0; i < index1; i++) {
					if (child1 == null) throw new RangeError("The supplied index is out of bounds.");
					child1 = child1.next;
				}
				if (child1 == null) throw new RangeError("The supplied index is out of bounds.");
				var child2:Object3D = childrenList;
				for (i = 0; i < index2; i++) {
					if (child2 == null) throw new RangeError("The supplied index is out of bounds.");
					child2 = child2.next;
				}
				if (child2 == null) throw new RangeError("The supplied index is out of bounds.");
				if (child1 != child2) {
					if (child1.next == child2) {
						removeFromList(child2);
						addToList(child2, child1);
					} else if (child2.next == child1) {
						removeFromList(child1);
						addToList(child1, child2);
					} else {
						var nxt:Object3D = child1.next;
						removeFromList(child1);
						addToList(child1, child2);
						removeFromList(child2);
						addToList(child2, nxt);
					}
				}
			}
		}

		/**
		 * Returns child <code>Object3D</code> instance with given <code>name</code>.
		 * In case of there are several objects with same name, the first of them will returned.
		 * If there are no objects with given name, <code>null</code> will returned.
		 *
		 * @param name The name of child object.
		 * @return Child Object3D with given name.
		 */
		public function getChildByName(name:String):Object3D {
			// Error checking
			if (name == null) throw new TypeError("Parameter name must be non-null.");
			// Search for object
			for (var child:Object3D = childrenList; child != null; child = child.next) {
				if (child.name == name) return child;
			}
			return null;
		}

		/**
		 * Check if given object is child of this <code>Object3D</code>.
		 * @param child Child <code>Object3D</code> instance.
		 * @return <code>true</code> if given instance is this  <code>Object3D</code> or one of its children or <code>false</code> otherwise.
		 */
		public function contains(child:Object3D):Boolean {
			// Error checking
			if (child == null) throw new TypeError("Parameter child must be non-null.");
			// Search for object
			if (child == this) return true;
			for (var object:Object3D = childrenList; object != null; object = object.next) {
				if (object.contains(child)) return true;
			}
			return false;
		}

		/**
		 * Returns the number of children of this object.
		 */
		public function get numChildren():int {
			var num:int = 0;
			for (var current:Object3D = childrenList; current != null; current = current.next) num++;
			return num;
		}

		private function addToList(child:Object3D, item:Object3D = null):void {
			child.next = item;
			if (item == childrenList) {
				childrenList = child;
			} else {
				for (var current:Object3D = childrenList; current != null; current = current.next) {
					if (current.next == item) {
						current.next = child;
						break;
					}
				}
			}
		}

		alternativa3d function removeFromList(child:Object3D):Object3D {
			var prev:Object3D;
			for (var current:Object3D = childrenList; current != null; current = current.next) {
				if (current == child) {
					if (prev != null) {
						prev.next = current.next;
					} else {
						childrenList = current.next;
					}
					current.next = null;
					return child;
				}
				prev = current;
			}
			return null;
		}

		/**
		 * Gather the resources of this <code>Object3D</code>. This resources should be uploaded in the <code>Context3D</code> in order to <code>Object3D</code> can be rendered.
		 *
		 * @param hierarchy If <code>true</code>, the resources of all children will be gathered too.
		 * @param resourceType If defined, only resources of this type will be gathered.
		 * @return Vector consists of gathered resources
		 * @see flash.display.Stage3D
		 */
		public function getResources(hierarchy:Boolean = false, resourceType:Class = null):Vector.<Resource> {
			var res:Vector.<Resource> = new Vector.<Resource>();
			var dict:Dictionary = new Dictionary();
			var count:int = 0;
			fillResources(dict, hierarchy, resourceType);
			for (var key:* in dict) {
				res[count++] = key as Resource;
			}
			return res;
		}

		alternativa3d function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			if (hierarchy) {
				for (var child:Object3D = childrenList; child != null; child = child.next) {
					child.fillResources(resources, hierarchy, resourceType);
				}
			}
		}

		alternativa3d function composeTransforms():void {
			// Matrix
			var cosX:Number = Math.cos(_rotationX);
			var sinX:Number = Math.sin(_rotationX);
			var cosY:Number = Math.cos(_rotationY);
			var sinY:Number = Math.sin(_rotationY);
			var cosZ:Number = Math.cos(_rotationZ);
			var sinZ:Number = Math.sin(_rotationZ);
			var cosZsinY:Number = cosZ*sinY;
			var sinZsinY:Number = sinZ*sinY;
			var cosYscaleX:Number = cosY*_scaleX;
			var sinXscaleY:Number = sinX*_scaleY;
			var cosXscaleY:Number = cosX*_scaleY;
			var cosXscaleZ:Number = cosX*_scaleZ;
			var sinXscaleZ:Number = sinX*_scaleZ;
			transform.a = cosZ*cosYscaleX;
			transform.b = cosZsinY*sinXscaleY - sinZ*cosXscaleY;
			transform.c = cosZsinY*cosXscaleZ + sinZ*sinXscaleZ;
			transform.d = _x;
			transform.e = sinZ*cosYscaleX;
			transform.f = sinZsinY*sinXscaleY + cosZ*cosXscaleY;
			transform.g = sinZsinY*cosXscaleZ - cosZ*sinXscaleZ;
			transform.h = _y;
			transform.i = -sinY*_scaleX;
			transform.j = cosY*sinXscaleY;
			transform.k = cosY*cosXscaleZ;
			transform.l = _z;
			// Inverse matrix
			var sinXsinY:Number = sinX*sinY;
			cosYscaleX = cosY/_scaleX;
			cosXscaleY = cosX/_scaleY;
			sinXscaleZ = -sinX/_scaleZ;
			cosXscaleZ = cosX/_scaleZ;
			inverseTransform.a = cosZ*cosYscaleX;
			inverseTransform.b = sinZ*cosYscaleX;
			inverseTransform.c = -sinY/_scaleX;
			inverseTransform.d = -inverseTransform.a*_x - inverseTransform.b*_y - inverseTransform.c*_z;
			inverseTransform.e = sinXsinY*cosZ/_scaleY - sinZ*cosXscaleY;
			inverseTransform.f = cosZ*cosXscaleY + sinXsinY*sinZ/_scaleY;
			inverseTransform.g = sinX*cosY/_scaleY;
			inverseTransform.h = -inverseTransform.e*_x - inverseTransform.f*_y - inverseTransform.g*_z;
			inverseTransform.i = cosZ*sinY*cosXscaleZ - sinZ*sinXscaleZ;
			inverseTransform.j = cosZ*sinXscaleZ + sinY*sinZ*cosXscaleZ;
			inverseTransform.k = cosY*cosXscaleZ;
			inverseTransform.l = -inverseTransform.i*_x - inverseTransform.j*_y - inverseTransform.k*_z;
			transformChanged = false;
		}

		alternativa3d function calculateVisibility(camera:Camera3D):void {
		}

		alternativa3d function calculateChildrenVisibility(camera:Camera3D):void {
			for (var child:Object3D = childrenList; child != null; child = child.next)
            {
				// Checking visibility flag
				if (child.visible)
                {
					// Compose matrix and inverse matrix
					if (child.transformChanged) child.composeTransforms();
					// Calculating matrix for converting from camera coordinates to local coordinates
					child.cameraToLocalTransform.combine(child.inverseTransform, cameraToLocalTransform);
					// Calculating matrix for converting from local coordinates to  camera coordinates
					child.localToCameraTransform.combine(localToCameraTransform, child.transform);

					// Culling checking
					if (child.boundBox != null)
                    {
						camera.calculateFrustum(child.cameraToLocalTransform);
						child.culling = child.boundBox.checkFrustumCulling(camera.frustum, 63);
					}
                    else
                    {
						child.culling = 63;
					}
					// Calculating visibility of the self content
					if (child.culling >= 0) child.calculateVisibility(camera);
					// Calculating visibility of children
					if (child.childrenList != null) child.calculateChildrenVisibility(camera);
				}
			}
		}

		alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
            meshMergerLastRenderCallId = camera.renderCallId;
		}

		alternativa3d function collectChildrenDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
			var i:int;
			var light:Light3D;

			for (var child:Object3D = childrenList; child != null; child = child.next)
            {
				// Checking visibility flag
				if (child.visible)
                {
					// Check getting in frustum and occluding
					if (child.culling >= 0)
                    {
						// Check if object needs in lightning
						var excludedLightLength:int = child._excludedLights.length;
						if (lightsLength > 0 && child.useLights) {
							// Pass the lights to children and calculate appropriate transformations
							var childLightsLength:int = 0;
							var j:int;
							if (child.boundBox != null) {
								for (i = 0; i < lightsLength; i++) {
									light = lights[i];
									// Checking object for existing in excludedLights
									j = 0;
									while (j<excludedLightLength && child._excludedLights[j]!=light)	j++;
									if (j<excludedLightLength) continue;

									light.lightToObjectTransform.combine(child.cameraToLocalTransform, light.localToCameraTransform);
									// Detect influence
									if (light.boundBox == null || light.checkBound(child)) {
										camera.childLights[childLightsLength] = light;
										childLightsLength++;
									}
								}
							} else {
								// Calculate transformation from light space to object space
								for (i = 0; i < lightsLength; i++) {
									light = lights[i];
									// Проверка источника света на отсутствие в excludedLights
									j = 0;
									while (j<excludedLightLength && child._excludedLights[j]!=light)	j++;
									if (j<excludedLightLength) continue;
									light.lightToObjectTransform.combine(child.cameraToLocalTransform, light.localToCameraTransform);
									camera.childLights[childLightsLength] = light;
									childLightsLength++;
								}
							}
                            sortLights(camera.childLights, childLightsLength);
							child.collectDraws(camera, camera.childLights, childLightsLength, useShadow&&child.useShadow);
						} else {
							child.collectDraws(camera, null, 0, useShadow&&child.useShadow);
						}
						// Debug the boundbox
						if (camera.debug && child.boundBox != null && (camera.checkInDebug(child) & Debug.BOUNDS)) Debug.drawBoundBox(camera, child.boundBox, child.localToCameraTransform);
					}
					// Gather the draws for children
					if (child.childrenList != null) child.collectChildrenDraws(camera, lights, lightsLength, useShadow && child.useShadow);
				}
			}
		}

        private static const LIGHT_TYPE_COUNT:int = 5;

        private static var __sortLights$buffers:Vector.<Vector.<Light3D>>;
        private static var __sortLights$bufferSize:Vector.<int>;

        protected static function sortLights(lights:Vector.<Light3D>, length:int):void
        {
            if (length < 2) return;
            if (__sortLights$buffers == null)
            {
                __sortLights$buffers = new Vector.<Vector.<Light3D>>(LIGHT_TYPE_COUNT, true);
                __sortLights$bufferSize = new Vector.<int>(LIGHT_TYPE_COUNT, true);
                for (var i:int = 0; i < LIGHT_TYPE_COUNT; i++)
                    __sortLights$buffers[i] = new Vector.<Light3D>(64, true);
            }

            for (var i:int = 0; i < LIGHT_TYPE_COUNT; i++)
                __sortLights$bufferSize[i] = 0;

            for (var i:int = 0; i < length; i++)
            {
                var light:Light3D = lights[i];
                var lightType:int = light.type;
                __sortLights$buffers[lightType][__sortLights$bufferSize[lightType]] = light;
                __sortLights$bufferSize[lightType]++;
            }

            var pos:int = 0;
            for (var i:int = 0; i < LIGHT_TYPE_COUNT; i++)
            {
                var buffer:Vector.<Light3D> = __sortLights$buffers[i];
                var lightsCount:int = __sortLights$bufferSize[i];
                for (var j:int = 0; j < lightsCount; j++, pos++)
                    lights[pos] = buffer[j];
            }
        }

		alternativa3d function setTransformConstants(drawUnit:DrawUnit, surface:Surface, vertexShader:Linker, camera:Camera3D):void {
		}


		/**
		 * Disables lighting of the object by given <code>light</code>.
         *
         * @param light Light which should not affect to the object
         * @param updateChildren If <code>true</code> all children of this object will be also shielded from the given light.
         * @see  #excludedLights()
         * @see  #clearExcludedLights()
		 */
		public function excludeLight(light:Light3D, updateChildren:Boolean = false):void{
			if (_excludedLights.indexOf(light) < 0) {
				_excludedLights.push(light);
			}
			if (updateChildren) {
				for (var child:Object3D = childrenList; child != null; child = child.next) {
					child.excludeLight(light, true);
				}
			}
		}

		/**
		 * Returns excluded lights list of current object.
		 */
		public function get excludedLights():Vector.<Light3D> {
			return _excludedLights.concat();
		}

		/**
		 * Resets list of lights excluded from lighting this object.
		 */
		public function clearExcludedLights(updateChildren:Boolean = false):void {
			_excludedLights.length = 0;
			if (updateChildren) {
				for (var child:Object3D = childrenList; child != null; child = child.next) {
					child.clearExcludedLights(true);
				}
			}
		}

		/**
		 * Returns a copy of object.
		 * @return A copy of this <code>Object3D</code>.
		 */
		public function clone():Object3D {
			var res:Object3D = new Object3D();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * Copies basic properties of <code>Object3D</code>. This method calls from  <code>clone()</code> method.
		 * @param source <code>Object3D</code>, properties of  which will be copied.
		 */
		protected function clonePropertiesFrom(source:Object3D):void {
			userData = source.userData;

			name = source.name;
			visible = source.visible;
			boundBox = source.boundBox ? source.boundBox.clone() : null;
			_x = source._x;
			_y = source._y;
			_z = source._z;
			_rotationX = source._rotationX;
			_rotationY = source._rotationY;
			_rotationZ = source._rotationZ;
			_scaleX = source._scaleX;
			_scaleY = source._scaleY;
			_scaleZ = source._scaleZ;
			for (var child:Object3D = source.childrenList, lastChild:Object3D; child != null; child = child.next) {
				var newChild:Object3D = child.clone();
				if (childrenList != null) {
					lastChild.next = newChild;
				} else {
					childrenList = newChild;
				}
				lastChild = newChild;
				newChild.parent = this;
			}
		}

		/**
		 * Returns the string representation of the specified object.
		 * @return The string representation of the specified object.
		 */
		public function toString():String {
			var className:String = getQualifiedClassName(this);
			var start:int = className.indexOf("::");
			return "[" + (start < 0 ? className : className.substr(start + 2)) + " " + name + "]";
		}

	}
}
