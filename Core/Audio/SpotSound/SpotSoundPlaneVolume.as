// Super simple volume without overlaps to use for drawing bounds to use for Plane-spots
class ASpotSoundPlaneVolume : AVolume
{
	default BrushComponent.bGenerateOverlapEvents = false;
	default BrushComponent.CollisionProfileName = n"AudioCollider";
}