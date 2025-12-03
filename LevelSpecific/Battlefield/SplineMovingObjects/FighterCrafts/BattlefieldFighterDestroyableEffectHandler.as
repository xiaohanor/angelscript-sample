struct FBattlefieldFighterHitParams
{
	UPROPERTY()
	FVector HitLocation;
}

struct FBattlefieldFighterCrashParams
{
	UPROPERTY()
	FVector CrashLocation;
}

UCLASS(Abstract)
class UBattlefieldFighterDestroyableEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFighterHit(FBattlefieldFighterHitParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFighterJetCrash(FBattlefieldFighterCrashParams Params) {}
}