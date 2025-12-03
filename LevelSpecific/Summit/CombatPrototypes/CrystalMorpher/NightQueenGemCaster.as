class ANightQueenGemCaster : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"CrystalMorphAttackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"CrystalMagicLineAttackCapability");

	UPROPERTY(Category = "Setup")
	TSubclassOf<AMetalMorpherAttack> MetalMorphClass;

	UPROPERTY(Category = "Setup")
	TSubclassOf<ARubyMagicSpear> MagicSpearClass;

	float ActivateDuration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int SpawnAmount = 20;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bUseMetalAttack = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartActive = false;

	bool bIsActive;

	bool bIsMainAttack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (bStartActive)
			ActivateCrystalMorpher();
	}

	void SpawnMetalMorpher(FVector Location)
	{
		SpawnActor(MetalMorphClass, Location);
	}

	void SpawnMagicSpear(FVector Location)
	{
		SpawnActor(MagicSpearClass, Location);
	}

	UFUNCTION()
	void ActivateCrystalMorpher()
	{
		bIsActive = true;
	}

	void SetNextAttackType()
	{
		bIsMainAttack = !bIsMainAttack;
	}
}