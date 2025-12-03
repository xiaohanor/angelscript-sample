class USkylineBossTankFollowTargetCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankMovement);
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankFollowTarget);
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankChase);

	AHazeActor Target;

	USkylineBossTankFollowTargetComponent FollowTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		FollowTargetComp = USkylineBossTankFollowTargetComponent::Get(BossTank);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
//		if (FollowTargetComp.CurrentTarget == nullptr)
//			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (FollowTargetComp.CurrentTarget == nullptr)
//			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
//		Debug::DrawDebugPoint(FollowTargetComp.GetTarget(), 50.0, FLinearColor::Red, 0.0);

		FVector ToTarget = (FollowTargetComp.GetTarget() - BossTank.ActorLocation).ConstrainToPlane(FVector::UpVector);

		if (ToTarget.Size() < FollowTargetComp.TargetRadius * 1.0)
			FollowTargetComp.FindNewTarget(BossTank.ConstraintRadiusOrigin.ActorTransform, BossTank.ConstraintRadius);

		// FVector Direction = ToTarget.SafeNormal;
		float Distance = ToTarget.Size();

		// float DistanceBasedSpeed = Math::GetMappedRangeValueClamped(FVector2D(5000.0, 20000.0), FVector2D(BossTank.MaxSpeed, BossTank.MaxSpeed * 1.8), Distance);

		float TurnSpeed = BossTank.MaxTurnSpeed * (1.0 - Math::Clamp(Math::NormalizeToRange(Distance, FollowTargetComp.TargetRadius, 20000.0), 0.0, 0.6));
				
		FVector TurnTorque = BossTank.ActorForwardVector.CrossProduct(ToTarget.SafeNormal) * TurnSpeed;

		BossTank.Torque += TurnTorque;
		BossTank.Force += BossTank.ActorForwardVector.VectorPlaneProject(FVector::UpVector) * BossTank.MaxSpeed;
	}

	void TickRemote(float DeltaTime)
	{
	}
}