class ACoastTrainSpinTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent Trigger;
	default Trigger.Shape = FHazeShapeSettings::MakeBox(FVector(500, 500, 500));

	// Whether we should reset the spin to neutral when this trigger is entered
	UPROPERTY(EditAnywhere, Category = "Coast Train Spin")
	bool bResetSpinToNeutral = false;

	// How fast to spin (negative spins in the opposite direction)
	UPROPERTY(EditAnywhere, Category = "Coast Train Spin")
	float SpinSpeed = 5.0;

	bool bTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bTriggered)
			return;

		bTriggered = true;
		AddActorDisable(this);

		// Find the train we're attached to and spin it
		AActor AttachActor = GetAttachParentActor();
		while (AttachActor != nullptr)
		{
			auto Cart = Cast<ACoastTrainCart>(AttachActor);
			if (Cart != nullptr)
			{
				if (bResetSpinToNeutral)
					Cart.Driver.ResetTrainSpinToNeutral(SpinSpeed);
				else
					Cart.Driver.SpinTrain(SpinSpeed);

				break;
			}

			AttachActor = AttachActor.GetAttachParentActor();
		}
	}
};