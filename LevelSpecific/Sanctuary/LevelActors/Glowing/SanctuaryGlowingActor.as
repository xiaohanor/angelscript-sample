class ASanctuaryGlowingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LightEffect;
	default LightEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UPointLightComponent LightComp;

	UPROPERTY(DefaultComponent)
	ULightBeamResponseComponent LightBeamComp;


	UPROPERTY()
    UMaterialInstance Material;
	UPROPERTY()
	UMaterialInstanceDynamic DynamicMaterial;

	float Alpha;
	float ChargedGlowTime = 3.0;
	float GlowTime = 1.0;
	float TimeAtFullyCharged;
	float TimeAtOnHitEnd;
	bool isCharging;
	bool isFullyCharged;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBeamComp.OnHitBegin.AddUFunction(this, n"OnHitBegin");
		LightBeamComp.OnHitEnd.AddUFunction(this, n"OnHitEnd");

		DynamicMaterial = MeshComp.CreateDynamicMaterialInstance(0);

	
		MeshComp.Materials[0] = DynamicMaterial;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if(isCharging)
		{
			if(!isFullyCharged)
			{
				if(Alpha < 1.0)
					Alpha += DeltaSeconds;
				else
					FullyCharged();
			}
			
		}
		else if(!isCharging)
		{

			if(!isFullyCharged && Alpha > 0.0)
				if(TimeAtOnHitEnd + GlowTime < Time::GameTimeSeconds)
				{
					Alpha -= DeltaSeconds;
				}

		}
		Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		LightComp.SetIntensity(Alpha * 1000000.0);
		DynamicMaterial.SetScalarParameterValue(n"Alpha", Alpha);


		if(isFullyCharged)
			if(TimeAtFullyCharged + ChargedGlowTime < Time::GameTimeSeconds)
				isFullyCharged = false;
	}

	void FullyCharged()
	{
		isFullyCharged = true;
		TimeAtFullyCharged = Time::GameTimeSeconds;
		//LightEffect.Activate();
		Print("Charged");

	}

	UFUNCTION()
	private void OnHitBegin(AHazePlayerCharacter Instigator)
	{
		isCharging = true;
	}

	UFUNCTION()
	private void OnHitEnd(AHazePlayerCharacter Instigator)
	{
		isCharging = false;
		TimeAtOnHitEnd = Time::GameTimeSeconds;
	}

}