class ASanctuaryWellCrumblingStairs : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent StairMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent StairCrumbleMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXCrumbleComp;

	UMaterialInstanceDynamic StairCrumbleMID1;
	UMaterialInstanceDynamic StairCrumbleMID2;
	UMaterialInstanceDynamic StairCrumbleMID3;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> ActorsToDisable;

	UPROPERTY(EditAnywhere)
	float CrumbleDelay = 0.1;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryWellCrumblingStairs LinkedStairs;

	UPROPERTY()
	FHazeTimeLike CrumbleTimeLike;
	default CrumbleTimeLike.UseLinearCurveZeroToOne();
	default CrumbleTimeLike.Duration = 5.0;

	bool bCrumbled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StairCrumbleMID1 = Material::CreateDynamicMaterialInstance(this, StairCrumbleMeshComp.GetMaterial(0));
		StairCrumbleMID2 = Material::CreateDynamicMaterialInstance(this, StairCrumbleMeshComp.GetMaterial(1));
		StairCrumbleMID3 = Material::CreateDynamicMaterialInstance(this, StairCrumbleMeshComp.GetMaterial(2));

		StairCrumbleMeshComp.SetMaterial(0, StairCrumbleMID1);
		StairCrumbleMeshComp.SetMaterial(1, StairCrumbleMID2);
		StairCrumbleMeshComp.SetMaterial(2, StairCrumbleMID3);

		CrumbleTimeLike.BindUpdate(this, n"CrumbleTimeLikeUpdate");
		CrumbleTimeLike.BindFinished(this, n"CrumbleTimeLikeFinished");
	}

	UFUNCTION()
	private void CrumbleTimeLikeUpdate(float CurrentValue)
	{
		StairCrumbleMID1.SetScalarParameterValue(n"VAT_DisplayTime", CurrentValue);
		StairCrumbleMID2.SetScalarParameterValue(n"VAT_DisplayTime", CurrentValue);
		StairCrumbleMID3.SetScalarParameterValue(n"VAT_DisplayTime", CurrentValue);
	}

	UFUNCTION()
	private void CrumbleTimeLikeFinished()
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	void Crumble()
	{
		if (bCrumbled)
			return;

		bCrumbled = true;

		Timer::SetTimer(this, n"DisableCollision", 1.0);

		CrumbleTimeLike.Play();

		if (LinkedStairs != nullptr)
		{
			if (CrumbleDelay > 0.0)
				Timer::SetTimer(LinkedStairs, n"Crumble", CrumbleDelay);
			else
				LinkedStairs.Crumble();
		}
	}

	UFUNCTION()
	private void DisableCollision()
	{
		StairMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		for (auto Actor : ActorsToDisable)
		{
			Actor.AddActorDisable(this);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(VFXCrumbleComp.Asset, 
														Actor.GetActorCenterLocation());
		}
	}
};