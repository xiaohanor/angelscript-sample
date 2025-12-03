class USpinningWorldZoeCameraCapability : UHazePlayerCapability
{
	USpinningWorldMioComponent MioComp;
    UCameraUserComponent CameraUser;

	FHazeAcceleratedVector AccVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MioComp = USpinningWorldMioComponent::Get(Game::GetMio());
        CameraUser = UCameraUserComponent::Get(Player);
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
        Player.ApplyCameraSettings(MioComp.Settings.CameraSettings, 0.5, this, SubPriority = 60);

		AccVector.Value = Player.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
        Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(!MioComp.Settings.bUseFollowCam)
			return;

		FVector ForwardOnPlane = Player.ActorForwardVector.VectorPlaneProject(MioComp.SmoothWorldRotation.UpVector);
		AccVector.AccelerateTo(ForwardOnPlane.GetSafeNormal(), 1.0 / MioComp.Settings.FollowCamSpeed, DeltaTime);
		CameraUser.SetDesiredRotation(FRotator::MakeFromXZ(AccVector.Value, MioComp.SmoothWorldRotation.UpVector), this);
	}
}

