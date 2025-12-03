event void FOnJackInteractionStarted(AHazePlayerCharacter Jack);

UCLASS(Abstract)
class ATitanic : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UThreeShotInteractionComponent RoseInteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UOneShotInteractionComponent JackInteractionComp;


	UPROPERTY()
	FOnJackInteractionStarted OnJackInteractionStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RoseInteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleRoseInteractionStarted");
		RoseInteractionComp.OnInteractionStopped.AddUFunction(this, n"HandleRoseInteractionStopped");
		JackInteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleJackInteractionStarted");

		JackInteractionComp.Disable(this);
	}


	UFUNCTION()
	private void HandleJackInteractionStarted(UInteractionComponent InteractionComponent,
	                                          AHazePlayerCharacter Player)
	{
		RoseInteractionComp.KickAnyPlayerOutOfInteraction();
		JackInteractionComp.KickAnyPlayerOutOfInteraction();
		JackInteractionComp.Disable(this);
		OnJackInteractionStarted.Broadcast(Player);
	}

	UFUNCTION()
	private void HandleRoseInteractionStarted(UInteractionComponent InteractionComponent,
	                                          AHazePlayerCharacter Player)
	{
		JackInteractionComp.Enable(this);
	}

	UFUNCTION()
	private void HandleRoseInteractionStopped(UInteractionComponent InteractionComponent,
	                                          AHazePlayerCharacter Player)
	{
		JackInteractionComp.Disable(this);
	}
};