UCLASS(Abstract)
class USplitTraversalElevatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}
}

class ASplitTraversalElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent ElevatorRoot;

	UPROPERTY(Category = Movement)
	float AccelerationDuration = 2.0;

	UPROPERTY(Category = Movement)
	float HeightSpeed = 2000.0;

	UPROPERTY(Category = Movement)
	float RotationSpeed = 30.0;

	UPROPERTY(Category = Timing, EditAnywhere)
	float DescendDuration = 5.0;

	UPROPERTY(Category = Timing, EditAnywhere)
	float WaitDuration = 2.0;
	float WaitUntilGameTime;

	UPROPERTY(Category = Timing, EditAnywhere)
	float RotationDuration = 3.0;
	float RotateUntilGameTime;

	UPROPERTY(EditInstanceOnly)
	float StartOffset = 0.0;

	FHazeAcceleratedFloat HeightAcceleratedFloat;
	float TargetHeightFloat;

	FHazeAcceleratedFloat RotationAcceleratedFloat;
	float TargetRotationFloat;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		QueueComp.SetLooping(true);
		QueueComp.Event(this, n"Descend");
		QueueComp.Duration(DescendDuration, this, n"DescendUpdate");
		QueueComp.Event(this, n"StopMoving");
		QueueComp.Idle(WaitDuration);
		QueueComp.Event(this, n"StartMoving");
		QueueComp.Duration(RotationDuration, this, n"RotateUpdate");
	}

	UFUNCTION()
	private void Descend()
	{
		TargetHeightFloat = HeightSpeed * DescendDuration;
		HeightAcceleratedFloat.SnapTo(TargetHeightFloat);

		TargetRotationFloat = 0.0;
		RotationAcceleratedFloat.SnapTo(TargetRotationFloat);
	}

	UFUNCTION()
	private void DescendUpdate(float Alpha)
	{
		float FinalHeight = HeightSpeed * DescendDuration;
		float CurrentHeight = Acceleration::GetDistanceAtTimeWithDestination(
			Alpha * DescendDuration,
			FinalHeight,
			DescendDuration,
			0.0,
			2.0,
		);
		
		HeightAcceleratedFloat.SnapTo(FinalHeight - CurrentHeight);
	}

	UFUNCTION()
	private void StopMoving()
	{
		USplitTraversalElevatorEventHandler::Trigger_OnStopMoving(this);
	}

	UFUNCTION()
	private void StartMoving()
	{
		USplitTraversalElevatorEventHandler::Trigger_OnStartMoving(this);
	}

	UFUNCTION()
	private void RotateUpdate(float Alpha)
	{
		TargetRotationFloat = Math::Lerp(0.0, -RotationSpeed * RotationDuration, Alpha);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		QueueComp.ScrubTo(Time::PredictedGlobalCrumbTrailTime + StartOffset);

		// HeightAcceleratedFloat.AccelerateTo(TargetHeightFloat, AccelerationDuration, DeltaSeconds);
		RotationAcceleratedFloat.AccelerateTo(TargetRotationFloat, AccelerationDuration, DeltaSeconds);

		ElevatorRoot.SetRelativeLocationAndRotation(FVector::UpVector * HeightAcceleratedFloat.Value, 
													FRotator(RotationAcceleratedFloat.Value, 0.0, 0.0));
	}
};