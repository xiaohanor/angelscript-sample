event void FOnSandFishCollision(AHazeActor SandfishActor, FVector ImpactPoint);

class USandFishResponseComponent : UActorComponent
{
	FBox Bounds;

	UPROPERTY()
	FOnSandFishCollision OnSandFishCollision;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector Origin;
		FVector BoxExtent;
		Owner.GetActorBounds(false, Origin, BoxExtent);
		Bounds = FBox(Origin - BoxExtent, Origin + BoxExtent);
	}

	void SandFishHeadCollision(AHazeActor SandfishActor, FVector ImpactPoint)
	{
		OnSandFishCollision.Broadcast(SandfishActor, ImpactPoint);
	}

	FVector GetClosestPointOnCollision(FVector Point) const
	{
		TArray<UPrimitiveComponent> Primitives;
		Owner.GetComponentsByClass(Primitives);

		float ClosestDistance = BIG_NUMBER;
		FVector ClosestPoint;
		for(auto& Primitive : Primitives)
		{
			FVector CollisionPoint;
			float Distance = Primitive.GetClosestPointOnCollision(Point, CollisionPoint);

			if(Distance <= 0)
				continue;

			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestPoint = CollisionPoint;
			}
		}

		return ClosestPoint;
	}
};