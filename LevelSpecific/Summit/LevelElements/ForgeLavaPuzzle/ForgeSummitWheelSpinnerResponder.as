class UForgeSummitWheelSpinnerResponer : USceneComponent
{
	UPROPERTY(EditAnywhere)
	ASummitRollingWheel RollingWheel;

	UPROPERTY(EditAnywhere)
	float RollScaler = 0.1;

	UPROPERTY(EditAnywhere)
	bool bCounterClockwise;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollingWheel.OnWheelRolled.AddUFunction(this, n"HandleRolling");
	}

	UFUNCTION()
	private void HandleRolling(float Amount)
	{	
		AddLocalRotation(FRotator(Amount * RollScaler * (bCounterClockwise ? -1.0 : 1.0), 0, 0));
	}
}