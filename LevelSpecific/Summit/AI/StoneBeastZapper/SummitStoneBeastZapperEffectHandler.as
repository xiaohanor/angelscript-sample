UCLASS(Abstract)
class USummitStoneBeastZapperEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeflectedHit() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLightningImpact(FSummitStoneBeastZapperLightningImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphing(FSummitStoneBeastZapperStartTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedBeamAttack(FSSummitStoneBeastZapperBeamData Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedBeamAttack() {}
}

struct FSummitStoneBeastZapperLightningImpactParams
{
	UPROPERTY()
	FVector Location;
}

struct FSSummitStoneBeastZapperBeamData
{
	FSSummitStoneBeastZapperBeamData(USummitStoneBeastZapperBeamComponent InBeamComp)
	{
		BeamComponent = InBeamComp;
	}

	UPROPERTY(BlueprintReadOnly)
	USummitStoneBeastZapperBeamComponent BeamComponent;
}

struct FSummitStoneBeastZapperStartTelegraphingParams
{
	FSummitStoneBeastZapperStartTelegraphingParams(USceneComponent Component)
	{
		AttachComponent = Component;
	}

	UPROPERTY()
	USceneComponent AttachComponent;
}