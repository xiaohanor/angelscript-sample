UCLASS(Abstract)
class ASkippingStones : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent StonePileRoot;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = InteractionComp)
	UArrowComponent ArrowComp;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(this);
		Timer::SetTimer(this, n"OnInteractionEndTimeout", 0.5);
	}

	UFUNCTION()
	private void OnInteractionEndTimeout()
	{
		InteractionComp.Enable(this);
	}
};