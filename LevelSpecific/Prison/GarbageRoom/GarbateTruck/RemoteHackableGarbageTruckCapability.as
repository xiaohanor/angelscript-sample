class URemoteHackableGarbageTruckCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AGarbageTruck GarbageTruck;

	bool bTutorialCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		GarbageTruck = Cast<AGarbageTruck>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bTutorialCompleted = false;

		FTutorialPrompt OpenHatchesPrompt;
		OpenHatchesPrompt.Action = ActionNames::PrimaryLevelAbility;
		OpenHatchesPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
		OpenHatchesPrompt.Text = GarbageTruck.OpenHatchesTutorialText;

		Player.ShowTutorialPromptWorldSpace(OpenHatchesPrompt, this, GarbageTruck.TruckRoot, FVector(-100.0, 0.0, 0.0), -150.0);

		GarbageTruck.BottomLeftHatch.OverrideNetworkSyncRate(EHazeCrumbSyncRate::High);
		GarbageTruck.BottomRightHatch.OverrideNetworkSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);

		GarbageTruck.BottomLeftHatch.OverrideNetworkSyncRate(EHazeCrumbSyncRate::Standard);
		GarbageTruck.BottomRightHatch.OverrideNetworkSyncRate(EHazeCrumbSyncRate::Standard);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (GarbageTruck.bLockPlayersIn)
			return;

		if(HasControl())
		{
			if (!bTutorialCompleted && GarbageTruck.BottomRightHatch.RelativeRotation.Roll <= -45.0)
				CrumbCompleteTutorial();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCompleteTutorial()
	{
		if(bTutorialCompleted)
			return;

		bTutorialCompleted = true;
		Player.RemoveTutorialPromptByInstigator(this);
	}
}