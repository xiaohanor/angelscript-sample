UCLASS(Abstract)
class AOilRigElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ElevatorRoot;

	UPROPERTY(DefaultComponent, Attach = ElevatorRoot)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TopRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MidRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BottomRoot;

	UFUNCTION()
	void Activate()
	{
		BP_Activate();

		UOilRigElevatorEffectEventHandler::Trigger_Start(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION()
	void SnapToTop()
	{
		BP_SnapToTop();
		Timer::SetTimer(this, n"AfterSnapToTop", 0.01);
	}

	UFUNCTION()
	private void AfterSnapToTop()
	{
		ActorLocation = ActorLocation + FVector(0, 0, 0.01);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SnapToTop() {}

	UFUNCTION()
	void ReachedTop()
	{
		UOilRigElevatorEffectEventHandler::Trigger_Stop(this);
	}
}