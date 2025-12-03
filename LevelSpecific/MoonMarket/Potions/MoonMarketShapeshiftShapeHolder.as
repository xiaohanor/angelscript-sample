class AMoonMarketShapeshiftShapeHolder : AMoonMarketInteractableActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	default InteractableTag = EMoonMarketInteractableTag::Shapeshift;

	AHazeActor CurrentShape;
	bool bDestroyOnUnshapeshift = true;
	bool bOverrideSize = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		InteractComp.Disable(this);
	}

	void SetShape(AHazeActor Shape, AActor Owner, bool bInDestroyOnUnshapeshift)
	{
		bDestroyOnUnshapeshift = bInDestroyOnUnshapeshift;
		CurrentShape = Shape;
		AttachToActor(Owner);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if(Player != nullptr)
		{
			OnInteractionStarted(InteractComp, Player);

			UMoonMarketPolymorphShapeComponent ShapeComp = UMoonMarketPolymorphShapeComponent::Get(Shape);
			if(ShapeComp != nullptr)
			{
				bOverrideSize = true;
				Player.CapsuleComponent.OverrideCapsuleRadius(ShapeComp.ShapeData.Radius, this);
			}
		}
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		if(!CanExitShape())
			Player.KillPlayer();
		
		Super::OnInteractionStopped(Player);

		if(bOverrideSize)
		{
			Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
		}

		if(CurrentShape != nullptr && bDestroyOnUnshapeshift)
			CurrentShape.DestroyActor();

		if(UMoonMarketShapeshiftComponent::Get(Player).ShapeshiftShape == this)
			UMoonMarketShapeshiftComponent::Get(Player).UnsetShape();
	}

	bool CanExitShape()
	{
		UMoonMarketPolymorphShapeComponent ShapeComp = UMoonMarketPolymorphShapeComponent::Get(CurrentShape);
		if(ShapeComp == nullptr)
			return true;

		FVector2D NewCapsuleSize = InteractingPlayer.CapsuleComponent.DefaultSize;
		FVector Origin = InteractingPlayer.ActorLocation + FVector::UpVector * NewCapsuleSize.Y / 2;

		FHazeTraceSettings Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.IgnorePlayers();
		Trace.UseSphereShape(NewCapsuleSize.X + 5);
		//Trace.DebugDrawOneFrame();

		FHitResultArray Hits = Trace.QueryTraceMulti(Origin, Origin + FVector::UpVector * NewCapsuleSize.Y);
		TArray<FVector> Normals = GetValidNormals(Hits);

		if(Normals.Num() <= 1)
			return true;

		if(AllNormalsAligned(Normals))
			return true;

		FVector TestTraceDirection;
		if(!FindAWayOut(Hits, TestTraceDirection))
			return false;

		//Debug::DrawDebugArrow(Origin, Origin + TestTraceDirection * 50, 100, FLinearColor::Green, bDrawInForeground = true);
		Origin += TestTraceDirection.VectorPlaneProject(FVector::UpVector) * NewCapsuleSize.X;
		Trace.UseSphereShape(NewCapsuleSize.X);
		Hits = Trace.QueryTraceMulti(Origin, Origin + FVector::UpVector * NewCapsuleSize.Y);
		Normals = GetValidNormals(Hits);

		if(Normals.Num() <= 1)
			return true;

		//Debug::DrawDebugArrow(Origin, Origin + TestTraceDirection * 50, 100, FLinearColor::Red, bDrawInForeground = true);
		return false;
	}

	TArray<FVector> GetValidNormals(FHitResultArray Hits)
	{
		TArray<FVector> Normals;
		for(int i = 0; i < Hits.Num(); i++)
		{
			if(!Hits[i].bBlockingHit)
				continue;

			float DotUp = Hits[i].ImpactNormal.DotProduct(FVector::UpVector);
			if(DotUp > 0.5)
				continue;

			if(DotUp < -0.5)
				continue;

			Normals.Add(Hits[i].ImpactNormal * Hits[i].PenetrationDepth);
			Debug::DrawDebugArrow(Hits[i].ImpactPoint, Hits[i].ImpactPoint + Hits[i].ImpactNormal * 50, 100, FLinearColor::White, bDrawInForeground = true);
		}
		return Normals;
	}

	private bool IsPointingUpwards(FVector Direction) const
    {
        return Direction.GetAngleDegreesTo(FVector::UpVector) <= 45.0;
    }

    private bool IsPointingDownwards(FVector Direction) const
    {
        return Direction.GetAngleDegreesTo(FVector::UpVector) >= 135.0;
    }

	bool AllNormalsAligned(TArray<FVector> Normals)
	{
		for(int i = 0; i < Normals.Num() - 1; i++)
		{
			for(int j = i+1; j < Normals.Num(); j++)
			{
				if(Normals[i].DotProduct(Normals[j]) < -0.3)
				{
					return false;
				}
			}
		}

		return true;
	}

	bool FindAWayOut(FHitResultArray Hits, FVector& OutVector)
	{
		auto Normals = GetValidNormals(Hits);


		FVector CombinedNormal;
		for(int i = 0; i < Normals.Num(); i++)
		{
			CombinedNormal += Normals[i];
		}
		CombinedNormal.Normalize();

		for(int i = 0; i < Normals.Num(); i++)
		{
			FVector Depenetration = Normals[i];
			if(Depenetration.DotProduct(CombinedNormal) > 0)
			{
				OutVector += Depenetration;
			}
		}

		OutVector = CombinedNormal;
		return true;
	}
};