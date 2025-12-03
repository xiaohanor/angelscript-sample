
UCLASS(Abstract)
class AAIIslandDodger : ABasicAIFlyingCharacter
{
	UPROPERTY(DefaultComponent)
	UProjectileProximityDetectorComponent ProjectileProximityComp;
	default ProjectileProximityComp.DetectionShape.SphereRadius = 600.0;

	UPROPERTY(DefaultComponent)
	UHazeEffectEventHandlerComponent EffectEventComp;

	UPROPERTY(DefaultComponent)
	UScifiCopsGunDamageableComponent CopsGunsDamageComp;
}