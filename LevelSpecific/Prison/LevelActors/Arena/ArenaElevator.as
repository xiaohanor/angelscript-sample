event void FArenaElevatorEvent();

UCLASS(Abstract)
class AArenaElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UStaticMeshComponent ElevatorMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveElevatorTimeLike;

	UPROPERTY()
	FArenaElevatorEvent OnElevatorReachedTop;

	bool bReversing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveElevatorTimeLike.BindUpdate(this, n"UpdateMoveElevator");
		MoveElevatorTimeLike.BindFinished(this, n"FinishMoveElevator");
	}

	UFUNCTION()
	void StartMovingElevator()
	{
		MoveElevatorTimeLike.Play();

		UArenaElevatorEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION()
	void StartReversingElevator()
	{
		bReversing = true;
		MoveElevatorTimeLike.Reverse();

		UArenaElevatorEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveElevator(float CurValue)
	{
		float Height = Math::Lerp(0.0, 9580.0, CurValue);
		ElevatorRoot.SetRelativeLocation(FVector(0.0, 0.0, Height));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveElevator()
	{
		if (!bReversing)
			OnElevatorReachedTop.Broadcast();

		UArenaElevatorEffectEventHandler::Trigger_StopMoving(this);
	}
}