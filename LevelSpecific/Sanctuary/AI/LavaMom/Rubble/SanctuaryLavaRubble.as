enum ESanctuaryLavaRubbleType
{
	JustRock,
	Lava,
	Water
}

class ASanctuaryLavaRubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RubbleMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WaterMaterialMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LavaMaterialMesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SplashVFX;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;
	default LavaComp.DamagePerSecond = 3.0;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	ESanctuaryLavaRubbleType RubbleType = ESanctuaryLavaRubbleType::JustRock;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	bool bHit = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		switch (RubbleType)
		{
			case ESanctuaryLavaRubbleType::JustRock:
			{
				SplashVFX.SetVisibility(false);
				WaterMaterialMesh.SetVisibility(false);
				LavaMaterialMesh.SetVisibility(false);
				break;
			}
			case ESanctuaryLavaRubbleType::Lava:
			{
				SplashVFX.SetVisibility(false);
				WaterMaterialMesh.SetVisibility(false);
				LavaMaterialMesh.SetVisibility(true);
				break;
			}
			case ESanctuaryLavaRubbleType::Water:
			{
				SplashVFX.SetVisibility(true);
				WaterMaterialMesh.SetVisibility(true);
				LavaMaterialMesh.SetVisibility(false);
				break;
			}
		}
	}

	// when you get older, you could get
	void HitByABoulder()
	{
		bHit = true;
		RubbleMesh.SetVisibility(false);
		WaterMaterialMesh.SetVisibility(false);
		LavaMaterialMesh.SetVisibility(false);
		SplashVFX.Deactivate();

		TArray<AActor> ChildActors;
		GetAttachedActors(ChildActors);
		for (auto Child : ChildActors)
		{
			auto OutletChild = Cast<ACentipedeWaterOutlet>(Child);
			if (OutletChild != nullptr)
				OutletChild.Unplugged(nullptr);
		}

		BP_OnCrumble();

		LavaSplash();
	}

	private void LavaSplash()
	{
		if (RubbleType == ESanctuaryLavaRubbleType::Lava)
		{
			for(FVector Location: GetBodyLocations())
			{
				float HitRadius = 200.0;
				if(!ActorLocation.IsWithinDist(Location, HitRadius))
					continue;
				LavaComp.OverlapSingleFrame(Location, HitRadius, false);
			}
		}
	}

	private TArray<FVector> GetBodyLocations() const
	{
		TArray<FVector> Locations;
		UPlayerCentipedeComponent CentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		if(ensure(CentipedeComp != nullptr, "Can only target centipede players!"))
			Locations = CentipedeComp.GetBodyLocations();
		return Locations;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnCrumble() {}
};