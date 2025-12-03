class ASolarFlareDysonRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	ASolarFlareSun Sun;

	UPROPERTY(EditInstanceOnly)
	FRotator RotationPerSecond = FRotator(30, 0, 0);

	UPROPERTY(EditInstanceOnly)
	float RotationMultiplier = 0.4;

	UPROPERTY(EditInstanceOnly)
	AHazeLevelSequenceActor Sequence;

	UPROPERTY(EditInstanceOnly)
	UStaticMesh Mesh;

	float RotationSpeedTwo = 1.0;
	float RotationSpeedThree = 1.8; 

	bool bScaleDown;
	FVector StartScale;
	FHazeAcceleratedVector AccelVec;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.StaticMesh = Mesh;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Sun.OnSolarFlareActivateWave.AddUFunction(this, n"OnSolarFlareActivateWave");
		AccelVec.SnapTo(ActorScale3D);
	}

	UFUNCTION()
	void ActivateBlackholeShrink()
	{
		bScaleDown = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldRotation(RotationPerSecond * DeltaSeconds * RotationMultiplier);

		if (bScaleDown)
		{
			AccelVec.AccelerateTo(FVector(0.02), 1.25, DeltaSeconds);
			ActorScale3D = AccelVec.Value;
			if (AccelVec.Value.X <= 0.025)
				AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void OnSolarFlareActivateWave()
	{
		if (Sun.Phase == ESolarFlareSunPhase::Phase6)
			RotationMultiplier = RotationSpeedTwo;
		else if (Sun.Phase == ESolarFlareSunPhase::Phase9)
			RotationMultiplier = RotationSpeedThree;
	}

	UFUNCTION()
	void DestroyRing()
	{
		MeshComp.SetHiddenInGame(true);
		if (Sequence != nullptr)
			Sequence.PlayLevelSequenceSimple();
	}
};