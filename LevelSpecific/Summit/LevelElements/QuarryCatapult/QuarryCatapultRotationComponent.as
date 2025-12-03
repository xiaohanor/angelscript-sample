class UQuarryCatapultRotationComponent : UActorComponent
{
	AQuarryCatapult Catapult;

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


		Catapult.BaseMeshComp.AddRelativeRotation(FRotator(0.0, TurnAmount, 0.0));
	}
}