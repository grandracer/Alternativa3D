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
	 * OmniLight is an attenuated light source placed at one point and spreads outward in all directions.
	 *
	 */
	public class OmniLight extends Light3D {

		/**
		 * Distance from which falloff starts.
		 */
		public var attenuationBegin:Number;

		/**
		 * Distance from at which falloff is complete.
		 */
		public var attenuationEnd:Number;

		/**
		 * Creates a OmniLight object.
		 * @param color Light color.
		 * @param attenuationBegin Distance from which falloff starts.
		 * @param attenuationEnd Distance from at which falloff is complete.
		 */
		public function OmniLight(color:uint, attenuationBegin:Number, attenuationEnd:Number) {
			this.type = OMNI;
			this.color = color;
			this.attenuationBegin = attenuationBegin;
			this.attenuationEnd = attenuationEnd;
			calculateBoundBox();
		}

		/**
		 * @private
		 */
		override alternativa3d function updateBoundBox(boundBox:BoundBox, transform:Transform3D = null):void {
			if (transform != null) {

			} else {
				if (-attenuationEnd < boundBox.minX) boundBox.minX = -attenuationEnd;
				if (attenuationEnd > boundBox.maxX) boundBox.maxX = attenuationEnd;
				if (-attenuationEnd < boundBox.minY) boundBox.minY = -attenuationEnd;
				if (attenuationEnd > boundBox.maxY) boundBox.maxY = attenuationEnd;
				if (-attenuationEnd < boundBox.minZ) boundBox.minZ = -attenuationEnd;
				if (attenuationEnd > boundBox.maxZ) boundBox.maxZ = attenuationEnd;
			}
		}

		/**
		 * @private
		 */
		override alternativa3d function checkBound(targetObject:Object3D):Boolean
        {
			return AlternativaUtils.checkOmniLightBound(lightToObjectTransform, attenuationEnd, targetObject.boundBox);
		}

		/**
		 * @inheritDoc
		 */
		override public function clone():Object3D {
			var res:OmniLight = new OmniLight(color, attenuationBegin, attenuationEnd);
			res.clonePropertiesFrom(this);
			return res;
		}

	}
}
