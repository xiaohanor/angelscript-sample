
event void FThreeShotActorEvent(AHazePlayerCharacter Player, AThreeShotInteractionActor Interaction);

/**
 * A simple one-shot animation interaction actor that can be placed in the level.
 *
 * The player can interact, plays an animation, and then exits the interaction automatically.
 */
UCLASS(HideCategories = "Interaction Movement Debug Rendering Collision HLOD LOD Cooking Input Actor Replication WorldPartition DataLayers", Meta = (HighlightPlacement))
class AThreeShotInteractionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UThreeShotInteractionComponent Interaction;

	UPROPERTY(DefaultComponent)
	UHazeEffectEventHandlerComponent EffectEventHandler;

	/* Executed when the interaction first triggers. */
    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotActivated;

	/* Executed when the player has left the interaction. */
    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotFinished;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotEnterBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotEnterBlendingOut;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotMHBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotMHBlendingOut;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotExitBlendedIn;

    UPROPERTY(Category = "Three Shot Interaction")
    FThreeShotActorEvent OnThreeShotExitBlendingOut;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		EHazePlayer Player = EHazePlayer::Mio;
		if(Interaction.UsableByPlayers == EHazeSelectPlayer::Zoe)
			Player = EHazePlayer::Zoe;

		CreatePlayerEditorVisualizer(Interaction, Player, FTransform::Identity);
		CreateInteractionEditorVisualizer(Interaction, Interaction.UsableByPlayers);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		Interaction.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");

		Interaction.OnEnterBlendedIn.AddUFunction(this, n"HandleEnterBlendedIn");
		Interaction.OnEnterBlendingOut.AddUFunction(this, n"HandleEnterBlendingOut");
		Interaction.OnMHBlendedIn.AddUFunction(this, n"HandleMHBlendedIn");
		Interaction.OnMHBlendingOut.AddUFunction(this, n"HandleMHBlendingOut");
		Interaction.OnExitBlendedIn.AddUFunction(this, n"HandleExitBlendedIn");
		Interaction.OnExitBlendingOut.AddUFunction(this, n"HandleExitBlendingOut");
	}

	UFUNCTION()
	private void HandleExitBlendingOut(AHazePlayerCharacter Player,
	                                   UThreeShotInteractionComponent ThreeShotInteraction)
	{
		OnThreeShotExitBlendingOut.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleExitBlendedIn(AHazePlayerCharacter Player,
	                                 UThreeShotInteractionComponent ThreeShotInteraction)
	{
		OnThreeShotExitBlendedIn.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleMHBlendingOut(AHazePlayerCharacter Player,
	                                 UThreeShotInteractionComponent ThreeShotInteraction)
	{
		OnThreeShotMHBlendingOut.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleMHBlendedIn(AHazePlayerCharacter Player,
	                               UThreeShotInteractionComponent ThreeShotInteraction)
	{
		OnThreeShotMHBlendedIn.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleEnterBlendingOut(AHazePlayerCharacter Player,
	                                    UThreeShotInteractionComponent ThreeShotInteraction)
	{
		OnThreeShotEnterBlendingOut.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleEnterBlendedIn(AHazePlayerCharacter Player,
	                                  UThreeShotInteractionComponent ThreeShotInteraction)
	{
		OnThreeShotEnterBlendedIn.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent ThreeShotInteraction, AHazePlayerCharacter Player)
	{
		OnThreeShotFinished.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent ThreeShotInteraction, AHazePlayerCharacter Player)
	{
		OnThreeShotActivated.Broadcast(Player, this);
	}
};