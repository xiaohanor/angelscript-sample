class ASanctuaryCentipedeFreezableLava : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
	default MeshComp.bGenerateOverlapEvents = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FreezeVFXComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryCentipedeFrozenLavaRock> LavaRockClass;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ColdMaterial;
	UMaterialInterface InitialMaterial;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	TArray<UPrimitiveComponent> OverlappedCentipedeParts;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;
	TArray<UHazeMovementComponent> ImpactingMoveComps;

	UPROPERTY(EditDefaultsOnly, Category = "Lava")
	float RockLifetime = 10.0;
	UPROPERTY(EditDefaultsOnly, Category = "Lava")
	FVector RockLocationRandomization = FVector(20, 20, 5.0);
	
	UPROPERTY(EditInstanceOnly)
	bool bDisabledSpawningRocks = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialMaterial = MeshComp.GetMaterial(0);
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");
		ImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandlePlayerImpactEnd");
		MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		ImpactingMoveComps.Add(MoveComp);
		if (ImpactingMoveComps.Num() == 1)
		{
			// todo(ylva) make a more granular check of which segments we overlap
			LavaComp.ManualStartOverlapWholeCentipedeApply();
		}
	}

	UFUNCTION()
	private void HandlePlayerImpactEnd(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		ImpactingMoveComps.Remove(MoveComp);
		if (ImpactingMoveComps.Num() == 0)
			LavaComp.ManualEndOverlapWholeCentipedeApply();
	}

	void Freeze(FVector WaterImpactPoint)
	{
		LavaComp.ManualEndOverlapWholeCentipedeApply();
		SanctuaryCentipedeLavaRock::GetManager().RequestSpawnRock(nullptr, LavaRockClass, WaterImpactPoint, RockLocationRandomization, true, RockLifetime);
	}
};