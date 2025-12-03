UCLASS(Abstract)
class USplitTraversalTapEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeverPulled() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPotImpact(FSplitTraversalWaterPotSpawnerEventParams Params) {}
}

class ASplitTraversalTap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent WaterVFXComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeverPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent WaterTriggerComp;

	UPROPERTY()
	FHazeTimeLike PullLeverTimeLike;
	default PullLeverTimeLike.UseSmoothCurveZeroToOne();
	default PullLeverTimeLike.Duration = 1.0;

	UPROPERTY()
	FHazeTimeLike LeverRetractTimeLike;
	default PullLeverTimeLike.UseSmoothCurveZeroToOne();
	default PullLeverTimeLike.Duration = 1.0;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	UAnimSequence PullAnim;

	ASplitTraversalWaterPot WaterPot;

	AHazePlayerCharacter InteractingPlayer;

	FHazeAnimationDelegate OnActivateBlendOut;

	bool bPouring = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeverRetractTimeLike.BindUpdate(this, n"LeverRetractTimeLikeUpdate");
		LeverRetractTimeLike.BindFinished(this, n"LeverRetractTimeLikeFinished");

		InteractionComp.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");

		WaterTriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"WatterTriggerOverlap");
		WaterTriggerComp.OnComponentEndOverlap.AddUFunction(this, n"WatterTriggerEndOverlap");
		
		OnActivateBlendOut.BindUFunction(this, n"HandleAnimationCompleted");

		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), OnActivateBlendOut, PullAnim, false);

		//USplitTraversalTapEventHandler::Trigger_OnLeverPulled(this);

		BP_PullLever();

		QueueComp.Idle(0.5);
		QueueComp.Event(this, n"AttachLever");
		QueueComp.Idle(0.3);
		QueueComp.Event(this, n"DetachLever");
	}

	UFUNCTION(BlueprintEvent)
	private void BP_PullLever(){}

	UFUNCTION()
	private void AttachLever()
	{
		LeverPivotComp.AttachToComponent(Game::Zoe.Mesh, n"Align", EAttachmentRule::SnapToTarget);
		BP_ActivateWater();
		bPouring = true;

		USplitTraversalTapEventHandler::Trigger_OnLeverPulled(this);
	}

	UFUNCTION()
	private void DetachLever()
	{
		LeverPivotComp.AttachToComponent(Root, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		//LeverPivotComp.AttachToComponent(Root, NAME_None, EAttachmentRule::SnapToTarget);

		BP_DeactivateWater();

		bPouring = false;

		if (WaterPot != nullptr && Game::Zoe.HasControl())
			WaterPot.CrumbFilled(WaterTriggerComp.WorldLocation);

		USplitTraversalTapEventHandler::Trigger_OnPotImpact(this, FSplitTraversalWaterPotSpawnerEventParams(WaterPot));
	}

	UFUNCTION()
	private void WatterTriggerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                  const FHitResult&in SweepResult)
	{
		if(OtherActor == Cast<ASplitTraversalWaterPot>(OtherActor))
		{
			WaterPot = Cast<ASplitTraversalWaterPot>(OtherActor);
		}
	}


	UFUNCTION()
	private void WatterTriggerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if(OtherActor == WaterPot)
		{
			WaterPot = nullptr;
		}
	}

	UFUNCTION()
	private void HandleAnimationCompleted()
	{
		InteractionComp.Disable(this);
		InteractionComp.KickAnyPlayerOutOfInteraction();


		LeverRetractTimeLike.PlayFromStart();
	}
	
	UFUNCTION()
	private void LeverRetractTimeLikeUpdate(float CurrentValue)
	{
		LeverPivotComp.SetRelativeRotation(FRotator(Math::Lerp(-50.0, 0.0, CurrentValue), 0.0, 0.0));
	}

	UFUNCTION()
	private void LeverRetractTimeLikeFinished()
	{
		InteractionComp.Enable(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ActivateWater(){}

	UFUNCTION(BlueprintEvent)
	private void BP_DeactivateWater(){}
};