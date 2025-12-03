class USkylineInterfaceTriggerComponent : USkylineInterfaceComponent
{
	UPROPERTY(EditAnywhere)
	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		auto PlayerTrigger = Cast<APlayerTrigger>(Owner);

		if (PlayerTrigger != nullptr)
		{
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
			PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeave");
		}
		else
		{
			auto ActorTrigger = Cast<AActorTrigger>(Owner);
			if (ActorTrigger != nullptr)
			{
				ActorTrigger.OnActorEnter.AddUFunction(this, n"HandleActorEnter");
				ActorTrigger.OnActorLeave.AddUFunction(this, n"HandleActorLeave");	
			}
		}
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		TriggerActivate();

		if (bDoOnce)
			Unbind();
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		TriggerDeactivate();
	}

	UFUNCTION()
	private void HandleActorEnter(AHazeActor Actor)
	{
		TriggerActivate();

		if (bDoOnce)
			Unbind();
	}

	UFUNCTION()
	private void HandleActorLeave(AHazeActor Actor)
	{
		TriggerDeactivate();
	}

	void Unbind()
	{
		auto PlayerTrigger = Cast<APlayerTrigger>(Owner);

		if (PlayerTrigger != nullptr)
		{
			PlayerTrigger.OnPlayerEnter.Unbind(this, n"HandlePlayerEnter");
			PlayerTrigger.OnPlayerLeave.Unbind(this, n"HandlePlayerLeave");
		}
		else
		{
			auto ActorTrigger = Cast<AActorTrigger>(Owner);
			if (ActorTrigger != nullptr)
			{
				ActorTrigger.OnActorEnter.Unbind(this, n"HandleActorEnter");
				ActorTrigger.OnActorLeave.Unbind(this, n"HandleActorLeave");	
			}
		}		
	}
};