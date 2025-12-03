
/**
 * Will spawn a sphere that emits bullet forces where the bullet lands, for 1 frame
 * 
 * Ideally this should be done via a static function but we have these
 * for debug and template purposes for now.
 */

class ABulletImpactFieldSystemActor : ABaseImpactFieldSystemActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	default SphereCollision.SphereRadius = 150.0;

	default StrainMagnitude = 1000000.0;
	default ForceMagnitude = 20000.0;
	default TorqueMagnitude = 20000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyFieldForce();

		// don't think this works on non haze actors...
		AddActorDisable(this);

		// Debug::DrawDebugSphere(
		// 	SphereCollision.GetWorldLocation(),
		// 	SphereCollision.GetScaledSphereRadius(),
		// 	Duration = 2  
		// );
	}

}