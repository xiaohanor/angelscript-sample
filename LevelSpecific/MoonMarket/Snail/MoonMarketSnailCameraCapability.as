class UMoonMarketSnailCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	UMoonMarketRideSnailComponent SnailComp;

	FRotator InitialRotation;

	float Duration = 1;
	FQuat RotationDelta;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SnailComp = UMoonMarketRideSnailComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SnailComp.Snail == nullptr)
			return false;

		if(Time::GetGameTimeSince(SnailComp.RideStartTime) > Duration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SnailComp.Snail == nullptr)
			return true;

		if(ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraControl, this);
		auto CameraComp = UCameraUserComponent::Get(Player);
		InitialRotation = CameraComp.ViewRotation;
		FRotator TargetRotation = CameraComp.ViewRotation;
		TargetRotation.Yaw = SnailComp.Snail.ActorForwardVector.Rotation().Yaw;
		CameraComp.SetDesiredRotation(TargetRotation, this);
		RotationDelta = FQuat::GetDelta(TargetRotation.Quaternion(), InitialRotation.Quaternion());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto CameraComp = UCameraUserComponent::Get(Player);

		float Alpha = Math::Saturate(ActiveDuration / Duration);
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);

		FQuat Delta = FQuat::Slerp(RotationDelta, FQuat::Identity, Alpha);

		FRotator TargetRotation = CameraComp.ViewRotation;
		TargetRotation.Yaw = SnailComp.Snail.ActorForwardVector.Rotation().Yaw;

		CameraComp.SetDesiredRotation(TargetRotation + Delta.Rotator(), this);
	}
};