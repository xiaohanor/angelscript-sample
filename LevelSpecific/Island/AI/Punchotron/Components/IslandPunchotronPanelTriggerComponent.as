class UIslandPunchotronPanelTriggerComponent : UActorComponent
{
	bool bIsOnPanel = false; // For controlling behaviour on panels in arena fight.

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Arena fight panel triggers
		UHazeTeam PanelTriggers = HazeTeam::GetTeam(n"AITriggerTeam");
		if (PanelTriggers != nullptr)
		{
			TArray<AHazeActor> Members = PanelTriggers.GetMembers();
			for (AHazeActor Member : Members)
			{
				AAITrigger Trigger = Cast<AAITrigger>(Member);
				if (Trigger == nullptr)
					continue;
				Trigger.OnTriggerEnter.AddUFunction(this, n"OnTriggerEnter");
				Trigger.OnTriggerExit.AddUFunction(this, n"OnTriggerExit");
			}
		}
	}

	UFUNCTION()
	private void OnTriggerEnter(AHazeActor Actor)
	{
		bIsOnPanel = true;
	}

	UFUNCTION()
	private void OnTriggerExit(AHazeActor Actor)
	{
		bIsOnPanel = false;
	}
};