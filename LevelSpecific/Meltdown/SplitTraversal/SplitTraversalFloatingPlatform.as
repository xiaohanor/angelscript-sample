class ASplitTraversalFloatingPlatform : AWorldLinkDoubleActor
{
	//UPROPERTY(DefaultComponent)
	//UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsTranslateComponent FantasyTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FantasyTranslateComp)
	UFauxPhysicsAxisRotateComponent FantasyRotateComp1;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp1)
	UFauxPhysicsAxisRotateComponent FantasyRotateComp2;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp1)
	UNiagaraComponent SplashEffect;
	default SplashEffect.bAutoActivate=false;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent SciFiTranslateRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	USplitTraversalTransferFauxWeightComponent TransferWeightComp;
	default TransferWeightComp.TransferToActor = this;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		auto DraggableParent = Cast<ASplitTraversalDraggableFloatingPlatform>(AttachParentActor);
		if (DraggableParent != nullptr)
			DraggableParent.InteractionComp.AttachToComponent(FantasyRotateComp2, NAME_None, EAttachmentRule::KeepWorld);

		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundimpact");
	}

	UFUNCTION()
	private void OnGroundimpact(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
			SplashEffect.SetAbsolute(bNewAbsoluteRotation = true);
			SplashEffect.Activate(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SciFiTranslateRoot.SetRelativeLocation(FantasyTranslateComp.RelativeLocation);
		SciFiTranslateRoot.SetWorldRotation(FantasyRotateComp2.WorldRotation);
	}
};