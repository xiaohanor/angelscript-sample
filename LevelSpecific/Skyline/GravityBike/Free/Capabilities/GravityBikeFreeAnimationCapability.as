class UGravityBikeFreeAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeAnimation);

	default TickGroup = EHazeTickGroup::LastMovement;

	AGravityBikeFree GravityBike;
	FQuat PreviousRotation = FQuat::Identity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
	}

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
		PreviousRotation = GravityBike.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GravityBike.AnimationData.SpeedAlpha = Math::GetPercentageBetweenClamped(
			GravityBike.Settings.MinimumSpeed,
			GravityBike.Settings.MaxSpeed,
			GravityBike.MoveComp.GetForwardSpeed()
		);

		float MaxTurn = Math::DegreesToRadians(GravityBike.Settings.FastMaxSteeringAngleDeg);
		MaxTurn = Math::Max(UGravityBikeFreeKartDriftSettings::GetSettings(GravityBike).GroundTurnMaxAmount, MaxTurn);

		FQuat DeltaRotation = GravityBike.ActorQuat * PreviousRotation.Inverse();
		const float AngularSpeed = DeltaRotation.GetTwistAngle(GravityBike.ActorUpVector) / DeltaTime;
		GravityBike.AnimationData.AngularSpeedAlpha = Math::Lerp(-1, 1, Math::GetPercentageBetweenClamped(-MaxTurn, MaxTurn, AngularSpeed));

		PreviousRotation = GravityBike.ActorQuat;
	}
}