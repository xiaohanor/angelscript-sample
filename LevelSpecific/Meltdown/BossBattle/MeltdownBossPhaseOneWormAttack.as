class AMeltdownBossPhaseOneWormAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere)
	float Speed = 2000.0;

	UPROPERTY(EditAnywhere)
	int SegmentCount = 5;

	UPROPERTY(EditAnywhere)
	float SegmentRadius = 60.0;

	UPROPERTY(EditAnywhere)
	float SegmentLength = 100.0;

	UPROPERTY(EditAnywhere)
	float SegmentSpacing = 250.0;

	UPROPERTY(EditAnywhere)
	FVector Displacement = FVector(0.0, 0.0, 200.0);

	UPROPERTY(EditAnywhere)
	float LerpDistance = 100.0;

	bool bTriggered = false;
	float Timer = 0.0;

	TArray<UMeltdownBossCubeGridDisplacementComponent> DisplacementComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(DevFunction)
	void TriggerAttack()
	{
		bTriggered = true;
		Timer = 0.0;
	}

	void CheckKillPlayers()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bTriggered)
			return;

		Timer += DeltaSeconds;

		float SplinePosition = Speed * Timer;
		if (SplinePosition >= Spline.SplineLength + SegmentSpacing * SegmentCount) 
		{
			bTriggered = false;
			for (UMeltdownBossCubeGridDisplacementComponent Comp : DisplacementComps)
				Comp.DeactivateDisplacement();
			return;
		}

		for (int i = 0; i < SegmentCount; ++i)
		{
			if (!DisplacementComps.IsValidIndex(i))
				DisplacementComps.Add(UMeltdownBossCubeGridDisplacementComponent::Create(this));

			float Pos = Math::Max(SplinePosition - (i * SegmentSpacing), 0.0);

			float DisplacementAlpha = Math::Min(
				Math::Saturate(Pos / SegmentLength * 0.5),
				Math::Saturate((Spline.SplineLength - Pos) / SegmentLength * 0.5),
			);

			UMeltdownBossCubeGridDisplacementComponent Comp = DisplacementComps[i];
			Comp.ActivateDisplacement();
			Comp.Type = EMeltdownBossCubeGridDisplacementType::Shape;
			Comp.Shape = FHazeShapeSettings::MakeCapsule(SegmentRadius, SegmentLength * 0.5);
			Comp.Displacement = Math::Lerp(FVector::ZeroVector, Displacement, DisplacementAlpha);
			Comp.LerpDistance = LerpDistance;
			Comp.bInfiniteHeight = true;

			Comp.WorldLocation = Spline.GetWorldLocationAtSplineDistance(Pos);
			Comp.WorldRotation = FRotator::MakeFromZX(Spline.GetWorldForwardVectorAtSplineDistance(Pos), FVector::UpVector);

			for (auto Player : Game::Players)
			{
				if (Player.IsPlayerDead())
					continue;

				float Distance = Comp.GetDistanceToPoint(Player.ActorLocation);
				if (Distance <= LerpDistance)
				{
					Player.KillPlayer();
				}
			}
		}
	}
};