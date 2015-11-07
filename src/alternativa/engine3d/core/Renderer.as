/**
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * If it is not possible or desirable to put the notice in a particular file, then You may include the notice in a location (such as a LICENSE file in a relevant directory) where a recipient would be likely to look for such a notice.
 * You may add additional accurate notices of copyright ownership.
 *
 * It is desirable to notify that Covered Software was "Powered by AlternativaPlatform" with link to http://www.alternativaplatform.com/ 
 *
 */
package alternativa.engine3d.core {

	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.materials.ShaderProgram;

    import corelib.utils.ArrayUtils;

    import corelib.utils.DebugUtils;

    import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
    import flash.display3D.VertexBuffer3D;
    import flash.display3D.textures.TextureBase;
    import flash.utils.getTimer;

    import mx.utils.StringUtil;

    import skyboy.utils.fastSort;

    use namespace alternativa3d;

	/**
	 * @private 
	 */
	public class Renderer {

		public static const SKY:int = 10;
		public static const OPAQUE:int = 20;
		public static const OPAQUE_OVERHEAD:int = 25;
		public static const DECALS:int = 30;
		public static const TRANSPARENT_SORTED:int = 40;
        public static const TRANSPARENT_UNSORTED:int = 35;
        public static const GHOST_OPAQUE:int = 47;
		public static const NEXT_LAYER:int = 50;

		alternativa3d var camera:Camera3D;

        private var drawUnitGroups:Vector.<Vector.<DrawUnit>> = new Vector.<Vector.<DrawUnit>>();
        private var drawUnitGroupLength:Vector.<uint> = new Vector.<uint>();

        private var drawUnitPool:Vector.<DrawUnit> = new Vector.<DrawUnit>();
        private var drawUnitPoolPos:uint = 0;

		protected var _contextProperties:RendererContext3DProperties;

        CONFIG::DEBUG
        {
            private var lastOutputTime:int = 0;
        }

		alternativa3d function render(context3D:Context3D):void
        {
			updateContext3D(context3D);

//            CONFIG::DEBUG
//            {
//                var lines:Vector.<String> = new Vector.<String>();
//                var now:int = getTimer();
//                var printDebugInfo:Boolean = now - lastOutputTime >= 3000;
//                if (printDebugInfo) lastOutputTime = now;
//            }

			for (var i:int = 0, len:int = drawUnitGroups.length; i < len; i++)
            {
                var group:Vector.<DrawUnit> = drawUnitGroups[i];
                var groupSize:uint = drawUnitGroupLength[i];
				if (groupSize > 0)
                {
					switch (i)
                    {
						case SKY:
							context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
							break;
						case OPAQUE:
							context3D.setDepthTest(true, Context3DCompareMode.LESS);
                            fastSort(group, 'averageZ', Array.NUMERIC, groupSize);
							break;
						case OPAQUE_OVERHEAD:
							context3D.setDepthTest(false, Context3DCompareMode.EQUAL);
							break;
						case DECALS:
							context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
							break;
						case TRANSPARENT_SORTED:
                            fastSort(group, 'averageZ', Array.NUMERIC | Array.DESCENDING, groupSize);
							context3D.setDepthTest(false, Context3DCompareMode.LESS);
							break;
                        case TRANSPARENT_UNSORTED:
                            context3D.setDepthTest(false, Context3DCompareMode.LESS);
                            break;
                        case GHOST_OPAQUE:
                            context3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
                            break;
						case NEXT_LAYER:
							context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
							break;
					}

                    for (var j:uint = 0; j < groupSize; j++)
                    {
                        var drawUnit:DrawUnit = group[j];
                        renderDrawUnit(group[j], context3D, camera);

//                        CONFIG::DEBUG
//                        {
//                            var id:String = drawUnit.object.userData['id'];
//                            if (id == null) id = drawUnit.object.name;
//                            if (id == null) id = '';
//                            if (printDebugInfo)
//                                lines.push(id + StringUtil.repeat(' ', 30 - id.length) + ' ' + drawUnit.numTriangles.toString() + ' ' + DebugUtils.formatMemoryAddress(DebugUtils.getMemoryAddress(drawUnit.program)) + ' ' + i.toString() + ' ' + drawUnit.passInfo.toString() + ' ' + drawUnit.averageZ.toString());
//                        }
                        drawUnit.clear();
                    }
				}
                drawUnitGroupLength[i] = 0;
			}

//            CONFIG::DEBUG
//            {
//                if (printDebugInfo)
//                {
//                    ArrayUtils.sortVectorOfStringsInPlace(lines);
//                    trace(lines.join('\n') + '\n\n\n\nzzz\n');
//                    lastOutputTime = now;
//                }
//            }
            drawUnitPoolPos = 0;
			freeContext3DProperties(context3D);
		}

		alternativa3d function createDrawUnit(object:Object3D, program:Program3D, indexBuffer:IndexBuffer3D, firstIndex:int, numTriangles:int, debugShader:ShaderProgram = null):DrawUnit {
            if (drawUnitPoolPos == drawUnitPool.length)
            {
                drawUnitPool.length = Math.max(drawUnitPool.length + 100, drawUnitPool.length * 1.5);
                for (var i:uint = drawUnitPoolPos; i < drawUnitPool.length; i++)
                    drawUnitPool[i] = new DrawUnit();
            }

			var res:DrawUnit = drawUnitPool[drawUnitPoolPos];
            res.clear();
            drawUnitPoolPos++;

			res.object = object;
			res.program = program;
			res.indexBuffer = indexBuffer;
			res.firstIndex = firstIndex;
			res.numTriangles = numTriangles;
			return res;
		}

		alternativa3d function addDrawUnit(drawUnit:DrawUnit, renderPriority:int):void
        {
            var groupCount:uint = drawUnitGroups.length;
			if (renderPriority >= groupCount)
            {
                drawUnitGroupLength.length = renderPriority + 1;
                drawUnitGroups.length = renderPriority + 1;
                for (var i:uint = groupCount; i < drawUnitGroups.length; i++)
                    drawUnitGroups[i] = new Vector.<DrawUnit>();
            }
            var group:Vector.<DrawUnit> = drawUnitGroups[renderPriority];
            var groupLength:uint = drawUnitGroupLength[renderPriority];
            if (groupLength == group.length) group.length = Math.max(group.length + 100, group.length * 2);
            group[groupLength] = drawUnit;
            drawUnitGroupLength[renderPriority]++;
            drawUnit.averageZ = drawUnit.object.localToCameraTransform.l;
		}

		protected function renderDrawUnit(drawUnit:DrawUnit, context:Context3D, camera:Camera3D):void {
			if (_contextProperties.blendSource != drawUnit.blendSource || _contextProperties.blendDestination != drawUnit.blendDestination)
            {
				context.setBlendFactors(drawUnit.blendSource, drawUnit.blendDestination);
				_contextProperties.blendSource = drawUnit.blendSource;
				_contextProperties.blendDestination = drawUnit.blendDestination;
			}

			if (_contextProperties.culling != drawUnit.culling)
            {
				context.setCulling(drawUnit.culling);
				_contextProperties.culling = drawUnit.culling;
			}

            var contextBuffer:Vector.<VertexBuffer3D> = _contextProperties.vertexBuffers;
            var contextBufferOffset:Vector.<int> = _contextProperties.vertexBuffersOffsets;
            var contextBufferFormat:Vector.<String> = _contextProperties.vertexBuffersFormats;

            var usedBuffers:uint = 0;
			for (var i:int = 0; i < drawUnit.vertexBuffersLength; i++)
            {
				var bufferIndex:int = drawUnit.vertexBuffersIndexes[i];
                var buffer:VertexBuffer3D = drawUnit.vertexBuffers[i];
                var bufferOffset:int = drawUnit.vertexBuffersOffsets[i];
                var bufferFormat:String = drawUnit.vertexBuffersFormats[i];

                if (contextBuffer.length <= bufferIndex)
                {
                    contextBuffer.length = bufferIndex + 1;
                    contextBufferOffset.length = bufferIndex + 1;
                    contextBufferFormat.length = bufferIndex + 1;
                }

                usedBuffers |= 1 << bufferIndex;
                if (buffer != contextBuffer[bufferIndex] || bufferOffset != contextBufferOffset[bufferIndex] || bufferFormat != contextBufferFormat[bufferIndex])
                {
                    contextBuffer[bufferIndex] = buffer;
                    contextBufferOffset[bufferIndex] = bufferOffset;
                    contextBufferFormat[bufferIndex] = bufferFormat;
//                    trace('context.setVertexBufferAt', bufferIndex, buffer, bufferOffset, bufferFormat);
				    context.setVertexBufferAt(bufferIndex, buffer, bufferOffset, bufferFormat);
                }
			}

            var unusedBuffers:int = _contextProperties.usedBuffers & ~usedBuffers;
            _contextProperties.usedBuffers = usedBuffers;
            for (var i:int = 0; i < contextBuffer.length; i++, unusedBuffers >>= 1)
            {
                if (unusedBuffers & 1)
                {
//                    trace('context.setVertexBufferAt', i, 'null');
                    context.setVertexBufferAt(i, null);
                    contextBuffer[i] = null;
                }
            }

            if (drawUnit.vertexConstantsRegistersCount > 0) context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, drawUnit.vertexConstants, drawUnit.vertexConstantsRegistersCount);
			if (drawUnit.fragmentConstantsRegistersCount > 0) context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, drawUnit.fragmentConstants, drawUnit.fragmentConstantsRegistersCount);

            var usedSamplers:uint = 0;
            var samplers:Vector.<TextureBase> = _contextProperties.samplers;
			for (i = 0; i < drawUnit.texturesLength; i++)
            {
                var texture:TextureBase = drawUnit.textures[i];
                var samplerIndex:int = drawUnit.texturesSamplers[i];
                usedSamplers |= 1 << samplerIndex;
                if (samplers.length <= samplerIndex) samplers.length = samplerIndex + 1;
                if (samplers[samplerIndex] != texture)
                {
                    samplers[samplerIndex] = texture;
//                    trace('context.setTextureAt', samplerIndex, texture);
				    context.setTextureAt(samplerIndex, texture);
                }
			}

            var unusedSamplers:int = _contextProperties.usedSamplers & ~usedSamplers;
            _contextProperties.usedSamplers = usedSamplers;
            for (var i:int = 0; i < samplers.length; i++, unusedSamplers >>= 1)
            {
                if (unusedSamplers & 1)
                {
//                    trace('context.setTextureAt', i, null);
                    context.setTextureAt(i, null);
                    samplers[i] = null;
                }
            }

			if (_contextProperties.program != drawUnit.program)
            {
				context.setProgram(drawUnit.program);
				_contextProperties.program = drawUnit.program;
			}

//            trace('context.drawTriangles', drawUnit.object.name, drawUnit.indexBuffer, drawUnit.firstIndex, drawUnit.numTriangles);
			context.drawTriangles(drawUnit.indexBuffer, drawUnit.firstIndex, drawUnit.numTriangles);
			camera.numDraws++;
			camera.numTriangles += drawUnit.numTriangles;
		}

		protected function updateContext3D(value:Context3D):void
        {
			_contextProperties = camera.context3DProperties;
		}

		alternativa3d function freeContext3DProperties(context3D:Context3D):void
        {
			_contextProperties.culling = null;
			_contextProperties.blendSource = null;
			_contextProperties.blendDestination = null;
			_contextProperties.program = null;

            var samplers:Vector.<TextureBase> = _contextProperties.samplers;
            for (var i:int = 0; i < samplers.length; i++)
            {
                if (samplers[i] != null)
                {
                    samplers[i] = null;
                    context3D.setTextureAt(i, null);
                }
            }

            var buffers:Vector.<VertexBuffer3D> = _contextProperties.vertexBuffers;
            for (var i:int = 0; i < buffers.length; i++)
            {
                if (buffers[i] != null)
                {
                    buffers[i] = null;
                    context3D.setVertexBufferAt(i, null);
                }
            }
		}
	}
}
