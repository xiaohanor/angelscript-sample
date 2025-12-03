class UGravityBikeSplineEnemyTickTriggersCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp;
	UGravityBikeSplineEnemyHealthComponent HealthComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TriggerUserComp = UGravityBikeSplineEnemyTriggerUserComponent::Get(Owner);
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(HealthComp.IsDead())
			return false;

		if(HealthComp.IsRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(HealthComp.IsDead())
			return true;

		if(HealthComp.IsRespawning())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto& Trigger : TriggerUserComp.TriggerDistanceDatas)
		{
			if(!Trigger.bHasEntered && Trigger.TriggerComp.GetStartDistance() < TriggerUserComp.GetDistanceAlongSpline())
			{
				if(Trigger.TriggerComp.bUseEndExtent)
				{
					if(TriggerUserComp.GetDistanceAlongSpline() > Trigger.TriggerComp.GetEndDistance())
					{
						// We have gone completely past this trigger
						// Skip it!
						Trigger.bHasEntered = true;
						Trigger.bHasExited = true;
						continue;
					}
				}

				EnterTrigger(Trigger.TriggerComp, true);
				Trigger.bHasEntered = true;
			}

			if(Trigger.bHasEntered && Trigger.TriggerComp.bUseEndExtent)
			{
				if(!Trigger.bHasExited && Trigger.TriggerComp.GetEndDistance() < TriggerUserComp.GetDistanceAlongSpline())
				{
					ExitTrigger(Trigger.TriggerComp, true);
					Trigger.bHasExited = true;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto& Trigger : TriggerUserComp.TriggerDistanceDatas)
		{
			if(Trigger.bHasEntered && !Trigger.bHasExited)
			{
				ExitTrigger(Trigger.TriggerComp, false);
				Trigger.bHasExited = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto& Trigger : TriggerUserComp.TriggerDistanceDatas)
		{
			if(!Trigger.bHasEntered && Trigger.TriggerComp.GetStartDistance() < TriggerUserComp.GetDistanceAlongSpline())
			{
				EnterTrigger(Trigger.TriggerComp, false);
				Trigger.bHasEntered = true;
			}

			if(Trigger.bHasEntered && Trigger.TriggerComp.bUseEndExtent)
			{
				if(!Trigger.bHasExited && Trigger.TriggerComp.GetEndDistance() < TriggerUserComp.GetDistanceAlongSpline())
				{
					ExitTrigger(Trigger.TriggerComp, false);
					Trigger.bHasExited = true;
				}
			}
		}
	}

	private void EnterTrigger(UGravityBikeSplineEnemyTriggerComponent TriggerComp, bool bIsTeleport)
	{
		TriggerComp.OnEnemyEnter(TriggerUserComp, bIsTeleport);
	}

	private void ExitTrigger(UGravityBikeSplineEnemyTriggerComponent TriggerComp, bool bIsTeleport)
	{
		// Some triggers don't need exits, saves on network bandwidth
		if(!TriggerComp.bImplementsExit)
			return;

		TriggerComp.OnEnemyExit(TriggerUserComp, bIsTeleport);
	}
};