event void FIslandRiftDoorHatchSignature();

class AIslandRiftDoorHatch : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachablePanelComp;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel OptionalPanelRef;
	
	UPROPERTY(EditInstanceOnly)
	AIslandOverloadPanelListener ListenerRef;

	UPROPERTY(EditInstanceOnly)
	AIslandGrenadeLockListener GrenadeListenerRef;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

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

		UIslandRiftDoorHatchEffectHandler::Trigger_OnStartMovingForward(this);
	}

	UFUNCTION()
	void Reverse()
	{
		if (bIsDisabled)
			return;

		bMovingBack = true;
		MoveAnimation.Reverse();

		UIslandRiftDoorHatchEffectHandler::Trigger_OnStartMovingBackward(this);
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
			UIslandRiftDoorHatchEffectHandler::Trigger_OnStopMovingBackward(this);
		else
			UIslandRiftDoorHatchEffectHandler::Trigger_OnStopMovingForward(this);

		if(MoveAnimation.Value != 1.0)
			return;

		OnReachedDestination.Broadcast();
		
		if (CameraShake == nullptr)
			return;

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);
	}

	UFUNCTION()
	void DisableMovement() {
		bIsDisabled = true;
	}
}

UCLASS(Abstract)
class UIslandRiftDoorHatchEffectHandler : UHazeEffectEventHandler
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