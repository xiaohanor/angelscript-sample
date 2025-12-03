class AIslandTurbineShakeVolume : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxTrigger;

	UPROPERTY(EditAnywhere)
	float FFIntensity = 0.4;
	
	UPROPERTY(EditAnywhere)
	float FFFrequency = 30.0;

	UPROPERTY(EditAnywhere)
	float CamShakeScale = 1;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CamShakeClass;

	TArray<AHazePlayerCharacter> Players;
	TPerPlayer<UCameraShakeBase> CamShakeInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnTriggerEnter");
		BoxTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnTriggerExit");
	}

	UFUNCTION()
	private void OnTriggerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Players.AddUnique(Player);

		if (CamShakeInstance[Player] == nullptr)
		{
			CamShakeInstance[Player] = Player.PlayCameraShake(CamShakeClass, this, Scale = CamShakeScale);
		}
	}

	UFUNCTION()
	private void OnTriggerExit(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if (CamShakeInstance[Player] != nullptr)
		{
			Player.StopCameraShakeInstance(CamShakeInstance[Player]);
			CamShakeInstance[Player] = nullptr;
		}

		Players.RemoveSingleSwap(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GetGameTimeSeconds() * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-Time::GetGameTimeSeconds() * FFFrequency) * FFIntensity;
		for(auto Player : Players)
		{
			Player.SetFrameForceFeedback(FF);
		}
	}
};