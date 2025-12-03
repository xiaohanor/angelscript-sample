event void FDarkProjectileHitSignature(FDarkProjectileHitData HitData);

class UDarkProjectileResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Response")
	FDarkProjectileHitSignature OnHit;
}