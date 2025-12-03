enum EMoonMarketRouletteSymbolType
{
	Broom,
	Cat,
	Mushroom,
	WitchHat,
	MushroomMan,
	Statue
}

struct FMoonMarketRouletteSymbolData
{
	UPROPERTY()
	EMoonMarketRouletteSymbolType Type;
}

class AMoonMarketSymbolCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent IndicatorPad;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BroomSymbol;
	default BroomSymbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CatSymbol;
	default CatSymbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MushroomSymbol;
	default MushroomSymbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent WitchHatSymbol;
	default WitchHatSymbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MushroomManSymbol;
	default MushroomManSymbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent StatueManSymbol;
	default StatueManSymbol.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ProgressMeshScalar1;
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ProgressMeshScalar2;
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ProgressMeshScalar3;
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ProgressMeshScalar4;
	TArray<USceneComponent> ProgressMeshes;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent MagicEffect;
	default MagicEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(EditInstanceOnly)
	EMoonMarketRouletteSymbolType Type;

	UPROPERTY(EditInstanceOnly)
	bool bUsedByCatHead;

	UPROPERTY(EditDefaultsOnly)
	TArray<FMoonMarketRouletteSymbolData> SymbolData;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface CorrectMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface IncorrectMaterial;
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface HighlightMaterial;

	UMaterialInterface DefaultMaterial;
	
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface IndicatorHighlightMat;
	UMaterialInterface IndicatorDefaultMat;

	FVector StartLocation;
	FVector EndLocation;
	float MoveSpeed = 3800.0;
	float ZOffset = 5000.0;

	bool bCubeActive;

	float TimerXScale;
	float TimerYScale;
	float TimerZScale;

	bool bPlayerIsTouching;
	bool bAnswerSet;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PickSymbol();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EndLocation = MeshRoot.RelativeLocation;
		StartLocation = MeshRoot.RelativeLocation - FVector::UpVector * ZOffset;

		if (!bUsedByCatHead)
			MeshRoot.RelativeLocation = StartLocation;
		
		DefaultMaterial = MeshComp.GetMaterial(0);

		if (!bUsedByCatHead)
			SetCubeInactive();

		ProgressMeshes.Add(ProgressMeshScalar1);
		ProgressMeshes.Add(ProgressMeshScalar2);
		ProgressMeshes.Add(ProgressMeshScalar3);
		ProgressMeshes.Add(ProgressMeshScalar4);
		HideTimers();

		for (USceneComponent CurrentTimer : ProgressMeshes)
		{
			auto CurrentMeshComp = Cast<UStaticMeshComponent>(CurrentTimer.GetChildComponent(0));
			CurrentMeshComp.SetMaterial(0, GetCorrectSymbolMaterial());
		}

		TimerXScale = ProgressMeshScalar1.RelativeScale3D.X;
		TimerYScale = ProgressMeshScalar1.RelativeScale3D.Y;
		TimerZScale = ProgressMeshScalar1.RelativeScale3D.Z;
	
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this, n"OnAnyImpactByPlayer");
		ImpactComp.OnAnyImpactByPlayerEnded.AddUFunction(this, n"OnAnyImpactByPlayerEnded");

		IndicatorDefaultMat = IndicatorPad.GetMaterial(0); 
	}

	UFUNCTION()
	private void OnAnyImpactByPlayer(AHazePlayerCharacter Player)
	{
		// if (bAnswerSet)
		// 	return;

		// IndicatorPad.SetMaterial(0, IndicatorHighlightMat);
		// bPlayerIsTouching = true;
	}

	UFUNCTION()
	private void OnAnyImpactByPlayerEnded(AHazePlayerCharacter Player)
	{
		// if (bAnswerSet)
		// 	return;

		// if (!ImpactComp.HasAnyPlayerImpact())
		// {
		// 	IndicatorPad.SetMaterial(0, IndicatorDefaultMat);
		// 	bPlayerIsTouching = false;
		// }
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bUsedByCatHead)
			return;

		FVector TargetLocation;

		if (bCubeActive)
		{
			TargetLocation = EndLocation;
		}
		else
		{
			TargetLocation = StartLocation;
		}

		if (MeshRoot.RelativeLocation != TargetLocation)
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, TargetLocation, DeltaSeconds, MoveSpeed);
	}

	void ChangeType(EMoonMarketRouletteSymbolType InType)
	{
		Type = InType;
		PickSymbol();
	}

	private void PickSymbol()
	{
		BroomSymbol.SetHiddenInGame(true);
		CatSymbol.SetHiddenInGame(true);
		MushroomSymbol.SetHiddenInGame(true);
		WitchHatSymbol.SetHiddenInGame(true);
		MushroomManSymbol.SetHiddenInGame(true);
		StatueManSymbol.SetHiddenInGame(true);

		UStaticMeshComponent ChosenComp;

		switch (Type)
		{
			case EMoonMarketRouletteSymbolType::Broom:
				ChosenComp = BroomSymbol;
				break;
			case EMoonMarketRouletteSymbolType::Cat:
				ChosenComp = CatSymbol;
				break;
			case EMoonMarketRouletteSymbolType::Mushroom:
				ChosenComp = MushroomSymbol;
				break;
			case EMoonMarketRouletteSymbolType::WitchHat:
				ChosenComp = WitchHatSymbol;
				break;
			case EMoonMarketRouletteSymbolType::MushroomMan:
				ChosenComp = MushroomManSymbol;
				break;
			case EMoonMarketRouletteSymbolType::Statue:
				ChosenComp = StatueManSymbol;
				break;
		}

		ChosenComp.SetHiddenInGame(false);
	}

	UMaterialInterface GetCorrectSymbolMaterial()
	{
		UMaterialInterface ChosenMat;

		switch (Type)
		{
			case EMoonMarketRouletteSymbolType::Broom:
				ChosenMat = BroomSymbol.GetMaterial(0);
				break;
			case EMoonMarketRouletteSymbolType::Cat:
				ChosenMat = CatSymbol.GetMaterial(0);
				break;
			case EMoonMarketRouletteSymbolType::Mushroom:
				ChosenMat = MushroomSymbol.GetMaterial(0);
				break;
			case EMoonMarketRouletteSymbolType::WitchHat:
				ChosenMat = WitchHatSymbol.GetMaterial(0);
				break;
			case EMoonMarketRouletteSymbolType::MushroomMan:
				ChosenMat = MushroomManSymbol.GetMaterial(0);
				break;
			case EMoonMarketRouletteSymbolType::Statue:
				ChosenMat = StatueManSymbol.GetMaterial(0);
				break;
		}		

		return ChosenMat;
	}

	int NumberOfPlayers()
	{
		return ImpactComp.GetImpactingPlayers().Num();
	}

	void ActivateCube()
	{
		SetCubeActive();
		// MagicEffect.Activate();
	}

	void DeactivateCube()
	{
		MeshComp.SetMaterial(0, DefaultMaterial);
		SetCubeInactive();
		bAnswerSet = false;
		IndicatorPad.SetMaterial(0, IndicatorDefaultMat);
		// MagicEffect.Activate();
	}

	void InitiateCube()
	{
		SetCubeInactive();
	}

	void SetCubeAnswer(bool bIsCorrectAnswer)
	{
		if (bIsCorrectAnswer)
			IndicatorPad.SetMaterial(0, CorrectMaterial);
		else
			IndicatorPad.SetMaterial(0, IncorrectMaterial);

		bAnswerSet = bIsCorrectAnswer;
	}

	void ManuallySetType(EMoonMarketRouletteSymbolType ChosenType)
	{
		Type = ChosenType;
		PickSymbol();
	}

	void ShowTimers()
	{
		for (USceneComponent Timer : ProgressMeshes)
		{
			Timer.SetHiddenInGame(false);
		}
	}

	void UpdateTimers(float Alpha)
	{
		float ClampedAlpha = Math::Clamp(Alpha, 0.05, 1.0);
		for (USceneComponent Timer : ProgressMeshes)
		{
			Timer.SetRelativeScale3D(FVector(TimerXScale * ClampedAlpha, TimerYScale, TimerZScale));
		}	
	}

	void HideTimers()
	{
		for (USceneComponent Timer : ProgressMeshes)
		{
			Timer.SetHiddenInGame(true);
		}	
	}

	private void SetCubeActive()
	{
		bCubeActive = true;
		// SetActorHiddenInGame(false);
		// SetActorEnableCollision(true);
	}

	private void SetCubeInactive()
	{
		bCubeActive = false;
		// SetActorHiddenInGame(true);
		// SetActorEnableCollision(false);
	}
};