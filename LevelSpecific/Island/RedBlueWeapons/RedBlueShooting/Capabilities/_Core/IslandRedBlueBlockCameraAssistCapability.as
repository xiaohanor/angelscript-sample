class UIslandRedBlueBlockCameraAssistCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	UCameraUserComponent CameraUserComp;
	float TimeOfStopHavingBlockCameraAssistInstigator = -100.0;
	bool bHasBlockCameraAssistInstigator = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bNewHasBlockCameraAssistInstigator = WeaponUserComp.HasBlockCameraAssistanceInstigator();
		if(!bNewHasBlockCameraAssistInstigator && bHasBlockCameraAssistInstigator)
		{
			TimeOfStopHavingBlockCameraAssistInstigator = Time::GetGameTimeSeconds();
		}

		bHasBlockCameraAssistInstigator = bNewHasBlockCameraAssistInstigator;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bHasBlockCameraAssistInstigator)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bHasBlockCameraAssistInstigator && Time::GetGameTimeSince(TimeOfStopHavingBlockCameraAssistInstigator) > 0.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraChaseAssistanceActivation, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistanceActivation, this);
	}
}