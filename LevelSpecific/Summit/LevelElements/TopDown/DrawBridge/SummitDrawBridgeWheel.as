class ASummitDrawBridgeWheel : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotationComponent;

	UFUNCTION()
	void ActivateWheel()
	{	
		BP_OnActivated();
	}

	UFUNCTION()
	void DeactivateWheel()
	{	
		BP_OnDeactivated();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated() {}

}
