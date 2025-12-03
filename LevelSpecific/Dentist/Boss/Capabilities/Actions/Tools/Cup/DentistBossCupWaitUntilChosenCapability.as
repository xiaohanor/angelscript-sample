struct FDentistBossCupWaitUntilChosenDeactivationParams
{
	bool bChoseCorrectCup;
}

class UDentistBossCupWaitUntilChosenCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossCupManager CupManager;

	UDentistBossTargetComponent TargetComp;
	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);
		CupManager = TListedActors<ADentistBossCupManager>().Single;

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistBossCupWaitUntilChosenDeactivationParams& Params) const
	{
		if(CupManager.ChosenCup.IsSet())
		{
			if(CupManager.ChosenCup.Value.RestrainedPlayer.IsSet())
				Params.bChoseCorrectCup = true;
			else
				Params.bChoseCorrectCup = false;

			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentist.bCupChosen = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistBossCupWaitUntilChosenDeactivationParams Params)
	{
		Dentist.bCupChosen = true;
	}
};