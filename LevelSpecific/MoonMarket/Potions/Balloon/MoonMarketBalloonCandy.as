class AMoonMarketBalloonCandy : AMoonMarketInteractableActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(EditAnywhere)
	UHazeCapabilitySheet SheetToStartWhenConsumed;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		InteractComp.AddInteractionCondition(this, FInteractionCondition(this, n"CheckInteractionAvailable"));
	}

	UFUNCTION()
	private EInteractionConditionResult CheckInteractionAvailable(
	                                                              const UInteractionComponent InteractionComponent,
	                                                              AHazePlayerCharacter Player)
	{
		if(!UHazeMovementComponent::Get(Player).HasGroundContact())
			return EInteractionConditionResult::DisabledVisible;

		return EInteractionConditionResult::Enabled;
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		FMoonMarketBalloonCandyFormEventData Params;
		Params.Player = Player;
		UMoonMarketBalloonCandyFormEventHandler::Trigger_OnInteractionStarted(Player, Params);
		StopInteraction(Player);
	}
};