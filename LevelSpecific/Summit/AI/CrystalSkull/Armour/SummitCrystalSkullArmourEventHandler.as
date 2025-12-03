struct FSummitCrystalSkullArmourDestroyedParams
{
	UPROPERTY()
	FVector Location;
}
struct FSummitCrystalSkullArmourRegrowParams
{
	UPROPERTY()
	FVector Location;
}
struct FSummitCrystalSkullSmashShieldParams
{
	FSummitCrystalSkullSmashShieldParams(USummitCrystalSkullShieldComponent SmashShield)
	{
		Shield = SmashShield;
	}

	UPROPERTY()
	USummitCrystalSkullShieldComponent Shield;
}

UCLASS(Abstract)
class USummitCrystalSkullArmourEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed(FSummitCrystalSkullArmourDestroyedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRegrow(FSummitCrystalSkullArmourRegrowParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashShield(FSummitCrystalSkullSmashShieldParams Params) {}
}

