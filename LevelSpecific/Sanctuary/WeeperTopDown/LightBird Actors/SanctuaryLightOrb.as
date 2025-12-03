event void FSanctuaryLightOrbSignature();

class ASanctuaryLightOrb : AHazeActor
{
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryLightOrbSignature OnActivated;
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryLightOrbSignature OnDeactivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Orb;
	
	UPROPERTY(EditAnywhere)
	UMaterialInstance LitMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstance UnlitMaterial;


	UPROPERTY(DefaultComponent)
	USanctuaryWeeperLightBirdResponseComponent LigthBirdResponseComp;

	UPROPERTY(EditAnywhere)
	float MaxActivationDistance = 300;

	bool bIlluminated;
	bool bActivated;

	ASanctuaryWeeperLightBird Bird;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LigthBirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LigthBirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIlluminated)
			return;
		bool bIsWithinDistance = IsWithinDistance();

		if(!bActivated && IsWithinDistance())
		{
			Activate();
		}
		else if(bActivated && !IsWithinDistance())
		{
			Deactivate();
		}

		
	}

	private bool IsWithinDistance()
	{
		float Distance = (Bird.ActorLocation - ActorLocation).Size();


		
		if(Distance <= MaxActivationDistance)
			return true;

		return false;
	}


	void Activate()
	{
		bActivated = true;
		OnActivated.Broadcast();

		Orb.SetMaterial(0, LitMaterial);
	}

	void Deactivate()
	{

		bActivated = false;
		OnDeactivated.Broadcast();

		Orb.SetMaterial(0, UnlitMaterial);
	}


	UFUNCTION()
	private void OnIlluminated(ASanctuaryWeeperLightBird LightBird)
	{
		bIlluminated = true;

		Bird = LightBird;
	}



	UFUNCTION()
	private void OnUnilluminated(ASanctuaryWeeperLightBird LightBird)
	{
		bIlluminated = false;

		if(bActivated)
		{
			Deactivate();
		}
	}

	
};