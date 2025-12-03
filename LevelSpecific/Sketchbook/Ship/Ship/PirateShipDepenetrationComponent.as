struct FPirateShipDepenetrationBox
{
	UPROPERTY(EditAnywhere)
	FVector RelativeLocation;

	UPROPERTY(EditAnywhere)
	FRotator RelativeRotation;

	UPROPERTY(EditAnywhere)
	FVector Extents = FVector(100);
}

struct FPirateShipShapeAndOverlaps
{
	FCollisionShape Shape;
	FVector Location;
	FQuat Rotation;
	TArray<FOverlapResult> Overlaps;
}

UCLASS(NotBlueprintable)
class UPirateShipDepenetrationComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float Radius = 4000;

	UPROPERTY(EditAnywhere)
	TArray<FPirateShipDepenetrationBox> Boxes;

	bool Depenetrate(FVector Location, FQuat Rotation, FVector&out OutDelta, TArray<AActor>&out OutHitActors) const
	{
		if(!Pirate::Ship::bDepenetrate)
			return false;

		FTransform NewTransform = FTransform(Rotation, Location, Owner.ActorScale3D);

		FVector TotalAccumulatedDelta = FVector::ZeroVector;
		TArray<FVector> AccumulatedDeltas;

		for(auto Obstacle : Pirate::GetObstacles())
		{
			if(Obstacle.Owner == Owner)
				continue;

			if(!Obstacle.IsRelevantFor(Location, Radius))
				continue;

			for(auto Box : Boxes)
			{
				FVector BoxLocation = NewTransform.TransformPosition(Box.RelativeLocation);
				FQuat BoxRotation = NewTransform.TransformRotation(Box.RelativeRotation.Quaternion());

				FCollisionShape Shape;
				Shape.SetBox(Box.Extents);

				for(auto Primitive : Obstacle.ComponentsToCollideWith)
				{
					FVector Delta;
					if(!Primitive.TryGetDepenetrationDelta(Shape, BoxLocation, BoxRotation, Delta))
						continue;

					OutHitActors.AddUnique(Primitive.Owner);

					// Accumulate the deltas from all overlaps
					TotalAccumulatedDelta += Delta;
					
					bool bFound = false;
					for(FVector& AccumulatedDelta : AccumulatedDeltas)
					{
						// Add the delta to accumulated deltas that point in the same direction
						if(Delta.DotProduct(AccumulatedDelta) > 0.0)
						{
							AccumulatedDelta += Delta;
							bFound = true;
						}
					}

					if(!bFound)
						AccumulatedDeltas.Add(Delta);
				}
			}
		}

		// TArray<FPirateShipShapeAndOverlaps> AllOverlaps;

		// for(auto Box : Boxes)
		// {
		// 	FVector BoxLocation = NewTransform.TransformPosition(Box.RelativeLocation);
		// 	FQuat BoxRotation = NewTransform.TransformRotation(Box.RelativeRotation.Quaternion());

		// 	// FB TODO: Do we need to sweep? Could we rewrite GetDepenetrationDelta to only check against obstacle actors and enemy ships?
		// 	FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
		// 	TraceSettings.UseBoxShape(Box.Extents, BoxRotation);
		// 	TraceSettings.IgnoreActor(Owner);
		// 	TraceSettings.IgnorePlayers();

		// 	const FOverlapResultArray Overlaps = TraceSettings.QueryOverlaps(BoxLocation);

		// 	if(Overlaps.Num() == 0)
		// 		continue;

		// 	FPirateShipShapeAndOverlaps ShapeAndOverlaps;
		// 	ShapeAndOverlaps.Shape = TraceSettings.Shape.Shape;
		// 	ShapeAndOverlaps.Location = BoxLocation;
		// 	ShapeAndOverlaps.Rotation = BoxRotation;

		// 	for(auto Overlap : Overlaps)
		// 	{
		// 		ShapeAndOverlaps.Overlaps.Add(Overlap);
		// 	}

		// 	AllOverlaps.Add(ShapeAndOverlaps);
		// }

		// if(AllOverlaps.Num() == 0)
		// 	return false;

		// FVector TotalAccumulatedDelta = FVector::ZeroVector;
		// TArray<FVector> AccumulatedDeltas;
		// AccumulatedDeltas.Reserve(AllOverlaps.Num());

		// for(const FPirateShipShapeAndOverlaps& ShapeAndOverlaps : AllOverlaps)
		// {
		// 	for(const FOverlapResult& Overlap : ShapeAndOverlaps.Overlaps)
		// 	{
		// 		// if(Overlap.Component.Mobility != EComponentMobility::Movable)
		// 		// 	continue;

		// 		const FVector Delta = Overlap.GetDepenetrationDelta(ShapeAndOverlaps.Shape, ShapeAndOverlaps.Rotation, ShapeAndOverlaps.Location);

		// 		// Accumulate the deltas from all overlaps
		// 		TotalAccumulatedDelta += Delta;
				
		// 		bool bFound = false;
		// 		for(FVector& AccumulatedDelta : AccumulatedDeltas)
		// 		{
		// 			// Add the delta to accumulated deltas that point in the same direction
		// 			if(Delta.DotProduct(AccumulatedDelta) > 0.0)
		// 			{
		// 				AccumulatedDelta += Delta;
		// 				bFound = true;
		// 			}
		// 		}

		// 		if(!bFound)
		// 			AccumulatedDeltas.Add(Delta);
		// 	}
		// }

		// Get the largest delta, which is either the sum of
		// all deltas, or one of the AccumulatedDeltas entries
		FVector FinalDelta = TotalAccumulatedDelta;

		for(const FVector& AccumulatedDelta : AccumulatedDeltas)
		{
			if(AccumulatedDelta.SizeSquared() > FinalDelta.SizeSquared())
				FinalDelta = AccumulatedDelta;
		}

		if(FinalDelta == FVector::ZeroVector)
			return false;

		OutDelta = FinalDelta;
		return true;
	}
};

#if EDITOR
class UPirateShipDepenetrationComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPirateShipDepenetrationComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto DepenetrationComp = Cast<UPirateShipDepenetrationComponent>(Component);
		if(DepenetrationComp == nullptr)
			return;

		DrawWireSphere(DepenetrationComp.Owner.ActorLocation, DepenetrationComp.Radius, FLinearColor::Blue, 3, 12, true);

		for(auto Box : DepenetrationComp.Boxes)
		{
			FVector BoxLocation = DepenetrationComp.Owner.ActorTransform.TransformPosition(Box.RelativeLocation);
			FQuat BoxRotation = DepenetrationComp.Owner.ActorTransform.TransformRotation(Box.RelativeRotation.Quaternion());
			DrawWireBox(BoxLocation, Box.Extents, BoxRotation, FLinearColor::Red, 3, true);
		}
	}
};
#endif