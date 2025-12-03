event void FSanctuaryWeeperLightBirdSocket(ASanctuaryWeeperLightBird LightBird);


class ASanctuaryWeeperLightBirdSocket : AHazeActor
{
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperLightBirdSocket OnActivated;
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperLightBirdSocket OnDeactivated;




	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractComp;
	default InteractComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default InteractComp.InteractionCapability = n"SanctuaryWeeperLightBirdSocketCapability";

	UPROPERTY(DefaultComponent)
	USimplePlayerInputReceivingComponenent PlayerInputComp;
	default PlayerInputComp.PlayerInput = EHazePlayer::Mio;


	UPROPERTY(DefaultComponent)
	USanctuaryWeeperLightBirdResponseComponent LightBirdResponseComp;

	bool bIsInteracting;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		// LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsInteracting)	
			return;

		
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bIsInteracting = true;

		auto LightBirdUserComp = USanctuaryWeeperLightBirdUserComponent::Get(Player);
		LightBirdUserComp.LightBird.BlockCapabilities(CapabilityTags::Movement, this);
		LightBirdUserComp.LightBird.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Player.SmoothTeleportActor(ActorLocation + FVector(0, 0, -200), ActorRotation, this, 1.5);

		
		OnActivated.Broadcast(LightBirdUserComp.LightBird);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		bIsInteracting = false;

		auto LightBirdUserComp = USanctuaryWeeperLightBirdUserComponent::Get(Player);
		LightBirdUserComp.LightBird.UnblockCapabilities(CapabilityTags::Movement, this);
		LightBirdUserComp.LightBird.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		
		
		OnDeactivated.Broadcast(LightBirdUserComp.LightBird);

	}

	// UFUNCTION()
	// private void OnIlluminated(ASanctuaryWeeperLightBird LightBird)
	// {
	// 	if(!bIsInteracting)
	// 		return;
		
	// 	OnActivated.Broadcast(LightBird);
	// }

	// UFUNCTION()
	// private void OnUnilluminated(ASanctuaryWeeperLightBird LightBird)
	// {
	// 	if(!bIsInteracting)
	// 		return;

	// 	OnDeactivated.Broadcast(LightBird);
	// }
}