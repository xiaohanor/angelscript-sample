class ASolarFlareFireWaveActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(50.0));
#endif

	UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D WallSceneCaptureComp;
	default WallSceneCaptureComp.ProjectionType = ECameraProjectionMode::Orthographic;
	default WallSceneCaptureComp.CaptureSource = ESceneCaptureSource::SCS_SceneDepth;
	default WallSceneCaptureComp.bCaptureEveryFrame = false;
	default WallSceneCaptureComp.bCaptureOnMovement = false;
	//default WallSceneCaptureComp.MaxViewDistanceOverride 100;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent WallMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
	
	UPROPERTY(Category = Setup)
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UPROPERTY()
	float OrthoWidth = 50000;

	// Target that the camera draws to
	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D WallSceneCaptureCompTarget;

	// Target that the camera draw is "appended" to.
	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D WallTarget0;
	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D WallTarget1;

	// Material that "adds" new holes to the wall using the data captured by the Scene Capture Component
	UPROPERTY(EditAnywhere)
	UMaterialInterface WallAddHoleMaterial;
	UPROPERTY(EditAnywhere)
	UMaterialInstanceDynamic WallAddHoleMaterialInstanceDynamic;
	
	// The material for the wall mesh itself.
	UPROPERTY(EditAnywhere)
	UMaterialInstanceDynamic WallMaterialInstanceDynamic;

	UPROPERTY()
	bool flip = false;

	TPerPlayer<USolarFlarePlayerComponent> SolarComps;

	FVector StartLocation;

	float MoveSpeed = 145000.0;

	float WaveTravelTime;
	float WaveTravelDuration = 5.0;

	float CanKillTime;
	float CanKillDuration;

	bool bNewActive;
	bool bCanKill;
	TPerPlayer<bool> bPlayedCameraShake;

	UMaterialInstanceDynamic DynamicMat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		SetActorTickEnabled(false);

		DynamicMat = Material::CreateDynamicMaterialInstance(this, WallMesh.Materials[0]);
		DynamicMat.SetScalarParameterValue(n"Opacity", 0.0);
		WallMesh.SetMaterial(0, DynamicMat);

		// Set up capture stuff
		WallSceneCaptureCompTarget = Rendering::CreateRenderTarget2D(1024, 1024, ETextureRenderTargetFormat::RTF_R16f);
		WallTarget0 = Rendering::CreateRenderTarget2D(1024, 1024, ETextureRenderTargetFormat::RTF_R8);
		WallTarget1 = Rendering::CreateRenderTarget2D(1024, 1024, ETextureRenderTargetFormat::RTF_R8);
		WallAddHoleMaterialInstanceDynamic = Material::CreateDynamicMaterialInstance(this, WallAddHoleMaterial);
		WallSceneCaptureComp.TextureTarget = WallSceneCaptureCompTarget;
		WallMaterialInstanceDynamic = WallMesh.CreateDynamicMaterialInstance(0);
	 	WallSceneCaptureComp.OrthoWidth = OrthoWidth;
		WallMesh.SetHiddenInGame(true);
	}

	FVector LastActorLocation;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Figure out how far we moved since last frame
		float DistanceMoved = LastActorLocation.Distance(ActorLocation);
		
		// Scene capture comp lags one frame behind so it can collide with all the geometry correctly.
		WallSceneCaptureComp.SetWorldLocation(LastActorLocation);
		WallSceneCaptureComp.MaxViewDistanceOverride = Math::Max(DistanceMoved, 0.001);
		WallSceneCaptureComp.CaptureScene();

		LastActorLocation = ActorLocation;
		
		// "Append" the collided geometry to the wall texture.
		UTextureRenderTarget2D Previous = flip ? WallTarget0 : WallTarget1;
		UTextureRenderTarget2D Current  = flip ? WallTarget1 : WallTarget0;
		WallAddHoleMaterialInstanceDynamic.SetTextureParameterValue(n"PreviousTexture", Previous);
		WallAddHoleMaterialInstanceDynamic.SetTextureParameterValue(n"NewCapture", WallSceneCaptureCompTarget);
		WallAddHoleMaterialInstanceDynamic.SetScalarParameterValue(n"BlurStrength", Math::RandRange(0.1, 2.0));
		Rendering::DrawMaterialToRenderTarget(Current, WallAddHoleMaterialInstanceDynamic);

		WallMaterialInstanceDynamic.SetTextureParameterValue(n"InputTexture", Current);
		WallMaterialInstanceDynamic.SetScalarParameterValue(n"OrthoWidth", OrthoWidth);
		flip = !flip;

		ActorLocation += ActorForwardVector * MoveSpeed * DeltaSeconds;
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			KillCheckPlayer(Player);
		}

		if (Time::GameTimeSeconds > WaveTravelTime)
			DeactivateWave();
	}

	void KillCheckPlayer(AHazePlayerCharacter Player)
	{
		USolarFlarePlayerComponent PlayerComp = USolarFlarePlayerComponent::Get(Player);
		
		if (GetPlaneDistanceTo(Player.ActorLocation) < 0.0)
		{
			if (!bPlayedCameraShake[Player])
			{
				bPlayedCameraShake[Player] = true;
				Player.PlayCameraShake(ImpactCameraShake, this);
			}
		}

		if (bNewActive && !bCanKill && GetPlaneDistanceTo(Player.ActorLocation) < 0.0)
		{
			bCanKill= true;
			bNewActive = false;
			CanKillTime = Time::GameTimeSeconds + CanKillDuration;
		}

		if (bCanKill && PlayerComp.CanKillPlayer() && !Player.IsPlayerDead())
			Player.KillPlayer();

		if (bCanKill && Time::GameTimeSeconds > CanKillTime)
		{
			bCanKill = false;
		}
	}

	void ActivateWave()
	{
		Rendering::ClearRenderTarget2D(WallTarget0, FLinearColor(1,1,1,1));
		Rendering::ClearRenderTarget2D(WallTarget1, FLinearColor(1,1,1,1));

		LastActorLocation = ActorLocation;

		SetActorTickEnabled(true);
		WallMesh.SetHiddenInGame(false);
		bNewActive = true;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			bPlayedCameraShake[Player] = false;
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			SolarComps[Player] = USolarFlarePlayerComponent::Get(Player);
		}

		ActorLocation = StartLocation;

		FSolarFlareActivateWaveParams Params;
		Params.SpawnLoc = ActorLocation;
		Params.AttachComp = Root; 
		USolarFlareFireWaveEffectHandler::Trigger_ActivateWave(this, Params);

		WaveTravelTime = Time::GameTimeSeconds + WaveTravelDuration;

		BP_ActivateWaveEvent();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_ActivateWaveEvent() {}

	UFUNCTION()
	void SetFireWaveOpacity(float Opacity)
	{
		DynamicMat.SetScalarParameterValue(n"Opacity", Opacity);
	}

	void DeactivateWave()
	{
		SetActorTickEnabled(false);
		USolarFlareFireWaveEffectHandler::Trigger_DeactivateWave(this);
		WallMesh.SetHiddenInGame(true);
		SetFireWaveOpacity(0.0);
	}

	float GetPlaneDistanceTo(FVector Location)
	{
		FVector Delta = Location - ActorLocation;
		return ActorForwardVector.DotProduct(Delta);
	}
}