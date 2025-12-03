 struct FGravityBikeSplineOnGroundImpactEventData
 {
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float ImpactStrength;
 }
 
 struct FGravityBikeSplineOnWallImpactEventData
 {
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	float ImpactStrength;
 }

 struct FGravityBikeSplineJumpEventData
{
	UPROPERTY()
	bool bHasGroundImpact = false;

	UPROPERTY()
	FVector GroundImpactPoint;

	UPROPERTY()
	FVector GroundNormal;
}
 
 UCLASS(Abstract)
 class UGravityBikeSplineEventHandler : UHazeEffectEventHandler
 {
	UPROPERTY(BlueprintReadOnly)
	AGravityBikeSpline GravityBike = nullptr;

	UPROPERTY(BlueprintReadWrite)
	UNiagaraComponent WallSparks;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMount() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForwardStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForwardEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoostStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoostEnd() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundImpact(FGravityBikeSplineOnGroundImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeaveGround() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWallImpact(FGravityBikeSplineOnWallImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterTrailStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWaterTrailEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJump(FGravityBikeSplineJumpEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInitialDamage(FGravityBikeFreeInitialDamageEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUpdateDamage(FGravityBikeFreeUpdateDamageEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyHealed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityChangeStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityChangeStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleForceFeedbackStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleForceFeedbackStart() {}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetDriver() const
	{
		return GravityBike.GetDriver();
	}
	
	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPassenger() const
	{
		return GravityBike.GetPassenger();
	}

	UFUNCTION(BlueprintPure) const
	float GetImmediateThrottle() const
	{
		return GravityBike.Input.GetImmediateThrottle();
	}

	UFUNCTION(BlueprintPure) const
	float GetStickyThrottle() const
	{
		return GravityBike.Input.GetStickyThrottle();
	}
 }