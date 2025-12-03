class ATurningWheelResponder : AHazeActor
{
	UPROPERTY(EditAnywhere)
	ASummitTurningWheel TurningWheel;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TurningWheel.OnWheelTurning.AddUFunction(this, n"OnWheelTurning");

	}

	UFUNCTION()
	private void OnWheelTurning(float TurnAmount)
	{
		PrintToScreen("TurnAmount: " + TurnAmount);

		
	}
}