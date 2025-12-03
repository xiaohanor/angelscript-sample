event void FCentipedeProjectileImpactSignature(FVector ImpactDirection, float Force);
event void FCentipedeWaterBeginOverlap(UActorComponent OverlappedComponent);
event void FCentipedeWaterEndOverlap(UActorComponent OverlappedComponent);

class UCentipedeProjectileResponseComponent : UActorComponent
{
	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FCentipedeProjectileImpactSignature OnImpact;

	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FCentipedeWaterBeginOverlap OnWaterBeginOverlap;

	UPROPERTY(Category = "Response", Meta = (NotBlueprintCallable))
	FCentipedeWaterEndOverlap OnWaterEndOverlap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void ProjectileImpact(FVector ImpactDirection, float Force)
	{
		OnImpact.Broadcast(ImpactDirection, Force);
	}

	UFUNCTION(BlueprintCallable)
	void WaterBeginOverlap(UActorComponent OverlappedComponent)
	{
		OnWaterBeginOverlap.Broadcast(OverlappedComponent);
	}

	UFUNCTION(BlueprintCallable)
	void WaterEndOverlap(UActorComponent OverlappedComponent)
	{
		OnWaterEndOverlap.Broadcast(OverlappedComponent);
	}
};