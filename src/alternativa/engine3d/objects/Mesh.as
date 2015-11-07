/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.objects {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
    import alternativa.engine3d.core.RayIntersectionContext;
    import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.resources.Geometry;

	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace alternativa3d;

	/**
	 *  A polygonal object defined by set of vertices and surfaces built on this vertices. <code>Surface</code> is a set of triangles which have same material.
	 *  To get access to vertices data you should use <code>geometry</code> property.
	 */
	public class Mesh extends Object3D {

		/**
		 * Through <code>geometry </code> property you can get access to vertices.
		 * @see alternativa.engine3d.resources.Geometry
		 */
		public var geometry:Geometry;
		public var surfaces:Vector.<Surface> = new Vector.<Surface>();
		public var surfacesLength:int = 0;

		/**
		 * @inheritDoc
		 */
		override public function intersectRay(origin:Vector3D, direction:Vector3D, rayIntersectionContext:RayIntersectionContext = null):RayIntersectionData {
            if (!includeInRayIntersect) return null;
            if (rayIntersectionContext == null) rayIntersectionContext = new RayIntersectionContext();
            if (rayIntersectionContext.invisibleObjectsAreTransparentForRays && !visible) return null;
            var childrenData:RayIntersectionData = super.intersectRay(origin, direction, rayIntersectionContext);
			var contentData:RayIntersectionData;
			if (rayIntersectionContext.childrenCallStack == null && geometry != null && (boundBox == null || boundBox.intersectRay(origin, direction))) {
				var minTime:Number = Number.MAX_VALUE;
				for each (var surface:Surface in surfaces) {
                    if (rayIntersectionContext.surface == null || rayIntersectionContext.surface == surface) {
                        var indexBegin:uint = Math.max(rayIntersectionContext.stopIndex, surface.indexBegin);
                        var numTrianglesAvailable:uint = surface.numTriangles - (indexBegin - surface.indexBegin) / 3;
                        var numTrianglesToProcess:uint = Math.min(numTrianglesAvailable, rayIntersectionContext.trianglesToCheck);
                        var data:RayIntersectionData = geometry.intersectRay(origin, direction, indexBegin, numTrianglesToProcess);
                        if (data != null && data.time < minTime) {
                            contentData = data;
                            contentData.object = this;
                            contentData.surface = surface;
                            minTime = data.time;
                        }
                        rayIntersectionContext.surface = null;
                        rayIntersectionContext.stopIndex = 0;
                        rayIntersectionContext.trianglesToCheck -= numTrianglesToProcess;
                        if (numTrianglesAvailable > numTrianglesToProcess) {
                            rayIntersectionContext.surface = surface;
                            rayIntersectionContext.stopIndex = indexBegin + numTrianglesToProcess * 3;
                            rayIntersectionContext.childrenCallStack = new <Object3D>[this];
                            break;
                        }
                    }
				}
			}
            var result:RayIntersectionData = childrenData == null ? contentData : contentData == null ? childrenData : childrenData.time < contentData.time ? childrenData : contentData;
            rayIntersectionContext.rayIntersectionData = result;
            return result;
		}

		// TODO: Add removeSurface() method

		/**
		 * Adds <code>Surface</code> to <code>Mesh</code> object.
		 * @param material Material of the surface.
		 * @param indexBegin Position of the firs index of  surface in the geometry.
		 * @param numTriangles Number of triangles.
		 */
		public function addSurface(material:Material, indexBegin:uint, numTriangles:uint):Surface {
			var res:Surface = new Surface();
			res.object = this;
			res.material = material;
			res.indexBegin = indexBegin;
			res.numTriangles = numTriangles;
			surfaces[surfacesLength++] = res;
			return res;
		}

		/**
		 * Returns surface by index.
		 *
		 * @param index  Index.
		 * @return  Surface with given index.
		 */
		public function getSurface(index:int):Surface {
			return surfaces[index];
		}

		/**
		 * Number of surfaces.
		 */
		public function get numSurfaces():int {
			return surfacesLength;
		}

		/**
		 * Assign given material to all surfaces.
		 *
		 * @param material Material.
		 * @see alternativa.engine3d.objects.Surface
		 * @see alternativa.engine3d.materials
		 */
		public function setMaterialToAllSurfaces(material:Material):void {
			for (var i:int = 0; i < surfaces.length; i++) {
				surfaces[i].material = material;
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function get useLights():Boolean {
			return true;
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			if (geometry != null) geometry.updateBoundBox(boundBox, transform);
		}
		
		/**
		 * @private
		 */
		alternativa3d override function fillResources(resources:Dictionary, hierarchy:Boolean = false, resourceType:Class = null):void {
			if (geometry != null && (resourceType == null || geometry is resourceType)) resources[geometry] = true;
			for (var i:int = 0; i < surfacesLength; i++) {
				var s:Surface = surfaces[i];
				if (s.material != null) s.material.fillResources(resources, resourceType);
			}
			super.fillResources(resources, hierarchy, resourceType);
		}

		/**
		 * @private
		 */
		override alternativa3d function collectDraws(camera:Camera3D, lights:Vector.<Light3D>, lightsLength:int, useShadow:Boolean):void {
            meshMergerLastRenderCallId = camera.renderCallId;
			for (var i:int = 0; i < surfacesLength; i++) {
				var surface:Surface = surfaces[i];
				if (surface.material != null && surface.meshMergerIsVisible && !surface.meshMergerInBuffer) surface.material.collectDraws(camera, surface, geometry, lights, lightsLength, useShadow, -1);
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:Mesh = new Mesh();
			res.clonePropertiesFrom(this);
			return res;
		}

		/**
		 * @inheritDoc
		 */
		override protected function clonePropertiesFrom(source:Object3D):void {
			super.clonePropertiesFrom(source);
			var mesh:Mesh = source as Mesh;
			geometry = mesh.geometry;
			surfacesLength = 0;
			surfaces.length = 0;
			for each (var s:Surface in mesh.surfaces) {
				addSurface(s.material, s.indexBegin, s.numTriangles);
			}
		}

	}
}
