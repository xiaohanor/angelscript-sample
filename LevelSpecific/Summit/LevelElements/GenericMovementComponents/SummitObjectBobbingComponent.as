class USummitObjectBobbingComponent : USceneComponent
{
	FVector StartLocation;
	UPROPERTY()
	float BobbingAmount = 50.0;
	UPROPERTY()
	float BobbingSpeed = 1.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RelativeLocation = StartLocation + FVector(0.0, 0.0, BobbingAmount) * Math::Sin(Time::GameTimeSeconds * BobbingSpeed);
	}
}