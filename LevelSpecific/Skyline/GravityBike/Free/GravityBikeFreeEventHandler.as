 struct FGravityBikeFreeOnGroundImpactEventData
 {
	UPROPERTY()
	FVector GroundImpactPoint;

	UPROPERTY()
	FVector GroundNormal;

	UPROPERTY()
	float ImpactStrength;
 }

struct FGravityBikeFreeOnWallImpactEventData
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	float ImpactStrength;
}

struct FGravityBikeFreeJumpEventData
{
	UPROPERTY()
	bool bHasGroundImpact = false;

	UPROPERTY()
	FVector GroundImpactPoint;

	UPROPERTY()
	FVector GroundNormal;
}

struct FGravityBikeFreeInitialDamageEventData
{
	UPROPERTY()
	float DamageFraction;
}

struct FGravityBikeFreeUpdateDamageEventData
{
	UPROPERTY()
	float DamageFraction;
}
 
 UCLASS(Abstract)
 class UGravityBikeFreeEventHandler : UHazeEffectEventHandler
 {
	UPROPERTY()
	AGravityBikeFree GravityBike = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMount() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForwardStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForwardEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDriftStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDriftEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoostStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoostRefill() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoostEnd() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundImpact(FGravityBikeFreeOnGroundImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeaveGround() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWallImpact(FGravityBikeFreeOnWallImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleForceFeedbackStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrottleForceFeedbackEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJump(FGravityBikeFreeJumpEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponPickupPickedUp() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponFire() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponFireNoCharge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInitialDamage(FGravityBikeFreeInitialDamageEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUpdateDamage(FGravityBikeFreeUpdateDamageEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyHealed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode() {}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetMountedPlayer() const
	{
		return GravityBike.GetDriver();
	}

	UFUNCTION(BlueprintPure) const
	float GetThrottle() const
	{
		return GravityBike.Input.Throttle;
	}
 
	UFUNCTION()
	void PlayBikeFrameFF() const	
	{
		FHazeFrameForceFeedback FFF;

		float FFMin = 0.0;
		float FFMax = 1.0;

		float FreqMin = 12.0;
		float FreqMax = 20.0;
		float Freq = Math::Lerp(FreqMin, FreqMax, GetThrottle());
		float Throttle = Math::Lerp(FFMin, FFMax, GetThrottle());

		if (GravityBike.IsKartDrifting())
			FFF.LeftMotor += Throttle * 0.4; // 0.2

//		FFF.RightTrigger = (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * GetThrottle() * GetThrottle() * 0.2;
//		FFF.LeftMotor += (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * Throttle * Math::Abs(Math::Min(GravityBike.Input.Steering, 0.0));
//		FFF.RightMotor += (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * Throttle * Math::Abs(Math::Max(GravityBike.Input.Steering, 0.0));
//		FFF.RightMotor += (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * Throttle * Math::Abs(Math::Max(GravityBike.Input.Steering, 0.0));

//		FFF.LeftTrigger += (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * Throttle * Math::Abs(Math::Min(GravityBike.Input.Steering, 0.0));
//		FFF.RightTrigger += (Math::Sin(Time::GameTimeSeconds * Freq * 2.0 * PI) + 1.0) * 0.5 * Throttle * Math::Abs(Math::Max(GravityBike.Input.Steering, 0.0));

//		FFF.LeftTrigger += Throttle * 0.5 * Math::Abs(Math::Min(GravityBike.Input.Steering, 0.0));
//		FFF.RightTrigger += Throttle * 0.5 * Math::Abs(Math::Max(GravityBike.Input.Steering, 0.0));

		FFF.RightTrigger += Throttle * 0.5 * Math::Abs(GravityBike.Input.Steering) * (GravityBike.IsOnWalkableGround() ? 1.0 : 0.0);
//		FFF.RightMotor += Throttle * 0.5 * (GravityBike.IsOnWalkableGround() ? 1.0 : 0.2);

		GetMountedPlayer().SetFrameForceFeedback(FFF, 0.8);
	}
 }