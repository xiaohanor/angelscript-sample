class ASolarFlareTriggerShield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent StaticMeshComp;
	default StaticMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent ActivateSystem;
	default ActivateSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent DeactivateSystem;
	default DeactivateSystem.SetAutoActivate(false);

	UMaterialInstanceDynamic DynamicMat;

	UFUNCTION(BlueprintEvent)
	void BP_OnShieldCollected(const AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent)
	void OnShieldUnavailable(const AHazePlayerCharacter Player) {}

	float MaxFrames = 30.0;
	float Frame = 1.0;

	bool bOn;
	float ImpactTime;

	float FadeAlpha = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DynamicMat = StaticMeshComp.CreateDynamicMaterialInstance(0);
		DynamicMat.SetScalarParameterValue(n"Display Frame", Frame);
		DynamicMat.SetScalarParameterValue(n"Auto Playback", 0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bOn)
		{
			FadeAlpha = Math::FInterpConstantTo(FadeAlpha, 0, DeltaSeconds, 2.5);
		}
		else
		{
			if (Frame < MaxFrames)
				Frame += MaxFrames * DeltaSeconds;

			Frame = Math::Clamp(Frame, 1, 30);

			if (ImpactTime > 0.0)
				ImpactTime -= DeltaSeconds;
			else
				FadeAlpha = Math::FInterpConstantTo(FadeAlpha, 1, DeltaSeconds, 3.5);
		}

		DynamicMat.SetScalarParameterValue(n"Display Frame", Frame);
		DynamicMat.SetScalarParameterValue(n"FadeIn", FadeAlpha);
	}

	void TurnOn()
	{
		bOn = true;
		ActivateSystem.Activate();
		Frame = 1.0;
	}

	void TurnOff()
	{
		bOn = false;
		DeactivateSystem.Activate();
	}

	void RunImpact()
	{
		ImpactTime = 1.0;
		bOn = false;
	}
};