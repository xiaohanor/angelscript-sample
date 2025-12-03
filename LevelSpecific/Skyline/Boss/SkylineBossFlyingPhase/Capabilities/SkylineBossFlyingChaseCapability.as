class USkylineBossFlyingChaseCapability : USkylineBossFlyingPhaseChildCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	AHazePlayerCharacter PlayerToChase;
	float LastTargetUpdateTime;
	const float TargetUpdateFrequency = 1;

	FHazeAcceleratedVector CurrentVelocity;
	FHazeAcceleratedFloat Yaw;


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerToChase = Game::GetClosestPlayer(Owner.ActorLocation);
		LastTargetUpdateTime = Time::GetGameTimeSeconds();
		Yaw.Value = Owner.ActorRotation.Yaw;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSeconds() - LastTargetUpdateTime > TargetUpdateFrequency)
		{
			PlayerToChase = Game::GetClosestPlayer(Owner.ActorLocation);
			LastTargetUpdateTime = Time::GetGameTimeSeconds();
		}

		FVector DirToPlayer = PlayerToChase.ActorLocation - Owner.ActorLocation;
		DirToPlayer.Z = (PlayerToChase.ActorLocation.Z + SkylineBoss::ChaseHeightOffset) - Owner.ActorLocation.Z;
		DirToPlayer.Normalize();

		
		float Dist = PlayerToChase.ActorLocation.DistXY(Owner.ActorLocation);
		if(Dist > SkylineBoss::HoverRange)
		{
			Yaw.AccelerateTo(DirToPlayer.Rotation().Yaw, SkylineBoss::TurnDuration, DeltaTime);
			Owner.SetActorRotation(FRotator(0, Yaw.Value, 0));
		}

		CurrentVelocity.AccelerateTo(DirToPlayer, SkylineBoss::ChaseDrag, DeltaTime);
		Owner.AddActorWorldOffset(CurrentVelocity.Value * SkylineBoss::ChaseSpeed * DeltaTime);

	}
};