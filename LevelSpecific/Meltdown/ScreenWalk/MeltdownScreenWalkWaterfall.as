class AMeltdownScreenWalkWaterfall : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TempSphere;
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TempBox;

	UPROPERTY()
	UNiagaraSystem SplashVFX;

	UPROPERTY()
	UMaterialParameterCollection VFXParameterCollection;

	UPROPERTY(EditAnywhere)
	float ZoeSphereSize = 200.0;

	bool bMioIsOverlapping = false;
	bool bMioIsFalling = false;
	bool bSphereMaskActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerBeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleTriggerEndOverlap");
	}

	UFUNCTION()
	private void HandleTriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                       bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (OtherActor == Game::Mio)
		{
			bMioIsOverlapping = true;
		}
	}
	
	UFUNCTION()
	private void HandleTriggerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (OtherActor == Game::Mio)
		{
			bMioIsOverlapping = false;
		}
	}

	// bool GetZoePositionOnWaterfall(FVector& OutPoint) const
	// {
	// 	auto Manager = AMeltdownScreenWalkManager::Get();
	// 	if (Manager.bScreenWalkRayActive)
	// 	{
	// 		OutPoint = Math::LinePlaneIntersection(
	// 			Manager.ScreenWalkRayOrigin,
	// 			Manager.ScreenWalkRayOrigin + Manager.ScreenWalkRayDirection,
	// 			TriggerComp.WorldLocation,
	// 			TriggerComp.UpVector,
	// 		);

	// 		FBox Box(-TriggerComp.BoxExtent, TriggerComp.BoxExtent);
	// 		FVector LocalPoint = TriggerComp.WorldTransform.InverseTransformPosition(OutPoint);

	// 		FVector ClosestPoint = TriggerComp.WorldTransform.TransformPosition(Box.GetClosestPointTo(LocalPoint));
	// 		return ClosestPoint.Distance(OutPoint) < ZoeSphereSize + 80.0;
	// 	}
	// 	else
	// 	{
	// 		return false;
	// 	}
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bMioIsCovered = false;

		FVector Position;
		// if (GetZoePositionOnWaterfall(Position))
		// {
		// 	bSphereMaskActive = true;
		// 	Material::SetVectorParameterValue(VFXParameterCollection, n"SphereMask", FLinearColor(
		// 		Position.X, Position.Y, Position.Z, ZoeSphereSize,
		// 	));

		// 	// TempSphere.SetHiddenInGame(false);
		// 	// TempSphere.WorldLocation = Position;
		// 	// TempSphere.WorldScale3D = FVector(ZoeSphereSize / 50.0, ZoeSphereSize / 50.0, 0.3);

		// 	// TempBox.SetHiddenInGame(false);
		// 	// TempBox.WorldLocation = Position - FVector(0, 0, 1000);
		// 	// TempBox.WorldScale3D = FVector(ZoeSphereSize / 50.0, 1000/50.0, 0.3);

		// 	FVector ScreenDirection = ActorForwardVector;
		// 	FVector DeltaToMio = (Position - Game::Mio.ActorLocation);
		// 	float DistanceForMio = Math::Abs(DeltaToMio.DotProduct(ScreenDirection));

		// 	if (Position.Z > Game::Mio.ActorLocation.Z && DistanceForMio < ZoeSphereSize)
		// 		bMioIsCovered = true;
		// }			
		// else
		// {
		// 	if (bSphereMaskActive)
		// 	{
		// 		bSphereMaskActive = false;
		// 		Material::SetVectorParameterValue(VFXParameterCollection, n"SphereMask", FLinearColor(
		// 			0, 0, 0, 0
		// 		));
		// 	}

		// 	TempSphere.SetHiddenInGame(true);
		// 	TempBox.SetHiddenInGame(true);
		// }

		const bool bMioShouldFall = bMioIsOverlapping && !bMioIsCovered;
		if (bMioShouldFall)
		{
			if (!bMioIsFalling)
			{
				StartFalling(Game::Mio);
				bMioIsFalling = true;
			}

			FVector Force;
			Force += FVector::UpVector * -1000.0;
			Force += ActorUpVector * 1000.0;

			Game::Mio.AddMovementImpulse(Force * DeltaSeconds);
		}
		else
		{
			if (bMioIsFalling)
			{
				StopFalling(Game::Mio);
				bMioIsFalling = false;
			}
		}
	}

	private void StartFalling(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);	
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::FloorMotion, this);
		Player.BlockCapabilities(n"SplineLock", this);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(SplashVFX, Player.ActorLocation);
	}

	private void StopFalling(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::FloorMotion, this);
		Player.UnblockCapabilities(n"SplineLock", this);
	}
};