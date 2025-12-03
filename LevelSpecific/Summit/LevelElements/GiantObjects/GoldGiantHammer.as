class AGoldGiantHammer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent HitBox;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitNightQueenGem> CrystalArray;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ANightQueenMetal> MetalArray;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ImpulseAmount = 22585000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FallRotationAmount = 90.0;

	UPROPERTY()
	FRotator StartingRot;

	int CrystalBreakCount;
	int MaxCrystalBreakCount;
	int MetalMeltCount;
	int MaxMetalMeltCount;

	bool bHaveFallen;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MaxCrystalBreakCount = CrystalArray.Num();
		MaxMetalMeltCount = MetalArray.Num();

		for (ASummitNightQueenGem Gem : CrystalArray)
		{
			Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitCrystalDestroyed");
		}

		for (ANightQueenMetal Metal : MetalArray)
		{
			Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
			Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
		}

		HitBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		StartingRot = MeshRoot.RelativeRotation;
	}

	void BreakCheck()
	{
		if (CrystalBreakCount < MaxCrystalBreakCount) 
			return;		
		
		if (MetalMeltCount < MaxMetalMeltCount)	
			return;		

		if (bHaveFallen)
			return;

		bHaveFallen = true;
		BP_WeaponFall();
		Game::Mio.PlayCameraShake(CameraShake, this, 0.8);
		Game::Zoe.PlayCameraShake(CameraShake, this, 0.8);
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		MetalMeltCount--;
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		MetalMeltCount++;
		BreakCheck();
	}

	UFUNCTION()
	private void OnSummitCrystalDestroyed(ASummitNightQueenGem DestroyedCrystal)
	{
		CrystalBreakCount++;
		BreakCheck();
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_WeaponFall() {}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		UGoldGiantBreakResponseComponent BreakComp = UGoldGiantBreakResponseComponent::Get(OtherActor);

		if (BreakComp == nullptr)
			return;

		FVector Dir = -OtherActor.ActorForwardVector;
		BreakComp.BreakGiant(Dir, ImpulseAmount);
	}
}