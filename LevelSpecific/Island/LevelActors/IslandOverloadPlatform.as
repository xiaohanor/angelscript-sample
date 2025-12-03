event void FIslandOverloadPlatformSignature();

enum EIslandOverloadPlatformMoveState
{
	Origin,
	MovingToDestination,
	MovingToOrigin,
	Destination
}

class AIslandOverloadPlatform : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = DestinationComp)
	UStaticMeshComponent DestinationMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UStaticMeshComponent MovableMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachablePanelComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

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

	UPROPERTY(EditInstanceOnly)
	bool bIsChildPlatform = false;

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

	// Will gets called when the overload platform starts moving towards destination
	UPROPERTY()
	FIslandOverloadPlatformSignature OnActivated;

	// Will gets called when the overload platform starts moving back towards the origin
	UPROPERTY()
	FIslandOverloadPlatformSignature OnReset;

	// Will gets called when the overload platform reaches the destination
	UPROPERTY()
	FIslandOverloadPlatformSignature OnReachedDestination;

	// Will gets called when the overload platform reaches the origin
	UPROPERTY()
	FIslandOverloadPlatformSignature OnReachedOrigin;

	UPROPERTY()
	bool bIsPlaying;
	bool bMovingBack;
	bool bCurrentlyExtended;
	EIslandOverloadPlatformMoveState CurrentPlatformMoveState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = bIsChildPlatform ? GetActorRelativeLocation() : StartingTransform.GetLocation();
		StartingRotation = bIsChildPlatform ? GetActorRelativeRotation().Quaternion() : StartingTransform.GetRotation();


		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = bIsChildPlatform ? GetActorRelativeLocation() + DestinationComp.RelativeLocation : EndingTransform.GetLocation();
		EndingRotation = bIsChildPlatform ? DestinationComp.RelativeRotation.Quaternion() : EndingTransform.GetRotation();

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
		CurrentPlatformMoveState = EIslandOverloadPlatformMoveState::MovingToDestination;
		MoveAnimation.Play();
		OnActivated.Broadcast();
		bMovingBack = false;
		UIslandOverloadPlatformEffectHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	void Reverse()
	{
		CurrentPlatformMoveState = EIslandOverloadPlatformMoveState::MovingToOrigin;
		MoveAnimation.Reverse();
		OnReset.Broadcast();
		bMovingBack = true;
		UIslandOverloadPlatformEffectHandler::Trigger_OnStartResetting(this);
	}

	UFUNCTION()
	void SetFinished()
	{
		SetActorRelativeLocation(EndingPosition);
		SetActorRelativeRotation(EndingRotation);
		PanelRef.DisablePanel();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		if(bIsChildPlatform)
		{
			SetActorRelativeLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
			SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		}
		else
		{
			SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		}
	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		UIslandOverloadPlatformEffectHandler::Trigger_OnStopMoving(this);

		if(MoveAnimation.Value != 1.0)
		{
			CurrentPlatformMoveState = EIslandOverloadPlatformMoveState::Origin;
			OnReachedOrigin.Broadcast();
			CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
			return;
		}
		
		CurrentPlatformMoveState = EIslandOverloadPlatformMoveState::Destination;
		OnReachedDestination.Broadcast();

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}

}

UCLASS(Abstract)
class UIslandOverloadPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartResetting() {}
}