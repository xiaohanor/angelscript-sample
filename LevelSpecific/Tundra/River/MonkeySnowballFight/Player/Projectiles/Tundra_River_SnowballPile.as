UCLASS(Abstract)
class ATundra_River_SnowballPile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent SnowballPile;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;

	UPROPERTY(DefaultComponent)
	UOneShotInteractionComponent OneShotInteractComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ATundra_River_Snowball> SnowballClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OneShotInteractComp.OnOneShotBlendingOut.AddUFunction(this, n"OnInteractionCompleted");
		// InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
	}

	UFUNCTION()
	private void OnInteractionCompleted(AHazePlayerCharacter Player,
	                                    UOneShotInteractionComponent Interaction)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);

		ATundra_River_Snowball Snowball = SpawnActor(SnowballClass);
		auto SnowballComp = UTundra_River_PlayerSnowballComponent::Get(Player);
		SnowballComp.Snowball = Snowball;
		Snowball.MakeNetworked(SnowballComp, SnowballComp.SnowBallID);
		SnowballComp.SnowBallID++;
		Snowball.OwningPlayer = Player;
		Snowball.SetActorControlSide(Player);
		Snowball.AttachToComponent(Player.Mesh, n"RightAttach");

		// Audio 
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Snowball.OwningPlayer, Snowball);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);

		ATundra_River_Snowball Snowball = SpawnActor(SnowballClass);
		auto SnowballComp = UTundra_River_PlayerSnowballComponent::Get(Player);
		SnowballComp.Snowball = Snowball;
		Snowball.MakeNetworked(SnowballComp, SnowballComp.SnowBallID);
		SnowballComp.SnowBallID++;
		Snowball.OwningPlayer = Player;
		Snowball.SetActorControlSide(Player);
		Snowball.AttachToComponent(Player.Mesh, n"RightAttach");

		// Audio 
		EffectEvent::LinkActorToReceiveEffectEventsFrom(Snowball.OwningPlayer, Snowball);
	}
};