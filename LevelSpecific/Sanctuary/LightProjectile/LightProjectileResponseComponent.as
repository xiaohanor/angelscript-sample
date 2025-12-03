
event void FLightProjectileHitSignature(FLightProjectileHitData HitData);

class ULightProjectileResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Response")
	FLightProjectileHitSignature OnHit;
}