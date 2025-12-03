UCLASS(Abstract)
class UIslandBeamTurretronProjectileEventHandler : UHazeEffectEventHandler
{	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FIslandBeamTurretronProjectileOnImpactEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDamage(FIslandBeamTurretronProjectileOnPlayerDamageEventData Data) {}
}


struct FIslandBeamTurretronProjectileOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FIslandBeamTurretronProjectileOnImpactEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FIslandBeamTurretronProjectileOnPlayerDamageEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactDirection;
	
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter HitPlayer;

	FIslandBeamTurretronProjectileOnPlayerDamageEventData(FVector InImpactLocation, FVector InImpactDirection, AHazePlayerCharacter InHitPlayer)
	{
		ImpactLocation = InImpactLocation;
		ImpactDirection = InImpactDirection;
		HitPlayer = InHitPlayer;
	}
}

