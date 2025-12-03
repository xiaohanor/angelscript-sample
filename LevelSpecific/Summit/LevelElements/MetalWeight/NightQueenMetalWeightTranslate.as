class ANightQueenMetalWeightTranslate : ANightQueenMetal
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent EndLocation;
	default EndLocation.SetWorldScale3D(FVector(5.0));

	FVector StartLoc;
	FVector TargetLoc;
	float MoveSpeed;
	float TargetSpeed = 1000.0;
	float AccelerationRate = 500.0;
	float TotalDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
		StartLoc = MeshRoot.RelativeLocation;
		TotalDistance = (StartLoc - EndLocation.RelativeLocation).Size();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetLoc, DeltaTime, MoveSpeed);

		if (MoveSpeed < TargetSpeed)
			MoveSpeed = Math::FInterpConstantTo(MoveSpeed, TargetSpeed, DeltaTime, AccelerationRate);
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		MoveSpeed = 0.0;
		TargetLoc = EndLocation.RelativeLocation;
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		MoveSpeed = 0.0;
		TargetLoc = StartLoc;
	}

	float GetWeightAlpha()
	{
		if (MeshRoot.RelativeLocation.Size() != 0.0)
			return (StartLoc - MeshRoot.RelativeLocation).Size() / TotalDistance;
		else
			return 0.0;
	}
}