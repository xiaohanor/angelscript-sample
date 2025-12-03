class ASkylineGravityZone : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityOnPlayerComponent;

	UPROPERTY(EditAnywhere, Category = "Gravity Zone")
	EHazeSelectPlayer UsableByPlayers = EHazeSelectPlayer::Both;
	
	UPROPERTY(EditAnywhere, Category = "Gravity Zone")
	UMaterialInterface ZoneMaterial;

	UPROPERTY(EditAnywhere, Category = "Gravity Zone")
	FName MaterialParameterName = n"Forcefield_Opacity";

	UPROPERTY(EditAnywhere, Category = "Gravity Zone")
	float ActiveParameterValue = 0.1;

	UPROPERTY(EditAnywhere, Category = "Gravity Zone")
	bool bAlwaysActive = false;

	private UMaterialInstanceDynamic DynamicMaterial;
	private TArray<AHazeActor> OverlappingActors;
	private TArray<FInstigator> ActiveGenerators;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetMaterial(ZoneMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DynamicMaterial = Material::CreateDynamicMaterialInstance(this, ZoneMaterial);
		DynamicMaterial.SetScalarParameterValue(MaterialParameterName, 0.0);
		SetMaterial(DynamicMaterial);

		OnActorBeginOverlap.AddUFunction(this, n"HandleActorBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"HandleActorEndOverlap");

		if (bAlwaysActive)
			Activate(this);
	}

	UFUNCTION(BlueprintCallable)
	void Activate(FInstigator Instigator)
	{
		if (Instigator == nullptr)
			return;

		const bool bWasActive = IsActive();
		ActiveGenerators.AddUnique(Instigator);
		
		if (!bWasActive && IsActive())
		{
			for (int i = OverlappingActors.Num() - 1; i >= 0; --i)
			{
				auto ZoneComp = USkylineGravityZoneComponent::Get(OverlappingActors[i]);
				if (ZoneComp != nullptr)
					ZoneComp.RegisterZone(this);
			}

			DynamicMaterial.SetScalarParameterValue(MaterialParameterName, ActiveParameterValue);
		}
	}

	UFUNCTION(BlueprintCallable)
	void Deactivate(FInstigator Instigator)
	{
		if (Instigator == nullptr)
			return;

		const bool bWasActive = IsActive();
		ActiveGenerators.Remove(Instigator);

		if (bWasActive && !IsActive())
		{
			for (int i = OverlappingActors.Num() - 1; i >= 0; --i)
			{
				auto ZoneComp = USkylineGravityZoneComponent::Get(OverlappingActors[i]);
				if (ZoneComp != nullptr)
					ZoneComp.UnregisterZone(this);
			}

			DynamicMaterial.SetScalarParameterValue(MaterialParameterName, 0.0);
		}
	}

	bool IsActive() const
	{
		return (ActiveGenerators.Num() != 0);
	}

	private void SetMaterial(UMaterialInterface Material)
	{
		TArray<UPrimitiveComponent> Primitives;
		GetComponentsByClass(Primitives);

		for (auto Primitive : Primitives)
		{
			for (int i = 0; i < Primitive.NumMaterials; i++)
				Primitive.SetMaterial(i, Material);
		}		
	}

	UFUNCTION()
	private void HandleActorBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto HazeActor = Cast<AHazeActor>(OtherActor);
		if (HazeActor == nullptr)
			return;
		if (OverlappingActors.Contains(HazeActor))
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && !Player.IsSelectedBy(UsableByPlayers))
			return;

		auto ZoneComp = USkylineGravityZoneComponent::Get(OtherActor);
		if (ZoneComp == nullptr)
			return;

		if (IsActive())
		{
			ZoneComp.RegisterZone(this);
		}

		OverlappingActors.AddUnique(HazeActor);
	}
	
	UFUNCTION()
	private void HandleActorEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto HazeActor = Cast<AHazeActor>(OtherActor);
		if (HazeActor == nullptr)
			return;
		if (!OverlappingActors.Contains(HazeActor))
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && !Player.IsSelectedBy(UsableByPlayers))
			return;

		auto ZoneComp = USkylineGravityZoneComponent::Get(OtherActor);
		if (ZoneComp == nullptr)
			return;

		if (IsActive())
		{
			ZoneComp.UnregisterZone(this);
		}

		OverlappingActors.Remove(HazeActor);
	}
}