
class APerchPointActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	UPerchPointComponent PerchPointComp;
	default PerchPointComp.bAllowGrappleToPoint = false;
	default PerchPointComp.AdditionalGrappleRange = 0.0;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent EnterZone;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchPointDrawComponent DrawComp;
#endif

	UPROPERTY()
	FOnPlayerStartedPerchingOnPointEventSignature OnPlayerStartedPerchingEvent;
	UPROPERTY()
	FOnPlayerStoppedPerchingOnPointEventSignature OnPlayerStoppedPerchingEvent;
	UPROPERTY()
	FOnPlayerStartedPerchingOnPointEventSignature OnPlayerInitiatedJumpToEvent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!PerchPointComp.bAllowPerch)	
			EnterZone.DisableTrigger(this);

		PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"OnPlayerPerchedOnPoint");
		PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"OnPlayerStoppedPerchingOnPoint");
		PerchPointComp.OnPlayerInitiatedJumpToEvent.AddUFunction(this, n"OnPlayerInitiatedJumpTo");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	//Will enable point for whichever player is set by "UsableByPlayers"
	UFUNCTION(Category = "Perch Point Activation")
	void EnablePerchPoint(FInstigator Instigator)
	{
		if(PerchPointComp.bStartDisabled)
		{
			PerchPointComp.EnableAfterStartDisabled();
			PerchPointComp.bStartDisabled = false;
		}

		PerchPointComp.Enable(Instigator);

		if(PerchPointComp.bAllowPerch)
			EnterZone.EnableTrigger(Instigator);
	}

	//Will enable point for whichever player is referenced (will not affect other players access)
	UFUNCTION(Category = "Perch Point Activation")
	void EnablePerchPointForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
#if EDITOR			
			devCheck(Player.IsSelectedBy(PerchPointComp.UsableByPlayers),
				"Attempted to enable: " + Name + " For Player: " + Player.Name + " When that player is not set as usable for the actor");
#endif	

		if(PerchPointComp.bStartDisabled)
		{
			PerchPointComp.EnableAfterStartDisabled();
			PerchPointComp.bStartDisabled = false;

			DisablePerchPointForPlayer(Player.IsMio() ? Game::GetZoe() : Game::GetMio(), Instigator);
		}
		else
			PerchPointComp.EnableForPlayer(Player, Instigator);
	}

	/*
	 * Will Disable point for both players
	 */
	UFUNCTION(Category = "Perch Point Activation")
	void DisablePerchPoint(FInstigator Instigator)
	{
		PerchPointComp.Disable(Instigator);

		if(PerchPointComp.bAllowPerch)
			EnterZone.DisableTrigger(Instigator);
	}

	//Will disable point for whichever player is referenced (will not affect other players access)
	UFUNCTION(Category = "Perch Point Activation")
	void DisablePerchPointForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		PerchPointComp.DisableForPlayer(Player, Instigator);
	}

	UFUNCTION(Category = "Perch Point Activation")
	void EnablePerchingOnPoint(FInstigator Instigator)
	{
		PerchPointComp.bAllowPerch = true;
		EnterZone.EnableTrigger(Instigator);
	}

	UFUNCTION(Category = "Perch Point Activation")
	void DisablePerchingOnPoint(FInstigator Instigator)
	{
		PerchPointComp.bAllowPerch = false;
		EnterZone.DisableTrigger(Instigator);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerPerchedOnPoint(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		OnPlayerStartedPerchingEvent.Broadcast(Player, PerchPoint);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStoppedPerchingOnPoint(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchPoint);
	}

	UFUNCTION()
	private void OnPlayerInitiatedJumpTo (AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		OnPlayerInitiatedJumpToEvent.Broadcast(Player, PerchPoint);
	}
}