
/**
 * Will spawn a sphere that emits bullet forces where the bullet lands, for 1 frame
 * 
 * Ideally this should be done via a static function but we have these
 * for debug and template purposes for now.
 */

class AAcidImpactFieldSystemActor : ABaseImpactFieldSystemActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	default SphereCollision.SphereRadius = 150.0;

	default StrainMagnitude = 50000.0;
	default ForceMagnitude = 450000.0;
	default TorqueMagnitude = 150000.0;
}