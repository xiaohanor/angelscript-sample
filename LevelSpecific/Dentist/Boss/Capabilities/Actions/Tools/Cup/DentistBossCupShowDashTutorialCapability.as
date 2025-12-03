class UDentistBossCupShowDashTutorialCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADentistBoss Dentist;
	ADentistBossCupManager CupManager;

	UDentistBossSettings Settings;
	
	AHazePlayerCharacter TutorialPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		CupManager = Dentist.CupManager;

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TutorialPlayer = CupManager.PlayerInCup.OtherPlayer;

		auto Cups = TListedActors<ADentistBossToolCup>().Array;
		for(auto Cup : Cups)
		{
			TutorialPlayer.ShowTutorialPromptWorldSpace(Settings.DashToOpenCupPrompt, CupManager, Cup.RootComponent, Settings.DashToOpenPromptOffset, 0.0);
		}

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}
};