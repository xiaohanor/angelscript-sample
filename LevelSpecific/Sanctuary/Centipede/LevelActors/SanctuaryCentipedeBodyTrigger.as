class ASanctuaryCentipedeBodyTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent ActivationZoneComp;

	AHazePlayerCharacter M;
	AHazePlayerCharacter Z;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationZoneComp.OnComponentBeginOverlap.AddUFunction(this, n"ActivationZoneHandleBeginOverlap");
		ActivationZoneComp.OnComponentEndOverlap.AddUFunction(this, n"ActivationZoneHandleEndOverlap");
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleBodyBeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleBodyEndOverlap");
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void HandleBodyBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                    UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                    bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto ResponseComp = OtherActor.GetComponentByClass(UCentipedeBodyTriggerResponseComponent);

		if (IsValid(ResponseComp))
			ResponseComp.BodyBeginOverlap(OtherComp);
	}

	UFUNCTION()
	private void HandleBodyEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                  UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto ResponseComp = OtherActor.GetComponentByClass(UCentipedeBodyTriggerResponseComponent);

		if (IsValid(ResponseComp))
			ResponseComp.BodyEndOverlap(OtherComp);
	}

	UFUNCTION()
	private void ActivationZoneHandleBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                         UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                         bool bFromSweep, const FHitResult&in SweepResult)
	{
		M = Game::Mio;
		Z = Game::Zoe;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void ActivationZoneHandleEndOverlap(UPrimitiveComponent OverlappedComponent,
	                                            AActor OtherActor, UPrimitiveComponent OtherComp,
	                                            int OtherBodyIndex)
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen("Mio: " + IsValid(M));
		PrintToScreen("Zoe: " + IsValid(Z));
		//float Multiplier = 1.0;

		FVector CenterLocation = Math::Lerp(M.ActorLocation, Z.ActorLocation, 0.5);

		FVector VectorA = M.ActorLocation - Z.ActorLocation;
		FVector VectorB = VectorA.GetSafeNormal().CrossProduct(FVector::UpVector);
		//FVector VectorC = CenterLocation - TargetActor.ActorLocation.GetSafeNormal();

		//FVector Offset = VectorB * (VectorA.Size() - 1000.0) * Multiplier;

		//if (VectorB.DotProduct(VectorC) < 0.0)
		//	Multiplier = -1.0;

		TriggerComp.SetWorldLocationAndRotation(CenterLocation, FRotator(0.0, VectorB.Rotation().Yaw, 0.0)); // + Offset for boulder? or maybe not
		TriggerComp.SetBoxExtent(FVector(50.0, VectorA.Size() * 0.5, 50.0));
	}
};