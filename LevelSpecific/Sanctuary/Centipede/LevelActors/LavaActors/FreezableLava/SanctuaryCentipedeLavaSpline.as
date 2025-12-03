class USanctuaryCentipedeLavaSplineSegmentComponent : UStaticMeshComponent
{
	// Don't think we actually use the overlaps here, lava uses traces instead of overlaps
	default bGenerateOverlapEvents = false;

	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
	default SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	TArray<UPrimitiveComponent> OverlappedCentipedeParts;

	UPROPERTY(EditDefaultsOnly, Category = "Lava")
	FVector RockLocationRandomization = FVector(20, 20, 5.0);

	UPROPERTY(EditDefaultsOnly, Category = "Lava")
	float LavaRockAliveDurationOverride = 1000.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASanctuaryCentipedeFrozenLavaRock> LavaRockClass;

	UPROPERTY(Transient)
	UHazeCrumbSyncedFloatComponent CrumbedDistanceAlongSpline;

	private TArray<ASanctuaryCentipedeFrozenLavaRock> AttachedRocks;
	private bool bIsGameNetworked = false;
	private bool bMelted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto MakingSureLavaRockManagerExistsOnBothClients = SanctuaryCentipedeLavaRock::GetManager();
		CrumbedDistanceAlongSpline = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, FName("CrumbedSyncedFloat" + Name));
	}

	void Freeze(FVector FreezeLocation)
	{
		SanctuaryCentipedeLavaRock::GetManager().RequestSpawnRock(this, LavaRockClass, FreezeLocation, RockLocationRandomization, true, LavaRockAliveDurationOverride);
		CrumbedDistanceAlongSpline.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	void RegisterRock(ASanctuaryCentipedeFrozenLavaRock Rock)
	{
		if (Rock != nullptr)
		{
			Rock.AttachToComponent(this, n"", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			Rock.OnDestroyed.AddUFunction(this, n"HandleDestroyed");
			Rock.OnMeltedEvent.AddUFunction(this, n"HandleMelted");
			AttachedRocks.Add(Rock);
		}
	}

	void MeltRocks()
	{
		if (bMelted)
			return;
		bMelted = true;
		for (int i = 0; i < AttachedRocks.Num(); ++i)
		{
			if (AttachedRocks[i].bIsCold)
				AttachedRocks[i].MeltNowPlz();
		}
	}

	void Unfreeze()
	{
		for (int i = 0; i < AttachedRocks.Num(); ++i)
		{
			AttachedRocks[i].OnMeltedEvent.Unbind(this, n"HandleMelted");
			AttachedRocks[i].OnDestroyed.Unbind(this, n"HandleDestroyed");
			AttachedRocks[i].MeltNowPlz();
		}

		AttachedRocks.Reset(16);
		bMelted = false;

		CrumbedDistanceAlongSpline.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
	}

	bool HasMeltedRocks()
	{
		return bMelted;
	}

	UFUNCTION()
	private void HandleMelted(ASanctuaryCentipedeFrozenLavaRock MeltedRock)
	{
		RemoveRock(MeltedRock);
		MeltedRock.OnMeltedEvent.Unbind(this, n"HandleMelted");
		MeltedRock.OnDestroyed.Unbind(this, n"HandleDestroyed");
	}
	UFUNCTION()
	private void HandleDestroyed(AActor DestroyedActor)
	{
		ASanctuaryCentipedeFrozenLavaRock MeltedRock = Cast<ASanctuaryCentipedeFrozenLavaRock>(DestroyedActor);
		RemoveRock(MeltedRock);
		MeltedRock.OnMeltedEvent.Unbind(this, n"HandleMelted");
		MeltedRock.OnDestroyed.Unbind(this, n"HandleDestroyed");
	}
	private void RemoveRock(ASanctuaryCentipedeFrozenLavaRock Rock)
	{
		if (Rock != nullptr && AttachedRocks.Contains(Rock))
			AttachedRocks.Remove(Rock);
	}
}

class ASanctuaryCentipedeLavaSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<USanctuaryCentipedeLavaSplineSegmentComponent> SegmentClass;

	UPROPERTY(EditAnywhere)
	FVector SegmentScale = FVector::OneVector;

	UPROPERTY(EditAnywhere)
	float FlowSpeed = 500.0;

	UPROPERTY()
	TArray<USanctuaryCentipedeLavaSplineSegmentComponent> Segments;

	UPROPERTY()
	TArray<FSplinePosition> SplinePositions;

	UPROPERTY(EditAnywhere)
	float AutoMeltRocksAtDistance = 13250.0;

	UPROPERTY(EditAnywhere)
	float SegmentSpacing = 400.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	USanctuaryLavaApplierComponent LavaComp;

	TArray<UHazeMovementComponent> ImpactingMoveComps;

	const float MaxNetSplineDistanceError = 50.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Segments.Reset();
		SplinePositions.Reset();

		float NumOfSegments = Spline.SplineLength / SegmentSpacing;
		for (int i = 0; i < NumOfSegments; i++)
		{
			auto Segment = Cast<USanctuaryCentipedeLavaSplineSegmentComponent>(CreateComponent(SegmentClass, FName("Segment_" + i)));
			FSplinePosition SplinePosition = Spline.GetSplinePositionAtSplineDistance(i * SegmentSpacing);
			
			FTransform TransformAtDistance = SplinePosition.WorldTransform;

			TransformAtDistance.Scale3D = TransformAtDistance.Scale3D * SegmentScale;

			TransformAtDistance.Scale3D = TransformAtDistance.Scale3D + FVector(i * 0.001);

			Segment.WorldTransform = TransformAtDistance;
			Segments.Add(Segment);
			SplinePositions.Add(SplinePosition);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");
		ImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"HandlePlayerImpactEnd");
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		ImpactingMoveComps.Add(MoveComp);
		// todo(ylva) make a more granular check of what bodyparts is on lava
		LavaComp.ManualStartOverlapWholeCentipedeApply();
	}

	UFUNCTION()
	private void HandlePlayerImpactEnd(AHazePlayerCharacter Player)
	{
		auto MoveComp = UHazeMovementComponent::Get(Player);
		ImpactingMoveComps.Remove(MoveComp);
		LavaComp.ManualEndOverlapWholeCentipedeApply();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = 0; i < Segments.Num(); i++)
		{
			auto Segment = Segments[i];
			auto& SplinePosition = SplinePositions[i];

			float RemainingDistance = 0.0;
			if (!Segment.HasMeltedRocks())
			{
				float PreviousDistance = SplinePosition.GetCurrentSplineDistance();
				float NewDistance = PreviousDistance + FlowSpeed * DeltaSeconds;
				if (PreviousDistance < AutoMeltRocksAtDistance && NewDistance > AutoMeltRocksAtDistance)
					Segment.MeltRocks();
			}

			// Move and reset if reached end of spline
			if (!SplinePosition.Move(FlowSpeed * DeltaSeconds, RemainingDistance))
			{
				SplinePosition = Spline.GetSplinePositionAtSplineDistance(RemainingDistance);
				Segment.Unfreeze();
			}

			// Control updates spline distance value
			if (HasControl())
			{
				Segment.CrumbedDistanceAlongSpline.SetValue(SplinePosition.CurrentSplineDistance);
			}
			// Remote side corrects spline position if local translation gets out of whack
			else
			{
				float SplineDistanceDelta = Math::Abs(SplinePosition.CurrentSplineDistance - Segment.CrumbedDistanceAlongSpline.Value);
				if (SplineDistanceDelta > MaxNetSplineDistanceError)
				{
					float SplineDistance = Math::FInterpConstantTo(SplinePosition.CurrentSplineDistance, Segment.CrumbedDistanceAlongSpline.Value, DeltaSeconds, 60);
					SplinePosition = Spline.GetSplinePositionAtSplineDistance(SplineDistance);
				}
			}

			Segment.SetWorldLocationAndRotation(SplinePosition.WorldLocation, SplinePosition.WorldRotation);
		}
	}
};