class ASanctuaryCipherLetter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TileMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LetterMesh;

	UMaterialInstanceDynamic FadeMaterial = nullptr;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent HighlightVFX;

	UPROPERTY(EditInstanceOnly)
	FString DefaultLetter;

	float bHighlightingTimer = -1.0;
	bool bHighlighting = false;
	float VFXTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FadeMaterial = Material::CreateDynamicMaterialInstance(this, LetterMesh.GetMaterial(0));
		LetterMesh.SetMaterial(0, FadeMaterial);
		FadeMaterial.SetScalarParameterValue(n"Radius", 0.0);
		FadeMaterial.SetScalarParameterValue(n"Fade", 0.0);

		LetterMesh.SetVisibility(false);
		if (DefaultLetter.Len() == 1)
			SetLetter(DefaultLetter);
		
		HighlightVFX.Deactivate();
	}

	void SetLetter(FString Letter)
	{
		BP_SetLetter(Letter);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SetLetter(FString Letter) {}

	void StartHighlight()
	{
		// bHighlighting = true;
		// LetterMesh.SetVisibility(true);
		VFXTimer = 1.0;
		HighlightVFX.Activate();
		// if (HighlightVFX != nullptr)
		// {
		// 	Niagara::SpawnOneShotNiagaraSystemAtLocation(HighlightVFX, ActorLocation + ActorForwardVector * 10.0);
		// }
	}

	void StopHighlight()
	{
		bHighlighting = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		VFXTimer -= DeltaSeconds;
		if (HighlightVFX.IsActive() && VFXTimer < 0.0)
			HighlightVFX.Deactivate();

		if (bHighlighting)
		{
			if (bHighlightingTimer >= 1.0)
			{
				bHighlighting = false;
				return;
			}

			bHighlightingTimer = 1.0; //Math::Clamp(bHighlightingTimer + DeltaSeconds, 0.0, 1.0);
			FadeMaterial.SetScalarParameterValue(n"Radius", Math::SinusoidalInOut(0.0, 100.0, bHighlightingTimer));
			FadeMaterial.SetScalarParameterValue(n"Fade", Math::SinusoidalInOut(0.0, 5.0, bHighlightingTimer));
		}
		else
		{
			if (bHighlightingTimer <= 0.0)
				return;

			bHighlightingTimer = Math::Clamp(bHighlightingTimer - DeltaSeconds * 0.5, 0.0, 1.0);
			FadeMaterial.SetScalarParameterValue(n"Radius", Math::SinusoidalInOut(0.0, 100.0, bHighlightingTimer));
			FadeMaterial.SetScalarParameterValue(n"Fade", Math::SinusoidalInOut(0.0, 5.0, bHighlightingTimer));
		}
	}
};