struct FMeltdownBossPhaseOneSmashSequence
{
	AHazePlayerCharacter SpawnOnPlayer;
	FVector SpawnOnLocation;
	float Timer = 0.0;
	float TelegraphTime = 0.0;
	float TrackDuration = 0.0;
	float Radius = 200.0;
	float HitDuration = 5.0;
	float TrackingAccelerationDuration = 0.0;
};

class AMeltDownBossPhaseOneAttackSequenceSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseOneSmashAttack> SmashAttackClass;

	UPROPERTY(EditAnywhere)
	AVolume DefaultPatternVolume;

	TArray<FMeltdownBossPhaseOneSmashSequence> SmashSequence;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void DevSmashAttackSequence()
	{
		SpawnSmashAttackSequence(Game::Mio);
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void DevSmashAttackSequenceAllAtOnce()
	{
		SpawnSmashAttackSequence(
			Game::Mio,
			Count = 5,
			TimeBetweenAttacks = 0.8,
			bAttackAllAtOnce = true,
		);
	}

	UFUNCTION()
	void SpawnSmashAttackSequence(
		AHazePlayerCharacter Player,
		int Count = 3,
		float TimeBetweenAttacks = 1.3,
		float TrackingTimePerAttack = 1.0,
		float TelegraphTimePerAttack = 1.5,
		float Radius = 200.0,
		float HitDuration = 200.0,
		bool bAttackAllAtOnce = false,
		float TrackingAccelerationDuration = 0.0,
	)
	{
		for (int i = 0; i < Count; ++i)
		{
			FMeltdownBossPhaseOneSmashSequence Element;
			Element.Timer = i * TimeBetweenAttacks;
			Element.SpawnOnPlayer = Player;
			Element.SpawnOnLocation = ActorLocation;
			Element.TrackDuration = TrackingTimePerAttack;
			Element.Radius = Radius;
			Element.HitDuration = HitDuration;
			Element.TrackingAccelerationDuration = TrackingAccelerationDuration;

			if (bAttackAllAtOnce)
				Element.TelegraphTime = (Count - i - 1) * TimeBetweenAttacks + TelegraphTimePerAttack;
			else
				Element.TelegraphTime = TelegraphTimePerAttack;

			SmashSequence.Add(Element);
		}
	}

	UFUNCTION(DevFunction, NotBlueprintCallable)
	void DevSmashAttackGrid()
	{
		SpawnSmashAttackGrid(nullptr);
	}

	UFUNCTION()
	void SpawnSmashAttackGrid(
		AVolume ContainingVolume,
		int XCount = 4, int YCount = 4,
		float TelegraphDuration = 1.5,
		float Radius = 200.0,
		float HitDuration = 200.0,
		FVector2D Offset = FVector2D(0, 0),
		float Angle = 0.0
	)
	{
		float XWidth = 1.0 / float(XCount);
		float YWidth = 1.0 / float(YCount);

		TArray<FVector2D> Positions;
		for (int Y = 0; Y < YCount; ++Y)
		{
			for (int X = 0; X < XCount; ++X)
			{
				FVector Pos = FVector(
					(X + 0.5) * XWidth + Offset.X,
					(Y + 0.5) * YWidth + Offset.Y,
					0.0
				);

				Pos.X = (Pos.X - 0.5) * 2.0;
				Pos.Y = (Pos.Y - 0.5) * 2.0;
				Pos = Pos.RotateAngleAxis(Angle, FVector::UpVector);
				Pos.X = (Pos.X * 0.5) + 0.5;
				Pos.Y = (Pos.Y * 0.5) + 0.5;

				Positions.Add(FVector2D(Pos.X, Pos.Y));
			}
		}
		SpawnSmashAttackPattern(ContainingVolume, Positions, TelegraphDuration, Radius, HitDuration);
	}

	UFUNCTION()
	void SpawnSmashAttackPattern(
		AVolume ContainingVolume,
		TArray<FVector2D> Positions,
		float TelegraphDuration = 1.5,
		float Radius = 200.0,
		float HitDuration = 5.0,
		float AppearInterval = 0.0
	)
	{
		FVector Origin;
		FVector Extent;

		if (ContainingVolume == nullptr)
			DefaultPatternVolume.GetActorBounds(true, Origin, Extent);
		else
			ContainingVolume.GetActorBounds(true, Origin, Extent);

		for (int i = 0, Count = Positions.Num(); i < Count; ++i)
		{
			FMeltdownBossPhaseOneSmashSequence Element;
			Element.Timer = i * AppearInterval;
			Element.SpawnOnLocation.X = Origin.X + (Extent.X * (Positions[i].X * 2.0 - 1.0));
			Element.SpawnOnLocation.Y = Origin.Y + (Extent.Y * (Positions[i].Y * 2.0 - 1.0));
			Element.SpawnOnLocation.Z = ActorLocation.Z;
			Element.TelegraphTime = TelegraphDuration;
			Element.Radius = Radius;
			Element.HitDuration = HitDuration;

			SmashSequence.Add(Element);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = SmashSequence.Num() - 1; i >= 0; --i)
		{
			FMeltdownBossPhaseOneSmashSequence& Element = SmashSequence[i];
			Element.Timer -= DeltaSeconds;

			if (Element.Timer <= 0.0)
			{
				AMeltdownBossPhaseOneSmashAttack Attack = SpawnActor(SmashAttackClass, Element.SpawnOnLocation);
				Attack.Radius = Element.Radius;
				Attack.bAutoDestroy = true;
				Attack.TrackingAccelerationDuration = Element.TrackingAccelerationDuration;
				Attack.StartAttack(
					Element.TelegraphTime,
					Element.SpawnOnPlayer,
					Element.TrackDuration,
				);

				SmashSequence.RemoveAt(i);
				continue;
			}
		}
	}
};