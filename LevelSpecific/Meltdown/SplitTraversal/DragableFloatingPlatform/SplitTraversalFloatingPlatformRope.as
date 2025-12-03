class ASplitTraversalFloatingPlatformRope : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UCableComponent FantasyCableComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UCableComponent ScifiCableComp;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalWaterBase WaterBase;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		InteractComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		FantasyCableComp.bAttachStart = false;
		ScifiCableComp.bAttachStart = false;

		InteractionComponent.Disable(this);

		// WaterBase.TranslateComp.MinY = -2100.0;
		// WaterBase.TranslateComp.MinX = -900.0;
	}
};