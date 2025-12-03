class ASpaceWalkAirDepressurizers : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent AirNozzle;

	UPROPERTY(EditAnywhere)
	bool bRotateClockwise;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bRotateClockwise)
			AirNozzle.AddLocalRotation(FRotator(0,-30,0) * DeltaSeconds);
		else
			AirNozzle.AddLocalRotation(FRotator(0,30,0) * DeltaSeconds);
	}

	UFUNCTION(BlueprintCallable)
	void StartAir()
	{
		USpaceWalkAirDepressurizerEventHandler::Trigger_StartAir(this);
	}
};