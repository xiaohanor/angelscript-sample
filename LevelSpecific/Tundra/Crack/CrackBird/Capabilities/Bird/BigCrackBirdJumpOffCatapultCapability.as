class UBigCrackBirdJumpOffCatapultCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	FTraversalTrajectory JumpTrajectory;

	FRotator TargetRotation;

	float RecoilTime;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Bird.bHopOffCatapult)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(RecoilTime <= 0)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RecoilTime = 0.16;
		Bird.DetachFromActor();
		Bird.InteractComp.Disable(Bird);
		Bird.bAttached = false;

		const float Gravity = 7;
		const float Height = 600;

		JumpTrajectory.LaunchLocation = Owner.ActorLocation;
		JumpTrajectory.LandLocation = Bird.CurrentNest.BirdLandPoint.WorldLocation;
		JumpTrajectory.Gravity = FVector::DownVector * Gravity;
		JumpTrajectory.LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(JumpTrajectory.LaunchLocation, JumpTrajectory.LandLocation, Gravity, Height);
		TargetRotation = FRotator::MakeFromXZ((Bird.CurrentNest.BirdLandPoint.WorldLocation - Bird.ActorLocation).GetSafeNormal(), FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Bird.SetActorLocation(Bird.CurrentNest.BirdLandPoint.WorldLocation);
		Bird.bHopOffCatapult = false;
		Bird.bRunningAway = true;
		Bird.CurrentNest.Bird = nullptr;
		Bird.CurrentNest = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Bird.ActorLocation.Z > Bird.CurrentNest.BirdLandPoint.WorldLocation.Z)
		{
			float JumpSpeed = 30;
			FVector Location = JumpTrajectory.GetLocation(ActiveDuration * JumpSpeed);
			Bird.SetActorLocation(Location);
			Bird.SetActorRotation(Math::RInterpConstantTo(Bird.ActorRotation, TargetRotation, DeltaTime, 300));
		}
		else
		{
			RecoilTime -= DeltaTime;
		}
	}
};