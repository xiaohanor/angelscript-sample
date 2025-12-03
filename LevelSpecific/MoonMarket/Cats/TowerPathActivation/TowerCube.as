// event void FOnTowerCubeActivated();
// event void FOnTowerCubeDeactivated();
event void FOnTowerCubeThrowPlayersOff();

class ATowerCube : AHazeActor
{
	UPROPERTY()
	FOnTowerCubeThrowPlayersOff OnTowerCubeThrowPlayersOff;
	// UPROPERTY()
	// FOnTowerCubeActivated OnTowerCubeActivated;

	// UPROPERTY()
	// FOnTowerCubeDeactivated OnTowerCubeDeactivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SymbolsZoe;
	default SymbolsZoe.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	// default SymbolsZoe.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SymbolsElla;
	default SymbolsElla.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	// default SymbolsElla.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"TowerCubeRotationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TowerCubeDefaultMoveCapability");

	UPROPERTY(DefaultComponent)
	UNiagaraComponent MagicEffect;
	default MagicEffect.SetAutoActivate(false);

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface EllaMat;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ZoeMat;
	TPerPlayer<UMaterialInterface> OriginalMats;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface CubeReadyMat;
	UMaterialInterface CubeOriginalMat;

	UPROPERTY(EditInstanceOnly)
	TArray<ATowerCube> ConnectedCubes;

	UPROPERTY(EditInstanceOnly)
	TArray<ATowerCube> PreviousCubes;

	UPROPERTY(EditInstanceOnly)
	bool bIsDefaultCube = false;
	bool bIsActive;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bIsDefaultCube", EditConditionHides))
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bIsDefaultCube", EditConditionHides))
	EHazePlayer TargetPlayer;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bIsDefaultCube", EditConditionHides))
	ATowerCube ConnectedDefaultCube;

	FVector CubeDefaultPosition;
	float DefaultCubeOffset = 500.0;
	bool bPlayersInteracted;
	TPerPlayer<bool> bPlayersOn;

	bool bHasBeenActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalMats[Game::Zoe] = SymbolsZoe.GetMaterial(0);
		OriginalMats[Game::Mio] = SymbolsElla.GetMaterial(0);

		CubeOriginalMat = MeshComp.GetMaterial(0);
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this, n"OnAnyImpactByPlayer");
		ImpactComp.OnAnyImpactByPlayerEnded.AddUFunction(this, n"OnAnyImpactByPlayerEnded");
		bIsActive = bIsDefaultCube;

		if (bIsDefaultCube)
		{
			//Set the opposite hidden
			if (TargetPlayer == EHazePlayer::Mio)
				SymbolsZoe.SetHiddenInGame(true);
			else
				SymbolsElla.SetHiddenInGame(true);

			CubeDefaultPosition = ActorLocation;
			ActorLocation -= ActorForwardVector * DefaultCubeOffset;
		}

		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);

		if (DoubleInteract != nullptr)
			DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		DoubleInteract.AddActorDisable(this);
		bPlayersInteracted = true;
		bIsActive = true;
		SetActorEnableCollision(true);
		SetActorHiddenInGame(false);
		UTowerCubeEffectHandler::Trigger_OnDefaultCubeDoubleInteractActivated(this, FTowerCubeParams(ActorLocation));
	}

	void ActivateCube()
	{
		bIsActive = true;
		SetActorEnableCollision(true);
		SetActorHiddenInGame(false);
		MagicEffect.Activate();
		UTowerCubeEffectHandler::Trigger_OnCubeActivated(this, FTowerCubeParams(ActorLocation));
	}

	void DeactivateCube()
	{
		bHasBeenActivated = false;

		if (bIsDefaultCube)
		{
			ResetDefault();	
			return;
		}

		bIsActive = false;
		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);
		MagicEffect.Activate();
		UTowerCubeEffectHandler::Trigger_OnCubeDeactivate(this, FTowerCubeParams(ActorLocation));
	}

	UFUNCTION()
	private void OnAnyImpactByPlayer(AHazePlayerCharacter Player)
	{
		bPlayersOn[Player] = true;

		if (bIsDefaultCube)
		{
			if (TargetPlayer == EHazePlayer::Mio && Player.IsMio())
			{
				SymbolsElla.SetMaterial(0, EllaMat);
				Print("OnAnyImpactByPlayer: " + ZoeMat.Name);
			}
			else if (TargetPlayer == EHazePlayer::Zoe && Player.IsZoe())
			{
				SymbolsZoe.SetMaterial(0, ZoeMat);
				Print("OnAnyImpactByPlayer: " + EllaMat.Name);
			}

			if (ConnectedDefaultCube.bPlayersOn[Player.OtherPlayer])
			{
				ConnectedDefaultCube.SetNextReady();
				SetNextReady();				
			}

			return;
		}

		if (Player.IsMio())
			SymbolsElla.SetMaterial(0, EllaMat);
		else
			SymbolsZoe.SetMaterial(0, ZoeMat);

		
		if (bPlayersOn[Player] && bPlayersOn[Player.OtherPlayer])
		{
			SetNextReady();
		}
	}

	UFUNCTION()
	private void OnAnyImpactByPlayerEnded(AHazePlayerCharacter Player)
	{
		if (bIsDefaultCube && bHasBeenActivated)
			return;
		Print("OnAnyImpactByPlayerEnded: " + OriginalMats[Player].Name);

		if (Player.IsMio())
			SymbolsElla.SetMaterial(0, OriginalMats[Player]);
		else
			SymbolsZoe.SetMaterial(0, OriginalMats[Player]);

		MeshComp.SetMaterial(0, CubeOriginalMat);
		bPlayersOn[Player] = false;
	}

	void ResetDefault()
	{
		SymbolsElla.SetMaterial(0, OriginalMats[Game::Mio]);
		SymbolsZoe.SetMaterial(0, OriginalMats[Game::Zoe]);
		MeshComp.SetMaterial(0, CubeOriginalMat);
	}

	void SetNextReady()
	{
		// if (bHasBeenActivated && bIsDefaultCube)
		// 	return;

		MeshComp.SetMaterial(0, CubeReadyMat);
		bHasBeenActivated = true;

		for (ATowerCube Cube : ConnectedCubes)
		{
			if (!Cube.bIsActive)
				Cube.ActivateCube();
		}

		for (ATowerCube Cube : PreviousCubes)
		{
			if (Cube.bIsActive)
				Cube.DeactivateCube();
		}
	}
};