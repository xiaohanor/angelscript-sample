UCLASS(Abstract)
class UIslandAttackShipBeamProjectileEventHandler : UHazeEffectEventHandler
{	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FIslandAttackShipBeamProjectileOnImpactEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDamage(FIslandAttackShipBeamProjectileOnPlayerDamageEventData Data) {}
}


struct FIslandAttackShipBeamProjectileOnImpactEventData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FIslandAttackShipBeamProjectileOnImpactEventData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}

struct FIslandAttackShipBeamProjectileOnPlayerDamageEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector ImpactLocation;

	UPROPERTY(BlueprintReadOnly)
	FVector ImpactDirection;
	
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter HitPlayer;

	FIslandAttackShipBeamProjectileOnPlayerDamageEventData(FVector InImpactLocation, FVector InImpactDirection, AHazePlayerCharacter InHitPlayer)
	{
		ImpactLocation = InImpactLocation;
		ImpactDirection = InImpactDirection;
		HitPlayer = InHitPlayer;
	}
}

