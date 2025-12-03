class ASanctuaryBossInsideElectricCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ActorWithSpline;
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossInsideElectricCablePulse> PulseClass;

	UPROPERTY(EditInstanceOnly)
	float Delay = 0.6;

	int PulseDataIndex = 0;

	float HeartRate = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(ActorWithSpline);
		if (!IsValid(SplineComp))
			PrintToScreen("Actor has no spline!!!", 10.0, FLinearColor::Red);
	}

	UFUNCTION()
	void CallSendPulse()
	{
		Timer::SetTimer(this, n"SendPulse", Delay);
	}

	UFUNCTION()
	private void SendPulse()
	{
		PrintToScreen("Sent pulse data", 3.0);

		auto Pulse = SpawnActor(PulseClass, bDeferredSpawn = true);
		Pulse.DistanceAlongSpline = SplineComp.SplineLength;
		Pulse.Cable = this;
		FinishSpawningActor(Pulse);

		//Timer::SetTimer(this, n"SendPulse", HeartRate);
	}

};