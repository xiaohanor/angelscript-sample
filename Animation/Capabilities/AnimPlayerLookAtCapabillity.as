class UAnimPlayerLookAtCapabillity : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AnimCameraLookAt");

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UHazeAnimPlayerLookAtComponent LookAtComp;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LookAtComp = UHazeAnimPlayerLookAtComponent::GetOrCreate(Player);
		LookAtComp.DisableCameraLookAt(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SceneView::IsFullScreen())
			return false;

		if (Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::ThirdPerson)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SceneView::IsFullScreen())
			return true;

		if (Player.GetCurrentGameplayPerspectiveMode() != EPlayerMovementPerspectiveMode::ThirdPerson)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LookAtComp.ClearDisabledCameraLookAt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LookAtComp.DisableCameraLookAt(this);
	}
};