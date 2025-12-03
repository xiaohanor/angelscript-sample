UCLASS(Abstract)
class USplitTraversalPushableTreeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFalling() {}
}

class ASplitTraversalPushableTree2 : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UThreeShotInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsAxisRotateComponent FantasyRotateComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	USceneComponent FantasyFocusComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	USceneComponent MashLocation;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ScifiRotateComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRotateComp)
	USceneComponent ScifiFocusComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	UCameraShakeForceFeedbackComponent FantasyCSFFComp;
	
	UPROPERTY(DefaultComponent, Attach = ScifiRotateComp)
	UCameraShakeForceFeedbackComponent ScifiCSFFComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	USceneComponent FantasytHandIKLeft;

	UPROPERTY(DefaultComponent, Attach = FantasyRotateComp)
	USceneComponent FantasyHandIKRight;

	UPROPERTY(EditAnywhere)
	float PushForce = 400.0;

	UPROPERTY()
	FButtonMashSettings MashSettings;

	UPROPERTY()
	FOnButtonMashCompleted OnCompleted;

	UPROPERTY()
	UNiagaraSystem ScifiExplosionSystem;

	UPROPERTY()
	UNiagaraSystem FantasyExplosionSystem;

	UPROPERTY()
	UAnimSequence StruggleAnim;

	UPROPERTY()
	UAnimSequence MhAnim;

	UPROPERTY()
	UAnimSequence SuccessAnim;

	UPROPERTY()
	ULocomotionFeatureTreePush Feature;

	UPROPERTY(EditAnywhere)
	FApplyPointOfInterestSettings POIsettings;

	UPROPERTY(EditInstanceOnly)
	TArray<APerchSpline> PerchSplineActors;
	
	private UButtonMashComponent ButtonMashComp = nullptr;

	FHazeAnimationDelegate OnSuccessBlendedOut;

	bool bMashCompleted = false;

	bool bInteracting = false;

	bool bPushing = false;

	float PrevFrameMashProgress = 0.0;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintPure)
	float GetButtonMashProgression() const
	{
		if (ButtonMashComp != nullptr)
			return ButtonMashComp.GetButtonMashProgress(this);

		return 0;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();	

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"HandleInteractionStopped");
		InteractionComp.OnCancelPressed.AddUFunction(this, n"HandleCancelPressed");
		OnCompleted.BindUFunction(this, n"HandleMashCompleted");

		FantasyRotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleMaxConstrainHit");
		for (auto PerchSplineActor : PerchSplineActors)
			PerchSplineActor.AddActorDisable(this);

		OnSuccessBlendedOut.BindUFunction(this, n"HandleSuccessAnimationFinished");
	}

	UFUNCTION()
	private void HandleMaxConstrainHit(float Strength)
	{
		FantasyCSFFComp.ActivateCameraShakeAndForceFeedback();
		ScifiCSFFComp.ActivateCameraShakeAndForceFeedback();

		FantasyCSFFComp.ForceFeedbackScale = FantasyCSFFComp.ForceFeedbackScale * 0.5;
		FantasyCSFFComp.ForceFeedbackScale = FantasyCSFFComp.CameraShakeScale * 0.5;

		ScifiCSFFComp.ForceFeedbackScale = ScifiCSFFComp.ForceFeedbackScale * 0.5;
		ScifiCSFFComp.ForceFeedbackScale = ScifiCSFFComp.CameraShakeScale * 0.5;
	}

	UFUNCTION()
	private void HandleCancelPressed(AHazePlayerCharacter InteractingPlayer,
	                                 UThreeShotInteractionComponent Interaction)
	{
		InteractingPlayer.StopButtonMash(this);
		bInteracting = false;
	}

	UFUNCTION()
	private void HandleMashCompleted()
	{
		bMashCompleted = true;
		InteractionComp.KickAnyPlayerOutOfInteraction();
		InteractionComp.Disable(this);
		FantasyRotateComp.SpringStrength = 0.0;
		
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ScifiExplosionSystem, ScifiRotateComp.WorldLocation);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(FantasyExplosionSystem, FantasyRotateComp.WorldLocation);

		FHazePointOfInterestFocusTargetInfo POIinfo;
		POIinfo.SetFocusToComponent(ScifiFocusComp);
		Game::Mio.ApplyPointOfInterest(this, POIinfo, POIsettings, 2.0);

		Timer::SetTimer(this, n"DelayedPerchEnable", 1.0);

		USplitTraversalPushableTreeEventHandler::Trigger_OnStartFalling(this);

		PushFinished();
	}

	UFUNCTION()
	private void DelayedPerchEnable()
	{
		for (auto PerchSplineActor : PerchSplineActors)
			PerchSplineActor.RemoveActorDisable(this);
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter InteractingPlayer)
	{
		Player = InteractingPlayer;

		MashSettings.WidgetAttachComponent = MashLocation;
		Player.StartButtonMash(MashSettings, this, OnCompleted);
		
		ButtonMashComp = UButtonMashComponent::Get(Player);
		
		Player.AddLocomotionFeature(Feature, this);
	//	StopPushing();

		bInteracting = true;
	}

	UFUNCTION()
	private void HandleInteractionStopped(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter InteractingPlayer)
	{
		Player.StopButtonMash(this);

		if (!bMashCompleted)
			ForceComp.Force = FVector::ZeroVector;

		bInteracting = false;

		Player.StopSlotAnimationByAsset(MhAnim);
		Player.StopSlotAnimationByAsset(StruggleAnim);

		Player.RemoveLocomotionFeature(Feature, this);
	}



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ScifiRotateComp.SetRelativeRotation(FantasyRotateComp.RelativeRotation);
		
		if (!bMashCompleted && bInteracting)
		{	
			if (bPushing)
				ForceComp.Force = FVector::ForwardVector * ButtonMashComp.GetButtonMashProgress(this) * PushForce;
			else
				ForceComp.Force = FVector::ZeroVector;

			if (ButtonMashComp.GetButtonMashProgress(this) > PrevFrameMashProgress && !bPushing)
				StartPushing();

			if (ButtonMashComp.GetButtonMashProgress(this) < PrevFrameMashProgress && bPushing)
				StopPushing();

			PrevFrameMashProgress = ButtonMashComp.GetButtonMashProgress(this);

			Player.RequestLocomotion(n"TreePush", this);
		}	
	}

	private void StartPushing()
	{
		bPushing = true;
		//Player.PlaySlotAnimation(Animation = StruggleAnim, bLoop = true);
	}

	private void StopPushing()
	{
		bPushing = false;
		//Player.StopSlotAnimationByAsset(StruggleAnim);
	}

	private void PushFinished()
	{
		bPushing = false;
		Player.StopAllSlotAnimations();
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnSuccessBlendedOut, SuccessAnim, false);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION()
	private void HandleSuccessAnimationFinished()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}
};