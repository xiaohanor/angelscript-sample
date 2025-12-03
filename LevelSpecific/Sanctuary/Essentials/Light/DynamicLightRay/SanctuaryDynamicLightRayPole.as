class ASanctuaryDynamicLightRayPole : APoleClimbActor
{
	default bAllowPerchOnTop = false;

	default Pole.bHiddenInGame = true;
	default Pole.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Pole.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	USanctuaryDynamicLightRayMeshComponent Mesh;
	
	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		RootComponent.SetMobility(EComponentMobility::Movable);
		Mesh = USanctuaryDynamicLightRayMeshComponent::Get(this);
		UpdateHeight();
	}

	UFUNCTION(BlueprintCallable)
	void UpdateHeight()
	{
		if (Mesh == nullptr)
			return;

		float HeightFraction = Height / 100.0;
		Mesh.RelativeScale3D = FVector(
			Mesh.RelativeScale3D.X,
			Mesh.RelativeScale3D.Y,
			HeightFraction
		);
	}

	void Disable(FInstigator Instigator)
	{
		if (DisableInstigators.Num() == 0)
		{
			DisablePoleActor(false);
			Mesh.Disable();
		}

		DisableInstigators.Add(Instigator);
	}

	void RemoveDisable(FInstigator Instigator)
	{
		if (DisableInstigators.Remove(Instigator) != 0 && DisableInstigators.Num() == 0)
		{
			EnablePoleActor(false);
			Mesh.Enable();
		}
	}
};