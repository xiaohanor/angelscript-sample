class AEvergreenMegaCircle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MegaCircleMesh;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;
	default SyncedRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 10;

	UPROPERTY(EditAnywhere)
	float MaskOffset = 0;

	FRotator NewRotation;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager LifeManager;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFXLeft;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent VFXRight;

	float EmissiveValue = 0;

	bool bHasStartedVFX = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		SyncedRotation.Value = MegaCircleMesh.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			SyncedRotation.Value += FRotator(0, 0, LifeManager.LifeComp.HorizontalAlpha * RotationSpeed * DeltaSeconds);
		}

		EmissiveValue = Math::FInterpTo(EmissiveValue, Math::Saturate(Math::Abs(LifeManager.LifeComp.HorizontalAlpha) + VO::GetZoeGaiaVoiceVolume()), DeltaSeconds, 3);

		PrintToScreen(""+ EmissiveValue);
		
		MegaCircleMesh.SetScalarParameterValueOnMaterialIndex(0, n"LifeGivingAlpha", EmissiveValue);
		MegaCircleMesh.SetScalarParameterValueOnMaterialIndex(0, n"HeightMask", GetActorLocation().Z + MaskOffset);
		MegaCircleMesh.SetScalarParameterValueOnMaterialIndex(1, n"HeightMask", GetActorLocation().Z + MaskOffset);
		MegaCircleMesh.SetRelativeRotation(SyncedRotation.Value);

		if(Math::Abs(LifeManager.LifeComp.HorizontalAlpha) >= 0.2 && !bHasStartedVFX)
		{
			StartVFX();
			bHasStartedVFX = true;
		}
		else if(Math::Abs(LifeManager.LifeComp.HorizontalAlpha) < 0.2 && bHasStartedVFX)
		{
			StopVFX();
			bHasStartedVFX = false;
		}
	}

	UFUNCTION()
	void StartVFX()
	{
		VFXLeft.Activate();
		VFXRight.Activate();
	}

	UFUNCTION()
	void StopVFX()
	{
		VFXLeft.Deactivate();
		VFXRight.Deactivate();
	}


	


};