class UTurnSegmentsZoeCameraCapability : UHazePlayerCapability
{
	UTurnSegmentsMioComponent MioComp;
	UTurnSegmentsMioDataComponent DataComp;
    UCameraUserComponent CameraUser;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        MioComp = UTurnSegmentsMioComponent::Get(Game::GetMio());
		DataComp = UTurnSegmentsMioDataComponent::Get(Game::GetMio());
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
    void TickActive(float DeltaTime)
    {
		auto ClimbComp = UPlayerPoleClimbComponent::Get(Player);
		if(ClimbComp.Data.ActivePole != nullptr)
		{
			if(DataComp.Settings.bAlignCameraWithWorldUpWhilePoleClimbing)
        		CameraUser.SetYawAxis(FVector::UpVector, this);
		}

		if(MioFullScreen::GetUseZoeInput())
		{
			CameraUser.SetDesiredRotation(FRotator::ZeroRotator, this);
		}
    }
}

