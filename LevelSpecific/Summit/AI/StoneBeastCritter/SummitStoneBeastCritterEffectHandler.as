struct FOnStoneCritterSpawnParams
{
	UPROPERTY()
	FVector SpawnLocation;

	FOnStoneCritterSpawnParams(FVector _SpawnLocation)
	{
		SpawnLocation = _SpawnLocation;
	}
}

struct FOnStoneCritterDamageParams
{
	UPROPERTY()
	FVector HitDirection;

	FOnStoneCritterDamageParams(FVector HitDir)
	{
		HitDirection = HitDir;
	}
}

struct FOnStoneCritterHitPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FOnStoneCritterHitPlayerParams(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}

UCLASS(Abstract)
class USummitStoneBeastCritterEffectHandler : UHazeEffectEventHandler
{
	//When landing from the air
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FOnStoneCritterDamageParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttackStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttackLunge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttackRecover() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHitPlayer(FOnStoneCritterHitPlayerParams Params) {}
}