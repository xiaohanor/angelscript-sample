// This file is an exact copy of the normal one shot interaction actor except for the interaction component being a custom one and the interaction events being custom to work for this actor.
event void FTundraShapeshiftingOneShotActorEvent(AHazePlayerCharacter Player, ATundraShapeshiftingOneShotInteractionActor Interaction);

/**
 * A simple one-shot animation interaction actor that can be placed in the level.
 *
 * The player can interact, plays an animation, and then exits the interaction automatically.
 */
UCLASS(HideCategories = "Interaction Movement Debug Rendering Collision HLOD LOD Cooking Input Actor Replication WorldPartition DataLayers")
class ATundraShapeshiftingOneShotInteractionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UTundraShapeshiftingOneShotInteractionComponent Interaction;

	UPROPERTY(DefaultComponent)
	UHazeEffectEventHandlerComponent EffectEventHandler;

	/* Executed when the interaction first triggers. */
    UPROPERTY(Category = "One Shot Interaction")
    FTundraShapeshiftingOneShotActorEvent OnOneShotActivated;

	/* Executed when the player has left the interaction. */
    UPROPERTY(Category = "One Shot Interaction")
    FTundraShapeshiftingOneShotActorEvent OnOneShotFinished;

    /* Executed when the one shot animation for this interaction has finished blending in. */
    UPROPERTY(Category = "One Shot Interaction")
    FTundraShapeshiftingOneShotActorEvent OnOneShotBlendedIn;

    /* Executed when the one shot animation for this interaction has finished playing and has started blending out. */
    UPROPERTY(Category = "One Shot Interaction")
    FTundraShapeshiftingOneShotActorEvent OnOneShotBlendingOut;

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
		Interaction.OnOneShotBlendedIn.AddUFunction(this, n"HandleOneShotBlendedIn");
		Interaction.OnOneShotBlendingOut.AddUFunction(this, n"HandleOneShotBlendingOut");
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent OneShotInteraction, AHazePlayerCharacter Player)
	{
		OnOneShotFinished.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent OneShotInteraction, AHazePlayerCharacter Player)
	{
		OnOneShotActivated.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleOneShotBlendingOut(AHazePlayerCharacter Player,
	                                      UOneShotInteractionComponent OneShotInteraction)
	{
		OnOneShotBlendingOut.Broadcast(Player, this);
	}

	UFUNCTION()
	private void HandleOneShotBlendedIn(AHazePlayerCharacter Player,
	                                    UOneShotInteractionComponent OneShotInteraction)
	{
		OnOneShotBlendedIn.Broadcast(Player, this);
	}
};