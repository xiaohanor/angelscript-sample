class UStoneBossQTEWeakpointSwordReleaseCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"StoneBossQTEWeakpoint");
	default CapabilityTags.Add(n"StoneBossQTEWeakpointRelease");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;

	default DebugCategory = n"Weakpoint";

	UStoneBossQTEWeakpointPlayerComponent WeakpointComp;
	UStoneBossQTEPlayerTestInputComponent TestInputComp;
	UDragonSwordUserComponent DragonSwordComp;

	FHazeAcceleratedTransform AccSwordTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
		TestInputComp = UStoneBossQTEPlayerTestInputComponent::GetOrCreate(Player);
		DragonSwordComp = UDragonSwordUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return false;

		if (IsActioning(ActionNames::PrimaryLevelAbility) || TestInputComp.IsActioning(StoneBossQTEWeakpoint::TestPrimaryAction))
			return false;

		if (WeakpointComp.DrawBackAlpha > WeakpointComp.DrawBackAlphaThreshold)
			return false;

		if (WeakpointComp.Weakpoint != nullptr && WeakpointComp.Weakpoint.HasBeenDestroyed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WeakpointComp.Weakpoint == nullptr)
			return true;

		if (IsActioning(ActionNames::PrimaryLevelAbility) || TestInputComp.IsActioning(StoneBossQTEWeakpoint::TestPrimaryAction))
			return true;

		if (WeakpointComp.Weakpoint != nullptr && WeakpointComp.Weakpoint.HasBeenDestroyed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (DragonSwordComp == nullptr)
			DragonSwordComp = UDragonSwordUserComponent::Get(Player);

		WeakpointComp.DrawBackAlpha = 0.0;

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		TutorialPrompt.Text = NSLOCTEXT("StoneBossQTE", "HoldRT", "Hold");
		if (Player.IsMio())
			TutorialPrompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
		TutorialPrompt.AlternativeDisplayType = ETutorialAlternativePromptDisplay::Keyboard_LeftRight;

		FVector Offset;
		if (Player.IsMio())
			Offset = FVector(0, -40, 0);
		else
			Offset = FVector(0, 40, 0);

		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, WeakpointComp.DrawSwordInstigator, AttachOffset = FVector(0, 0, 176.0) + Offset);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(WeakpointComp.DrawSwordInstigator);
	}
};