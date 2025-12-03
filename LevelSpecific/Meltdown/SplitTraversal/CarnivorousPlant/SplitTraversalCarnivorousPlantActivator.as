UCLASS(Abstract)
class USplitTraversalCarnivorousPlantActivatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartInteract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopInteract() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivateBite() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLostTarget() {}
}

class ASplitTraversalCarnivorousPlantActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TutorialAttachComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UThreeShotInteractionComponent InteractComp;
	default InteractComp.InteractionCapability = n"SplitTraversalCarnivorousPlantActivatorCapability";

	UPROPERTY(DefaultComponent)
	UWidgetComponent WidgetComp;

	USplitTraversalCarnivorousPlantActivatorWidget Widget;

	UPROPERTY()
	UAnimSequence ActivateAnim;

	UPROPERTY(EditInstanceOnly)
	AActor CableActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike AlongCableTimeLike;
	default AlongCableTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalCarnivorousPlant2 Plant;

	UPROPERTY()
	FCarnivorousPlantTargetSignature OnActivated;

	UPROPERTY()
	FCarnivorousPlantTargetSignature OnReachedEnd;

	UPROPERTY()
	UAnimSequence ControlAnim;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	bool bCoolDown = false;

	AHazePlayerCharacter InteractingPlayer;

	bool bTargetLost = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Widget = Cast<USplitTraversalCarnivorousPlantActivatorWidget>(WidgetComp.Widget);
		Widget.Activator = this;

		Plant.OnRetract.AddUFunction(this, n"Reenable");
		Plant.OnTargetFound.AddUFunction(this, n"TargetFound");
		Plant.OnTargetLost.AddUFunction(this, n"LostTarget");

		SplineComp = Spline::GetGameplaySpline(CableActor, this);

		SetActorControlSide(Game::Mio);
	}

	UFUNCTION()
	private void LostTarget()
	{
		Widget.bShouldHaveTarget = false;
		BP_LostTarget();
		bCoolDown = true;

		USplitTraversalCarnivorousPlantActivatorEventHandler::Trigger_OnLostTarget(this);
	}

	UFUNCTION()
	void Activate()
	{
		bCoolDown = true;
		Widget.OnBite();
		OnActivated.Broadcast();

		USplitTraversalCarnivorousPlantActivatorEventHandler::Trigger_OnActivateBite(this);

		if (HasControl())
			Plant.Attack();
	}

	UFUNCTION()
	void Deactivate()
	{
		BP_Deactivated();
		InteractComp.KickAnyPlayerOutOfInteraction();
		InteractComp.Disable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_LostTarget(){}

	UFUNCTION()
	private void Reenable()
	{
		bCoolDown = false;
		Widget.EnableFollow();
	}

	UFUNCTION()
	private void TargetFound()
	{
		bCoolDown = false;
		Widget.TargetFound();
	}
};