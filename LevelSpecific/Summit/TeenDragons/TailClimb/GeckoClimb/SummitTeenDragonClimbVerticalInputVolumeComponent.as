class USummitTeenDragonClimbVerticalInputVolumeComponent : UActorComponent
{
	APlayerTrigger Trigger;

	TOptional<UPlayerTailTeenDragonComponent> TailDragonCompInsideVolume;

	bool bHasFlippedInput = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger = Cast<APlayerTrigger>(Owner);
		devCheck(Trigger != nullptr, f"{this.Name} was not attached to a player trigger, it will not work then");

		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		Trigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;

		TailDragonCompInsideVolume.Set(DragonComp);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if(bHasFlippedInput)
		{
			TailDragonCompInsideVolume.Value.VerticalInputInstigators.RemoveSingleSwap(this);
			bHasFlippedInput = false;
		}

		TailDragonCompInsideVolume.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if(TailDragonCompInsideVolume.IsSet())
		{
			if(TailDragonCompInsideVolume.Value.IsClimbing()
			&& !bHasFlippedInput)
			{
				TailDragonCompInsideVolume.Value.VerticalInputInstigators.AddUnique(this);
				bHasFlippedInput = true;
			}
			else if(!TailDragonCompInsideVolume.Value.IsClimbing()
			&& bHasFlippedInput)
			{
				TailDragonCompInsideVolume.Value.VerticalInputInstigators.RemoveSingleSwap(this);
				bHasFlippedInput = false;
			}
		}
	}
};