struct FMoveIntoPlayerState
{
	FVector CurrentLocation = FVector::ZeroVector;
	FVector DeltaToTrace = FVector::ZeroVector;
	float PerformedMovementAmount = 0;
};

/** 
 * 
*/
class UMoveIntoPlayerMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = UMoveIntoPlayerMovementData;

	const UMoveIntoPlayerMovementData MoveIntoPlayerData;

	FMoveIntoPlayerState MoveIntoPlayerState;
	TArray<FVector> MoveOutDeltas;

#if !RELEASE
	default TemporalLogPageName = "MoveIntoPlayer Resolver";
	const FString InitialCategory = "1. Initial";
	const FString OutCategory = "2. Out Iterations";
	const FString BackCategory = "3. Back Iterations";
	const FString FinalCategory = "4. Final";
	FString DebugMoveCategory;
#endif

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveIntoPlayerData = Cast<UMoveIntoPlayerMovementData>(Movement);

		MoveIntoPlayerState.CurrentLocation = Owner.ActorLocation;
		MoveIntoPlayerState.DeltaToTrace = MoveIntoPlayerData.DeltaStates.GetDelta().Delta;

		// FVector Origin;
		// FVector Extent;
		// MoveIntoPlayerData.ShapeComponent.Owner.GetActorLocalBounds(true, Origin, Extent);

		// const float MinDeltaSize = (Extent * MoveIntoPlayerData.ShapeComponent.Owner.ActorScale3D).Size() * 0.5;
		// if(MoveIntoPlayerState.DeltaToTrace.SizeSquared() < Math::Square(MinDeltaSize))
		// {
		// 	MoveIntoPlayerState.DeltaToTrace = MoveIntoPlayerState.DeltaToTrace.GetSafeNormal() * MinDeltaSize;
		// }

		MoveIntoPlayerState.PerformedMovementAmount = 0;
		MoveOutDeltas.Reset();

#if !RELEASE
		if(CanTemporalLog())
		{
			DebugMoveCategory = MoveIntoPlayerData.MoveCategory;
			GetTemporalLog().Status("MoveIntoPlayer", FLinearColor::Green);
		}
#endif
	}

	void ResolveMoveInto(FVector&out OutLocation, FVector&out OutVelocity, const USceneComponent&out OutRelativeToComponent)
	{
#if !RELEASE
		if(CanTemporalLog())
		{
			GetTemporalLog().Section(DebugMoveCategory).Section(InitialCategory, 1)
				.Shape("CurrentLocation", MoveIntoPlayerState.CurrentLocation + IterationTraceSettings.CollisionShapeOffset, TraceShape.Shape, TraceShape.Orientation.Rotator())
				.DirectionalArrow("Delta", MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace);
		}
#endif

		// By default, we will use the current component for relative syncing
		OutRelativeToComponent = MoveIntoPlayerData.MovedByComponent;

		// Move Out Iterations
		while(true)
		{
			if(!PrepareOutNextIteration())
				break;

			IterationTraceSettings.AddNextTraceIgnoredActor(MoveIntoPlayerData.MovedByComponent.Owner);
			const FHazeTraceTag TraceTag = GenerateTraceTag(n"MoveIntoPlayerOutIteration", n"ResolveMoveInto");
			auto OutIterationHit = QueryShapeTrace(MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace, TraceTag);

#if !RELEASE
			if(CanTemporalLog())
			{
				GetTemporalLog().Section(DebugMoveCategory).Section(f"{OutCategory} {IterationCount :03}", 2)
					.HitResults("OutIterationHit", OutIterationHit.ConvertToHitResult(), TraceShape, IterationTraceSettings.CollisionShapeOffset, true)
					.MovementShape("CurrentLocation", MoveIntoPlayerState.CurrentLocation, IterationTraceSettings)
					.DirectionalArrow("Delta", MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace)
					.Value("PerformedMovementAmount", MoveIntoPlayerState.PerformedMovementAmount);
			}
#endif

			if(OutIterationHit.bStartPenetrating)
			{
				break;
			}
			else if(OutIterationHit.bBlockingHit)
			{
				MoveOutDeltas.Add(MoveIntoPlayerState.DeltaToTrace * OutIterationHit.Time);
				HandleIterationDeltaMovementImpact(OutIterationHit);
			}
			else
			{
				MoveOutDeltas.Add(MoveIntoPlayerState.DeltaToTrace);
				HandleIterationDeltaMovementWithoutImpact();
			}
		}

		// Move Back Iterations
		int BackIterationCount = 0;

		for(int i = MoveOutDeltas.Num() - 1; i >= 0; i--)
		{
			BackIterationCount++;
			
			MoveIntoPlayerState.DeltaToTrace = -MoveOutDeltas.Last();
			MoveOutDeltas.RemoveAt(MoveOutDeltas.Num() - 1);

			if(MoveIntoPlayerState.DeltaToTrace.IsNearlyZero())
				continue;

			const FHazeTraceTag TraceTag = GenerateTraceTag(n"MoveIntoPlayerBackIteration", n"ResolveMoveInto");
			auto BackIterationHit = QueryShapeTrace(MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace, TraceTag);

#if !RELEASE
			if(CanTemporalLog())
			{
				GetTemporalLog().Section(DebugMoveCategory).Section(f"{BackCategory} {BackIterationCount :03}", 3)
					.HitResults("BackIterationHit", BackIterationHit.ConvertToHitResult(), TraceShape, IterationTraceSettings.CollisionShapeOffset, true)
					.MovementShape("CurrentLocation", MoveIntoPlayerState.CurrentLocation, IterationTraceSettings)
					.DirectionalArrow("Delta", MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace)
					.Value("PerformedMovementAmount", MoveIntoPlayerState.PerformedMovementAmount);
			}
#endif

			if(BackIterationHit.bStartPenetrating)
			{
				break;
			}
			else if(BackIterationHit.bBlockingHit)
			{
				if(BackIterationHit.Actor == MoveIntoPlayerData.MovedByComponent.Owner)
				{
					if(HasMovementControl())
						HandleMovementImpactInternal(BackIterationHit, EMovementResolverAnyShapeTraceImpactType::MoveIntoPlayer);

					// We hit the moving actor, so we are done
					MoveIntoPlayerState.CurrentLocation = BackIterationHit.Location;

					// Also use the hit component for synced relative position
					OutRelativeToComponent = BackIterationHit.Component;
					break;
				}
				else
				{
					HandleIterationDeltaMovementImpact(BackIterationHit);
				}
			}
			else
			{
				HandleIterationDeltaMovementWithoutImpact();
			}
		}

		OutLocation = MoveIntoPlayerState.CurrentLocation;
		OutVelocity = (OutLocation - MoveIntoPlayerData.OriginalActorTransform.Location) / IterationTime;

#if !RELEASE
		if(CanTemporalLog())
		{
			GetTemporalLog().Section(DebugMoveCategory).Section(FinalCategory, 4)
				.MovementShape("CurrentLocation", MoveIntoPlayerState.CurrentLocation, IterationTraceSettings)
			;
		}
#endif
	}

	protected bool PrepareOutNextIteration()
	{
		// Increase the iteration so we don't get stuck in a loop
		IterationCount++;

		if(IterationCount > MoveIntoPlayerData.MaxRedirectIterations)
			return false;

		const float DeltaSizeSq = MoveIntoPlayerState.DeltaToTrace.SizeSquared();
		if(DeltaSizeSq <= Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			MoveIntoPlayerState.DeltaToTrace = FVector::ZeroVector;
			return false;
		}

		return true;
	}

	void HandleIterationDeltaMovementImpact(FMovementHitResult IterationHit)
	{
		MoveIntoPlayerState.PerformedMovementAmount += IterationHit.Distance;
		MoveIntoPlayerState.CurrentLocation = IterationHit.Location;

		ApplyImpactOnDeltas(IterationHit);

		MoveIntoPlayerState.DeltaToTrace *= (1.0 - IterationHit.Time);
	}

	void HandleIterationDeltaMovementWithoutImpact()
	{
		MoveIntoPlayerState.PerformedMovementAmount += MoveIntoPlayerState.DeltaToTrace.Size();
		MoveIntoPlayerState.CurrentLocation += MoveIntoPlayerState.DeltaToTrace;

		MoveIntoPlayerState.DeltaToTrace = FVector::ZeroVector;
	}

	/**
	 * This function will change the pending delta moves
	 */
	protected void ApplyImpactOnDeltas(FMovementHitResult Impact)
	{
		const float DeltaSize = MoveIntoPlayerState.DeltaToTrace.Size();
		MoveIntoPlayerState.DeltaToTrace = MoveIntoPlayerState.DeltaToTrace.VectorPlaneProject(Impact.Normal).GetSafeNormal() * DeltaSize;
	}

#if !RELEASE
	FTemporalLog GetTemporalLog() const override
	{
		return Super::GetTemporalLog().Page("MoveIntoPlayer");
	}
#endif
};