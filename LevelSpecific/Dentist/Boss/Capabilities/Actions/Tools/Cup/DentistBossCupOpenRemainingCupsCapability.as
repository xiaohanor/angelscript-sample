struct FDentistBossCupOpenRemainingCupsActivationParams
{
	
}

class UDentistBossCupOpenRemainingCupsCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossCupOpenRemainingCupsActivationParams Params;

	ADentistBoss Dentist;
	ADentistBossCupManager CupManager;
	UDentistBossTargetComponent TargetComp;

	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		CupManager = TListedActors<ADentistBossCupManager>().Single;
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossCupOpenRemainingCupsActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TArray<ADentistBossToolCup> Cups;
		Cups.Add(Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupLeft]));
		Cups.Add(Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupMiddle]));
		Cups.Add(Cast<ADentistBossToolCup>(Dentist.Tools[EDentistBossTool::CupRight]));

		for(auto Cup : Cups)
		{
			if(Cup.bHasBeenOpened)
				continue;
			
			Cup.FlingAway(-Dentist.ActorRightVector.ConstrainToPlane(FVector::UpVector));
		}

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};