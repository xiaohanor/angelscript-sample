UCLASS(Abstract)
class USkylineFlyingCarEnemyBurstFireProjectileEventHandler : UHazeEffectEventHandler
{	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))	
	void OnImpact(FSkylineFlyingCarEnemyBurstFireProjectileOnImpactEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDamage(FSkylineFlyingCarEnemyBurstFireProjectileOnPlayerDamageEventData Data) {}
}


struct FSkylineFlyingCarEnemyBurstFireProjectileOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FSkylineFlyingCarEnemyBurstFireProjectileOnImpactEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FSkylineFlyingCarEnemyBurstFireProjectileOnPlayerDamageEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactDirection;
	
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter HitPlayer;

	FSkylineFlyingCarEnemyBurstFireProjectileOnPlayerDamageEventData(FVector InImpactLocation, FVector InImpactDirection, AHazePlayerCharacter InHitPlayer)
	{
		ImpactLocation = InImpactLocation;
		ImpactDirection = InImpactDirection;
		HitPlayer = InHitPlayer;
	}
}

