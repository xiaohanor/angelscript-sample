event void FIslandTimeLikeBaseSignature();

class AIslandTimeLikeBaseActor : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachablePanelComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UBoxComponent KillCollider;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UCameraShakeForceFeedbackComponent StartCamShakeFFComp;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel OptionalPanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadPanelListener ListenerRef;

	UPROPERTY(EditInstanceOnly)
	AIslandGrenadeLockListener GrenadeListenerRef;

	UPROPERTY(EditInstanceOnly)
	AIslandSidescrollerShootableScrewListener ScrewListenerRef;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;
	
	// UPROPERTY(EditAnywhere) Add feature to attach panel to actor
	// bool bAttachPanel;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FIslandTimeLikeBaseSignature OnActivated;

	UPROPERTY()
	FIslandTimeLikeBaseSignature OnReachedDestination;

	UPROPERTY()
	bool bIsPlaying;
	bool bMovingBack;

	bool bIsDisabled;

	UPROPERTY(EditAnywhere)
	bool bKillableCollider = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		KillCollider.OnComponentBeginOverlap.AddUFunction(this, n"HandleKillOverlap");

		if (PanelRef != nullptr)
		{
			PanelRef.OnOvercharged.AddUFunction(this, n"HandleOvercharge");
			PanelRef.OnReset.AddUFunction(this, n"HandleReset");
		}
		if (OptionalPanelRef != nullptr)
		{
			OptionalPanelRef.OnOvercharged.AddUFunction(this, n"HandleOvercharge");
			OptionalPanelRef.OnReset.AddUFunction(this, n"HandleReset");
		}
		if (ListenerRef != nullptr)
		{
			ListenerRef.OnCompleted.AddUFunction(this, n"HandleOvercharge");
			ListenerRef.OnReset.AddUFunction(this, n"HandleReset");
			return;
		}
		if (GrenadeListenerRef != nullptr)
		{
			GrenadeListenerRef.OnCompleted.AddUFunction(this, n"HandleOvercharge");
			GrenadeListenerRef.OnReset.AddUFunction(this, n"HandleReset");
			return;
		}

		if (ScrewListenerRef != nullptr)
		{
			ScrewListenerRef.OnCompleted.AddUFunction(this, n"HandleOvercharge");
			ScrewListenerRef.OnReset.AddUFunction(this, n"HandleReset");
			return;
		}

	}

	UFUNCTION()
	private void HandleKillOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                               UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                               const FHitResult&in SweepResult)
	{
		if (!bKillableCollider)
			return;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		// Player.DamagePlayerHealth(1.0);
		Player.KillPlayer(DeathEffect = DeathEffect);
	}

	UFUNCTION()
	void HandleOvercharge()
	{
		Start();
	}

	UFUNCTION()
	void HandleReset()
	{
		Reverse();
	}

	UFUNCTION()
	void Start()
	{
		if (bIsDisabled)
			return;

		bMovingBack = false;
		MoveAnimation.Play();
		OnActivated.Broadcast();

		StartCamShakeFFComp.ActivateCameraShakeAndForceFeedback();

		UIslandTimeLikeBaseActorEffectHandler::Trigger_OnStartMovingForward(this);
	}

	UFUNCTION()
	void Reverse()
	{
		if (bIsDisabled)
			return;

		bMovingBack = true;
		MoveAnimation.Reverse();

		UIslandTimeLikeBaseActorEffectHandler::Trigger_OnStartMovingBackward(this);
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;

		bIsPlaying = true;
		
		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		if(bMovingBack)
			UIslandTimeLikeBaseActorEffectHandler::Trigger_OnStopMovingBackward(this);
		else
			UIslandTimeLikeBaseActorEffectHandler::Trigger_OnStopMovingForward(this);

		if(MoveAnimation.Value != 1.0)
			return;

		OnReachedDestination.Broadcast();
		
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	void DisableMovement() {
		bIsDisabled = true;
	}
}

UCLASS(Abstract)
class UIslandTimeLikeBaseActorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingForward() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingBackward() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMovingForward() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMovingBackward() {}
}