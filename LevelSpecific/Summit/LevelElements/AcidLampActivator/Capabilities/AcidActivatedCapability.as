class UAcidActivatedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	AAcidActivator Activator;
	bool bEventAdded;
	bool bActionCompleted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Activator = Cast<AAcidActivator>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Activator.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		//THIS NEEDS TO ACCOUNT FOR RESETTING A TIMER VARIABLE EXTERNALLY AND READING FROM THAT
		if (Activator.bIsReactivatable)
		{
			if (Activator.TimeSinceLastHit >= Activator.ActivateDuration)
				return true;

			return false;
		}

		if (ActiveDuration > Activator.ActivateDuration && !Activator.bWaitForActionCompleted)
			return true;

		if (Activator.bWaitForActionCompleted && bActionCompleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Activator.bWaitForActionCompleted)
		{
			if (!bEventAdded)
			{
				bEventAdded = true;
				Activator.ActivatorActor.OnSummitActivatorActorCompletedAction.AddUFunction(this, n"OnSummitActivatorActorCompletedAction");
			}
			bActionCompleted = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Activator.StopActivator();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Activator.TimeSinceLastHit += DeltaTime;
	}
	
	UFUNCTION()
	private void OnSummitActivatorActorCompletedAction()
	{
		bActionCompleted = true;
	}
};