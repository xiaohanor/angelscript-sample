class USummitTeenDragonClimbRespawnZoneComponent : UActorComponent
{
	APlayerTrigger Trigger;

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
		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(ClimbComp == nullptr)
			return;
		
		ClimbComp.bForceRespawnOnWall = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(ClimbComp == nullptr)
			return;
		
		ClimbComp.bForceRespawnOnWall = false;
	}
};