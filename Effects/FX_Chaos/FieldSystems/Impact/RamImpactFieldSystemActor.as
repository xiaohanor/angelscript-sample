
/**
 * Will spawn a sphere that emits bullet forces where the bullet lands, for 1 frame
 * 
 * Ideally this should be done via a static function but we have these
 * for debug and template purposes for now.
 */

class ARamImpactFieldSystemActor : ABaseImpactFieldSystemActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	default SphereCollision.SphereRadius = 200.0;
	default StrainMagnitude = 1000000.0;
	default ForceMagnitude = 6000.0;
	default TorqueMagnitude = 3000.0;
}