/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 * */

package alternativa.engine3d.lights {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;

	use namespace alternativa3d;

	/**
	 * OmniLight is an attenuated light source placed at one point and spreads outward in  a coned direction.
	 *
	 * Lightning direction defines by z-axis of  OmniLight.
	 * You can use lookAt() to make DirectionalLight point at given coordinates.
	 */
	public class SpotLight extends Light3D {

		/**
		 * Distance from which falloff starts.
		 */
		public var attenuationBegin:Number;

		/**
		 * Distance from at which falloff is complete.
		 */
		public var attenuationEnd:Number;

		/**
		 * Adjusts the angle of a light's cone.
		 */
		public var hotspot:Number;

		/**
		 * Adjusts the angle of a light's falloff. For photometric lights, the Field angle is comparable
		 * to the Falloff angle. It is the angle at which the light's intensity has fallen to zero.
		 */
		public var falloff:Number;

		/**
		 * Creates a new SpotLight instance.
		 * @param color Light color.
		 * @param attenuationBegin Distance from which falloff starts.
		 * @param attenuationEnd Distance from at which falloff is complete.
		 * @param hotspot Adjusts the angle of a light's cone. The Hotspot value is measured in radians.
		 * @param falloff Adjusts the angle of a light's falloff. The Falloff value is measured in radians.
		 */
		public function SpotLight(color:uint, attenuationBegin:Number, attenuationEnd:Number, hotspot:Number, falloff:Number) {
			this.type = SPOT;
			this.color = color;
			this.attenuationBegin = attenuationBegin;
			this.attenuationEnd = attenuationEnd;
			this.hotspot = hotspot;
			this.falloff = falloff;
			calculateBoundBox();
		}

		/**
		 * @private 
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			var r:Number = (falloff < Math.PI) ? Math.sin(falloff*0.5)*attenuationEnd : attenuationEnd;
			var bottom:Number = (falloff < Math.PI) ? 0 : Math.cos(falloff*0.5)*attenuationEnd;
			boundBox.minX = -r;
			boundBox.minY = -r;
			boundBox.minZ = bottom;
			boundBox.maxX = r;
			boundBox.maxY = r;
			boundBox.maxZ = attenuationEnd;
		}

		/**
		 * Set direction of the light direction to the given coordinates..
		 */
		public function lookAt(x:Number, y:Number, z:Number):void {
			var dx:Number = x - this.x;
			var dy:Number = y - this.y;
			var dz:Number = z - this.z;
			rotationX = Math.atan2(dz, Math.sqrt(dx*dx + dy*dy)) - Math.PI/2;
			rotationY = 0;
			rotationZ = -Math.atan2(dx, dy);
		}
		
		override alternativa3d function checkBound(targetObject:Object3D):Boolean
        {
            return AlternativaUtils.checkSpotLightBound(lightToObjectTransform, boundBox, targetObject.boundBox);
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:SpotLight = new SpotLight(color, attenuationBegin, attenuationEnd, hotspot, falloff);
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}
