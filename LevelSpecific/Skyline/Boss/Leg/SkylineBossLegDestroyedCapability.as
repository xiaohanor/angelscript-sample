class USkylineBossLegDestroyedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineBossLeg Leg;
	UBasicAIHealthComponent HealthComp;
	UBasicAIHealthBarComponent HealthBarComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Leg = Cast<ASkylineBossLeg>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Leg);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Leg);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HealthComp.IsDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HealthComp.IsDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.TriggerStartDying();

		if (!HasControl()) 
			HealthComp.RemoteDie();

		HealthComp.OnDie.Broadcast(Leg);

		HealthBarComp.SetPlayerVisibility(EHazeSelectPlayer::None);

		FSkylineBossLegEventData LegEventData;
		LegEventData.Leg = Leg;
		LegEventData.Leg.GetFootLocationAndRotation(LegEventData.FootLocation, LegEventData.FootRotation);
		USkylineBossEventHandler::Trigger_LegDamaged(Leg.Boss, LegEventData);

		Leg.BP_OnLegDamaged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Leg.Boss == nullptr)
			return;
		
		HealthBarComp.SetPlayerVisibility(EHazeSelectPlayer::Both);

		FSkylineBossLegEventData LegEventData;
		LegEventData.Leg = Leg;
		LegEventData.Leg.GetFootLocationAndRotation(LegEventData.FootLocation, LegEventData.FootRotation);
		USkylineBossEventHandler::Trigger_LegRestored(Leg.Boss, LegEventData);

		Leg.BP_OnLegRestored();
	}
};