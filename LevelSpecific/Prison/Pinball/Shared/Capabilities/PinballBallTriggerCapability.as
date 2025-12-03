class UPinballBallTriggerCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 0;

	UPinballBallComponent BallComp;

	TArray<UPinballTriggerComponent> CurrentTriggers;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CurrentTriggers.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector Delta = Owner.ActorVelocity * DeltaTime;
		const FVector NextLocation = Owner.ActorLocation + Delta;

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.DirectionalArrow("Trigger Delta", Owner.ActorLocation, Delta);
#endif

		for(int i = CurrentTriggers.Num() - 1; i >= 0; i--)
		{
			UPinballTriggerComponent TriggerComp = CurrentTriggers[i];
			if(TriggerComp.IsInTrigger(Owner.ActorLocation, NextLocation))
				continue;

			CurrentTriggers.RemoveAtSwap(i);
			TriggerComp.OnBallPass.Broadcast(TriggerComp, BallComp, false);

#if !RELEASE
			TemporalLog.Status(f"Ball Exit! {TriggerComp.Name}", FLinearColor::Purple);
#endif
		}

		for(UPinballTriggerComponent TriggerComp : Pinball::GetManager().Triggers)
		{
			// Early cull
			if(TriggerComp.WorldLocation.Distance(Owner.ActorLocation) > 10000)
				continue;

			if(TriggerComp.CanBeInsideTrigger() && CurrentTriggers.Contains(TriggerComp))
				continue;

			if(!TriggerComp.IsInTrigger(Owner.ActorLocation, NextLocation))
				continue;

			if(TriggerComp.CanBeInsideTrigger())
			{
				TriggerComp.OnBallPass.Broadcast(TriggerComp, BallComp, true);
				CurrentTriggers.Add(TriggerComp);

#if !RELEASE
				TemporalLog.Status(f"Ball Enter! {TriggerComp.Name}", FLinearColor::LucBlue);
#endif
			}
			else
			{
				const bool bEnterTrigger = Delta.DotProduct(TriggerComp.UpVector) > 0;
				TriggerComp.OnBallPass.Broadcast(TriggerComp, BallComp, bEnterTrigger);

#if !RELEASE
				if(bEnterTrigger)
					TemporalLog.Status(f"Ball Enter! {TriggerComp.Name}", FLinearColor::LucBlue);
				else
					TemporalLog.Status(f"Ball Exit! {TriggerComp.Name}", FLinearColor::Purple);
#endif
			}
		}
	}
};