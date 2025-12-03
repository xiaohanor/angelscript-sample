struct FGravityBikeSplineEnforcerFireEventData
{
	UPROPERTY()
	float Range;
	
	UPROPERTY()
	FVector StartLocation;

	UPROPERTY()
	FVector StartDirection;

	UPROPERTY()
	FHitResult HitResult;
};

UCLASS(Abstract)
class UGravityBikeSplineEnforcerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeSplineEnforcer Enforcer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enforcer = Cast<AGravityBikeSplineEnforcer>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFire(FGravityBikeSplineEnforcerFireEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFireTraceImpact(FGravityBikeSplineEnforcerFireEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath() {}
};