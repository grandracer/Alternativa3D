/**
 * Created by pc3 on 18.03.14.
 */
package alternativa.engine3d.core
{
    import alternativa.engine3d.alternativa3d;
    import alternativa.engine3d.objects.Surface;

    use namespace alternativa3d;

    public class RayIntersectionContext
    {
        alternativa3d var childrenCallStack:Vector.<Object3D>;

        alternativa3d var surface:Surface;

        alternativa3d var stopIndex:uint;

        public var trianglesToCheck:uint;

        public var invisibleObjectsAreTransparentForRays:Boolean;

        public var rayIntersectionData:RayIntersectionData;

        public function RayIntersectionContext(maxTrianglesToCheck:uint = uint.MAX_VALUE)
        {
            this.trianglesToCheck = maxTrianglesToCheck;
            this.invisibleObjectsAreTransparentForRays = false;
            reset();
        }

        public function isRayIntersectionFinished():Boolean
        {
            return childrenCallStack == null;
        }

        public function reset():void
        {
            this.childrenCallStack = null;
            this.surface = null;
            this.stopIndex = 0;
            this.rayIntersectionData = null;
        }
    }
}
