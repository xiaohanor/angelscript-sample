// This capability will only run locally on magnet control side (robot's remote)
class UTazerBotLaunchBullshitNetworkCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ATazerBot TazerBot;

	FVector Velocity;
	FVector2D RandomTorque;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Network::IsGameNetworked())
			return false;

		if (!TazerBot.bLaunched)
			return false;

		if (TazerBot.bDestroyed)
			return false;

		if (!Drone::GetMagnetDronePlayer().HasControl())
			return false;

		if (TazerBot.IsAnyCapabilityActive(TazerBot::TazerBotLaunchCapability))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TazerBot.bLaunched)
			return true;

		if (TazerBot.bDestroyed)
			return true;

		if (TazerBot.IsAnyCapabilityActive(TazerBot::TazerBotLaunchCapability))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Velocity = TazerBot.CurrentLaunchParams.Impulse;
		RandomTorque = TazerBot.CurrentLaunchParams.RandomTorque;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TazerBot.MeshOffsetComponent.ResetOffsetWithLerp(this, Time::EstimatedCrumbRoundtripDelay);
	}

	// Rotation will be entirely different for both sides and there will be a snappy move
	// when this deactivates. But mäh...
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NetSpeedMultiplier = (Time::EstimatedCrumbReachedDelay / Math::Sqrt(Time::EstimatedCrumbRoundtripDelay));

		// Get location
		Velocity += TazerBot.MovementComponent.Gravity * DeltaTime * NetSpeedMultiplier;
		FVector NextLocation = TazerBot.MeshRoot.WorldLocation + Velocity * DeltaTime * NetSpeedMultiplier;

		// We know how far away target is, so we have air time
		// Rotate bot 360 degrees on its pitch axis
		FQuat MeshRotation;
		if (TazerBot.CurrentLaunchParams.IsTargetedLaunch())
		{
			float Progress = Math::Pow(Math::Saturate((ActiveDuration) / TazerBot.CurrentLaunchParams.Time), 2);
			MeshRotation = FQuat(TazerBot.ActorRightVector, PI * 2.0 * Progress) * TazerBot.ActorQuat;
		}
		else
		{
			// Add random rotation
			FQuat DeltaRotation = FQuat(-TazerBot.ActorRightVector, RandomTorque.X * DeltaTime);
			MeshRotation = DeltaRotation * TazerBot.MeshOffsetComponent.ComponentQuat;
		}

		// Snap to bullshit semi-predicted transform
		TazerBot.MeshOffsetComponent.SnapToTransform(this, FTransform(MeshRotation, NextLocation));
	}
}