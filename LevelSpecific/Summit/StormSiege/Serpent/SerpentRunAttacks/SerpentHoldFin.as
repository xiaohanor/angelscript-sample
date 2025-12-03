class ASerpentHoldFin : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractCompMio;
	default InteractCompMio.UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractCompZoe;
	default InteractCompZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractCompMio.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractCompMio.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractCompZoe.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		InteractCompZoe.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		DisableInteractions();
	}

	void EnableInteractions()
	{
		InteractCompMio.Enable(this);
		InteractCompZoe.Enable(this);
	}

	void DisableInteractions()
	{
		InteractCompMio.Disable(this);
		InteractCompZoe.Disable(this);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(InteractionComponent, NAME_None, EAttachmentRule::KeepWorld);
		Player.RootOffsetComponent.FreezeRelativeTransformAndLerpBackToParent(this, InteractionComponent, 0.5);
		Player.SetActorTransform(InteractionComponent.WorldTransform);
	}
}