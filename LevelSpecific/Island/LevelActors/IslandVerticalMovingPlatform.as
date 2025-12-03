event void FIslandVerticalMovingPlatformSignature();

class AIslandVerticalMovingPlatform : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(EditAnywhere)
	bool bAutoPlay;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 3.0;

	UPROPERTY(EditAnywhere)
	float MovementOffset = 0.0;
	
	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;
	bool bMovingUp;

	float PredictedCrumbStartTime = 0.0;
	bool bActive = false;
	float PreviousPosition;

	UPROPERTY()
	FIslandVerticalMovingPlatformSignature OnActivated;

	UPROPERTY()
	FIslandVerticalMovingPlatformSignature OnReachedDestination;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		if (bAutoPlay)
		{
			bActive = true;
			OnActivated.Broadcast();
			BP_ActivatePlatform();
		}

		ActionQueue.SetLooping(true);
		ActionQueue.SetPaused(true);
		ActionQueue.Duration(AnimationDuration, this, n"OnUpdate");
		ActionQueue.Event(this, n"Reverse");
		ActionQueue.ReverseDuration(AnimationDuration, this, n"OnUpdate");
		ActionQueue.Event(this, n"Start");
	}

	UFUNCTION()
	void ActivatePlatform()
	{
		if (HasControl())
			NetActivatePlatform(Time::GetActorControlCrumbTrailTime(this));
	}

	UFUNCTION(NetFunction)
	private void NetActivatePlatform(float ActorControlCrumbTrailTime)
	{
		bActive = true;
		PredictedCrumbStartTime = ActorControlCrumbTrailTime;

		OnActivated.Broadcast();
		BP_ActivatePlatform();
	}

	UFUNCTION()
	void DeactivatePlatform()
	{
		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			float Time = Time::GetActorControlPredictedCrumbTrailTime(this) - PredictedCrumbStartTime - MovementOffset;
			if (Time >= 0)
				ActionQueue.ScrubTo(Time);
		}
	}

	UFUNCTION()
	void ResumePlatform()
	{
		bActive = true;
	}

	UFUNCTION()
	private void Start()
	{
		UIslandVerticalMovingPlatformEffectHandler::Trigger_OnStartMovingDown(this);
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		bMovingUp = false;
	}

	UFUNCTION()
	private void Reverse()
	{
		OnReachedDestination.Broadcast();
		UIslandVerticalMovingPlatformEffectHandler::Trigger_OnStartMovingUp(this);
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		bMovingUp = true;
	}

	UFUNCTION()
	private void OnUpdate(float Alpha)
	{
		float Position = Curve::SmoothCurveZeroToOne.GetFloatValue(Alpha);
		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Position), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
		PreviousPosition = Position;
	}

	
	UFUNCTION(BlueprintEvent)
	void BP_ActivatePlatform() {}

	// Get the alpha of the current position of the moving platform, between 0 and 1. 0 is bottom and 1 is top
	UFUNCTION(BlueprintPure)
	float GetPositionAlpha() const
	{
		return 1.0 - PreviousPosition;
	}
	
	// Get the movement direction of the moving platform, 1 is up and -1 is down, 0 is not moving.
	UFUNCTION(BlueprintPure)
	int GetMoveDirection() const
	{
		if(!bActive)
			return 0;

		return bMovingUp ? 1 : -1;
	}

}

UCLASS(Abstract)
class UIslandVerticalMovingPlatformEffectHandler : UHazeEffectEventHandler
{
	// Triggers when the moving platform starts moving upwards
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingUp() {}

	// Triggers when the moving platform starts moving downwards
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingDown() {}
}