class USanctuaryLavamoleAutoDamageCapability : UHazeCapability
{
	AAISanctuaryLavamole Mole;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(LavamoleTags::LavaMole);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	float RandomWhackTime = 0.0;
	UHazeActionQueueComponent ActionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		ActionComp = UHazeActionQueueComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SanctuaryCentipedeDevToggles::Mole::AutoTakeDamage.IsEnabled())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < RandomWhackTime)
			return false;
		if (Mole.bIsUnderground)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RandomWhackTime = Math::RandRange(5, 15);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DebugWhackaMole();
	}

	void DebugWhackaMole()
	{
		const int WhackTimesDeath = 3;
		float Damage = 1.0 / Math::TruncToFloat(WhackTimesDeath +1);
		if (Mole.WhackedTimes < WhackTimesDeath)
		{
			Mole.HealthComp.TakeDamage(Damage, EDamageType::Default, Mole);
			if (Mole.HasControl())
			{
				ActionComp.Empty();
				ActionComp.Capability(USanctuaryLavamoleActionWhackedCapability, FSanctuaryLavamoleActionWhackedData());
				ActionComp.Capability(USanctuaryLavamoleActionDigDownCapability, FSanctuaryLavamoleActionDigDownData());
			}
			//ActionComp.ActionQueue.Queue(FSanctuaryLavamoleActionScaredData());
		}
		else if (Mole.WhackedTimes == WhackTimesDeath)
		{
			Mole.WhackedTimes++;
			float Diff = Mole.HealthComp.GetCurrentHealth() - 0.01;
			Mole.HealthComp.TakeDamage(Diff, EDamageType::Default, Mole);
			if (Mole.HasControl())
			{
				ActionComp.Empty();
				ActionComp.Capability(USanctuaryLavamoleActionSplitCapability, FSanctuaryLavamoleActionSplitData());
			}
		}
	}
};