event void FKnightArenaOverlapEventSignature(AHazePlayerCharacter Player, ASummitKnightArenaActor Arena);

class ASummitKnightArenaActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;
	default Arrow.ArrowSize = 5.0;
	default Arrow.ArrowLength = 50.0;
	default Arrow.ArrowColor = FLinearColor::Red;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UBoxComponent Bounds;
	default Bounds.BoxExtent = FVector(3000.0, 2000.0, 1000.0);
	default Bounds.RelativeLocation = FVector(2500.0, 0.0, 0.0);
	default Bounds.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY(EditInstanceOnly)
	ESummitKnightPhase Phase = ESummitKnightPhase::None;	

	UPROPERTY(EditInstanceOnly)
	uint8 Round = 1;

	UPROPERTY(EditInstanceOnly)
	float WallSpeedUpSplineDistance = 0.0;

	UPROPERTY()
	FKnightArenaOverlapEventSignature OnEnterArena;
	UPROPERTY()
	FKnightArenaOverlapEventSignature OnLeaveArena;

	TPerPlayer<bool> IsInside;

	TPerPlayer<FSplinePosition> PlayerSplinePositions;
	bool bUpdateSplinePositionMio = false;
	uint SplinePositionUpdateFrame = 0;

	float MaxSplineLength = 1.0;	

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTextRenderComponent MarkerText;
	default MarkerText.IsVisualizationComponent = false;
	default MarkerText.Text = FText::FromString("Knight Arena");
	default MarkerText.TextRenderColor = FColor::Red;
	default MarkerText.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default MarkerText.bHiddenInGame = true;
	default MarkerText.WorldSize = 100.0;
	default MarkerText.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> InsideActors;
		Bounds.GetOverlappingActors(InsideActors, AHazePlayerCharacter);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			IsInside[Player] = InsideActors.Contains(Player);
			if (IsInside[Player])
				OnEnterArena.Broadcast(Player, this);
		}
		Bounds.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
		Bounds.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");

		MaxSplineLength = Spline.SplineLength;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (IsActorDisabled())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		EnterArena(Player);
	}

	UFUNCTION(BlueprintCallable)
	void EnterArena(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return;
		if (!IsInside[Player])
		{
			IsInside[Player] = true;
			OnEnterArena.Broadcast(Player, this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		if (IsInside[Player])
		{
			IsInside[Player] = false;
			OnLeaveArena.Broadcast(Player, this);
		}
	}

	FVector GetArenaLocation(FVector Location) const
	{
		FVector ArenaCenterLoc = Math::ProjectPositionOnInfiniteLine(ActorLocation, Arrow.ForwardVector, Location);
		return FVector(Location.X, Location.Y, ArenaCenterLoc.Z);
	}

	FVector GetArenaCenter(float Fraction) const
	{
		return GetArenaLocation(Arrow.WorldLocation + Arrow.ForwardVector * Arrow.ArrowLength * Arrow.ArrowSize * Arrow.WorldScale.X * Fraction);	
	}

	void UpdatePlayerDistancesAlongSpline()
	{
		if (Time::FrameNumber == SplinePositionUpdateFrame)
			return;
		SplinePositionUpdateFrame = Time::FrameNumber;		

		// TODO: If this is too expensive, use a component on the knight to make sure we only update properly once per frame
		AHazePlayerCharacter Player = (bUpdateSplinePositionMio) ? Game::Mio : Game::Zoe;
		PlayerSplinePositions[Player] = Spline.GetClosestSplinePositionToWorldLocation(Player.ActorLocation);

		// Use cheap approximation for other player
		FSplinePosition& OtherPos = PlayerSplinePositions[Player.OtherPlayer];
		if (OtherPos.IsValid())
			OtherPos.Move(OtherPos.WorldForwardVector.DotProduct(Player.OtherPlayer.ActorLocation - OtherPos.WorldLocation));

		bUpdateSplinePositionMio = !bUpdateSplinePositionMio;
	}

	UFUNCTION()
	void BlockSplineAt(FVector Location, float OffsetAlongSpline = 0.0)
	{
		MaxSplineLength = Spline.GetClosestSplineDistanceToWorldLocation(Location) + OffsetAlongSpline;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		float Fraction = Math::Wrap(Time::GameTimeSeconds, 0.0, 5.0) * 0.2;
		FVector Center = GetArenaCenter(Fraction);
		Debug::DrawDebugLine(Center, Center + FVector(0.0, 0.0, 50.0), FLinearColor::DPink, 10.0);
		//Debug::DrawDebugString(Center + FVector(0.0, 0.0, 40.0), "" + Fraction, Scale = 3.0);
	}
#endif
}
