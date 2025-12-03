struct FOnBattlefieldMissileImpactEffectParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UBattlefieldMissileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MissileImpact(FOnBattlefieldMissileImpactEffectParams Params) {}
} 