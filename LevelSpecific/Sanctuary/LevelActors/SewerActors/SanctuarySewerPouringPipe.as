class ASanctuarySewerPouringPipe : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Pipe;

	UPROPERTY(EditAnywhere)
	ASanctuarySewerWater Water;

	UPROPERTY(EditAnywhere)
	AHazeActor BirdCage;

	UPROPERTY(EditAnywhere)
	float PourSpeed = 60;

	UPROPERTY(EditAnywhere)
	float DrainSpeed = 60;

	UPROPERTY(EditAnywhere)
	bool bPlugged;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto BirdResponseComp = ULightBirdResponseComponent::Get(BirdCage);

		if(BirdCage == nullptr)
			return;

		BirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		BirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

		if(bPlugged)
		{
			Water.WaterDrain(DrainSpeed);
			BP_DisableWaterFall();

		}
		else
		{
			Water.WaterRise(PourSpeed);
			BP_EnableWaterFall();

		}
	}

	UFUNCTION()
	void Unplug()
	{
		bPlugged = false;
		Water.WaterRise(PourSpeed);
		BP_EnableWaterFall();
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		Water.WaterDrain(DrainSpeed);
		BP_DisableWaterFall();
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		Water.WaterRise(PourSpeed);
		BP_EnableWaterFall();

	}

	UFUNCTION(BlueprintEvent)
	void BP_EnableWaterFall()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_DisableWaterFall()
	{

	}
	

};