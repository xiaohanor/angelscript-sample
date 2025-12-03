class USkylineClubDancingCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineClubDancing");
	default CapabilityTags.Add(n"SkylineClubDancingCamera");

	default TickGroup = EHazeTickGroup::Gameplay;

	USkylineClubDancingUserComponent UserComp;
	UCameraUserComponent CameraUserComp;

	float LastCameraInputTime = 0.0;
	float Delay = 3.0;
	FHazeAcceleratedFloat AccFloat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineClubDancingUserComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsDancing)
			return false;

		if (Time::GameTimeSeconds < LastCameraInputTime + Delay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsDancing)
			return true;

		if (Time::GameTimeSeconds < LastCameraInputTime + Delay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.bIsCameraSpinning = true;
		Player.ApplyCameraSettings(UserComp.CameraSettings, 6.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bIsCameraSpinning = false;
		Player.ClearCameraSettingsByInstigator(this, OverrideBlendTime = 2.0);
		AccFloat.SnapTo(0.0, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccFloat.AccelerateTo(UserComp.CameraRotationSpeed, 6.0, DeltaTime);

		FVector ViewDirection = Player.ViewRotation.ForwardVector.RotateAngleAxis(-AccFloat.Value * DeltaTime, Player.ActorUpVector);

		ViewDirection = ViewDirection.RotateAngleAxis(-AccFloat.Value * DeltaTime, Player.ViewRotation.RightVector).ConstrainToCone(-Player.ActorUpVector, Math::DegreesToRadians(90.0));

		CameraUserComp.SetDesiredRotation(ViewDirection.Rotation(), this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!Player.CameraInput.IsNearlyZero())
			LastCameraInputTime = Time::GameTimeSeconds;
	}
};