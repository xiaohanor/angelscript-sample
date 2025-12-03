event void SkylineBossTankAutoCannonProjectileResponseComponentSignature(FHitResult HitResult, FVector Velocity);

class USkylineBossTankAutoCannonProjectileResponseComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bProjectileStopping = true;

	UPROPERTY()
	SkylineBossTankAutoCannonProjectileResponseComponentSignature OnProjectileImpact;
}