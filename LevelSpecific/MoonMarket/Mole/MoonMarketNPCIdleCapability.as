struct FMoonMarketNPCIdleCapabilityActivatedParams
{
	UMoonMarketNPCIdleSplinePoint IdlePoint;
}

class UMoonMarketNPCIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	UMoonMarketNPCWalkComponent WalkComp;

	UMoonMarketNPCIdleSplinePoint IdlePoint;

	float IdleTime;
	bool bReachedTargetRotation = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WalkComp = UMoonMarketNPCWalkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMoonMarketNPCIdleCapabilityActivatedParams& Params) const
	{
		if(!WalkComp.bIdling)
			return false;

		if(WalkComp.PreviousIdlePoint == nullptr)
			return false;

		Params.IdlePoint = WalkComp.PreviousIdlePoint;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= IdleTime)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMoonMarketNPCIdleCapabilityActivatedParams Params)
	{
		IdlePoint = Params.IdlePoint;
		WalkComp.PreviousIdlePoint = IdlePoint;
		WalkComp.bIdling = true;
		Owner.SetActorVelocity(FVector::ZeroVector);
		bReachedTargetRotation = false;
		IdleTime = Math::RandRange(5, 15);
		if(WalkComp.PreviousIdlePoint.MoleToTalkTo != nullptr)
		{
			WalkComp.PreviousIdlePoint.MoleToTalkTo.bAlwaysTalking = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(IdlePoint.MoleToTalkTo != nullptr)
		{
			IdlePoint.MoleToTalkTo.bAlwaysTalking = false;
		}

		WalkComp.bIdling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bReachedTargetRotation)
			return;

		FRotator NewRotation = Math::RInterpConstantTo(Owner.ActorRotation, IdlePoint.WorldRotation, DeltaTime, 150);
		if(Math::IsNearlyEqual(NewRotation.Yaw, IdlePoint.WorldRotation.Yaw))
			bReachedTargetRotation = true;

		Owner.SetActorRotation(NewRotation);
	}
};