UCLASS(Abstract)
class AOilRigElevatorBlastShield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShieldRoot;

	UFUNCTION()
	void Raise()
	{
		BP_Raise();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Raise() {}

	UFUNCTION()
	void Lower()
	{
		BP_Lower();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Lower() {}

	UFUNCTION()
	void SnapRaise()
	{
		BP_SnapRaise();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SnapRaise() {}

	UFUNCTION()
	void SnapLower()
	{
		BP_SnapLower();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SnapLower() {}
}