class ASummitKnightMobileArena : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Shape;
	default Shape.SphereRadius = 5600.0;

	UPROPERTY(DefaultComponent)
	USceneComponent DeathPosition;
	default DeathPosition.RelativeLocation = FVector(-1.0, 0.0, 0.0) * Shape.SphereRadius * 0.82;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = Shape.SphereRadius + 2000.0;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination0;
	default SwoopDestination0.RelativeLocation = FVector(1.0, 0.0, 0.0) * Shape.SphereRadius * 0.95;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination1;
	default SwoopDestination1.RelativeLocation = FVector(0.707, 0.707, 0.0) * Shape.SphereRadius * 0.95;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination2;
	default SwoopDestination2.RelativeLocation = FVector(0.0, 1.0, 0.0) * Shape.SphereRadius * 0.95;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination3;
	default SwoopDestination3.RelativeLocation = FVector(-0.707, 0.707, 0.0) * Shape.SphereRadius * 0.95;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination4;
	default SwoopDestination4.RelativeLocation = FVector(-1.0, 0.0, 0.0) * Shape.SphereRadius * 0.95;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination5;
	default SwoopDestination5.RelativeLocation = FVector(-0.707, -0.707, 0.0) * Shape.SphereRadius * 0.95;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination6;
	default SwoopDestination6.RelativeLocation = FVector(0.0, -1.0, 0.0) * Shape.SphereRadius * 0.95;

	UPROPERTY(DefaultComponent)
	UScenepointComponent SwoopDestination7;
	default SwoopDestination7.RelativeLocation = FVector(0.707, -0.707, 0.0) * Shape.SphereRadius * 0.95;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Target";
	default Billboard.WorldScale3D = FVector(40.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 300.0);
#endif	

	USummitKnightStageComponent KnightStageComp;
	TArray<UScenepointComponent> SwoopDestinations;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(SwoopDestinations);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())	
			return;
		if (KnightStageComp == nullptr)
		{
			AAISummitKnight Knight = TListedActors<AAISummitKnight>().Single;
			if (Knight == nullptr)
				return;
			KnightStageComp = USummitKnightStageComponent::Get(Knight);
		}
		if (KnightStageComp == nullptr)
			return;
		if (KnightStageComp.Phase != ESummitKnightPhase::None)
			return;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.ActorLocation.IsWithinDist2D(Shape.WorldLocation, Shape.SphereRadius))
				continue;
			if (Math::Abs(Player.ActorLocation.Z - Shape.WorldLocation.Z) > Shape.SphereRadius)
				continue;
			// One player is within cylinder encompassing arena sphere, let's go!
			CrumbPlayerEnterArena(KnightStageComp);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbPlayerEnterArena(USummitKnightStageComponent StageComp)
	{
		KnightStageComp = StageComp;
		KnightStageComp.SetPhase(ESummitKnightPhase::MobileStart, 0);
	}

	bool IsInsideArena(FVector Location, float InsideThreshold = 0.0, float HeightThreshold = 10000.0) const
	{
		if (Math::Abs(Location.Z - Center.Z) > HeightThreshold)
			return false;
		if (!Location.IsWithinDist2D(Center, Radius - InsideThreshold))
			return false;
		return true;
	}

	FVector GetCenter() const property
	{
		return ActorLocation;
	}

	float GetRadius() const property
	{
		return Shape.SphereRadius;
	}

	FVector GetAtArenaHeight(FVector Location) const
	{
		return FVector(Location.X, Location.Y, ActorLocation.Z);
	}

	FVector GetClampedToArena(FVector Location, float InsideOffset = 0.0) const
	{
		float TweakedRadius = Radius - InsideOffset;
		FVector Loc = GetAtArenaHeight(Location);
		if (Loc.IsWithinDist2D(Center, TweakedRadius))
			return Loc;
		return Center + ((Loc - Center).GetSafeNormal2D() * TweakedRadius);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugLine(DeathPosition.WorldLocation, DeathPosition.WorldLocation + FVector(0.0, 0.0, 1000.0), FLinearColor::Purple, 100.0);

		TArray<UScenepointComponent> SwoopDests;
		GetComponentsByClass(SwoopDests);
		for (UScenepointComponent SwoopDest : SwoopDests)
		{
			Debug::DrawDebugSphere(SwoopDest.WorldLocation + ActorUpVector * 200.0, 200.0, 4, FLinearColor::DPink, 10.0);
		}
	}
#endif
};