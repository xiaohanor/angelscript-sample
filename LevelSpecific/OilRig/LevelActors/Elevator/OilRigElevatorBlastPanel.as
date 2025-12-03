UCLASS(Abstract)
class AOilRigElevatorBlastPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShieldRoot;

	UFUNCTION()
	void Activate()
	{
		BP_Activate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}

	UFUNCTION()
	void SnapClosed()
	{
		BP_SnapClosed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SnapClosed() {}
}