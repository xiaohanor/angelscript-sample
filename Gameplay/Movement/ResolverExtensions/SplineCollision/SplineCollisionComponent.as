struct FSplineCollisionResolverExtensionInstigatorArray
{
	TArray<FInstigator> Instigators;
};

enum ESplineCollisionWorldUp
{
	MovementWorldUp,
	GlobalUp,
	SplineUp,
};

/**
 * Applied automatically on any actor using the SplineCollision resolver extension.
 * Keeps references to the splines currently used for collision, and the instigators that applied those splines.
 */
UCLASS(NotBlueprintable, NotPlaceable)
class USplineCollisionComponent : UActorComponent
{
	access SplineCollision = private, USplineCollisionResolverExtension;

	private TMap<ASplineActor, FSplineCollisionResolverExtensionInstigatorArray> SplineMap;
	private TArray<ASplineActor> Splines;

	access:SplineCollision
	TInstigated<ESplineCollisionWorldUp> WorldUp;

	void AddSplines(FInstigator Instigator, TArray<ASplineActor> InSplines)
	{
		if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
			return;

		if(!ensure(!InSplines.IsEmpty(), "No splines supplied!"))
			return;

		for(auto Spline : InSplines)
		{
			TArray<FInstigator>& Instigators = SplineMap.FindOrAdd(Spline).Instigators;
			Instigators.AddUnique(Instigator);
		}

		RecreateSplineArray();
	}

	void ClearSplines(FInstigator Instigator)
	{
		if(!ensure(Instigator.IsValid(), "Invalid instigator supplied!"))
			return;
		
		TArray<ASplineActor> SplinesToRemove;
		for(auto Spline : SplineMap)
		{
			Spline.Value.Instigators.RemoveSingleSwap(Instigator);
			if(Spline.Value.Instigators.IsEmpty())
				SplinesToRemove.Add(Spline.Key);
		}

		for(auto SplineToRemove : SplinesToRemove)
		{
			SplineMap.Remove(SplineToRemove);
		}

		RecreateSplineArray();
	}

	/**
	 * By default, the movement WorldUp is used for the infinite height direction of the splines.
	 * Use this function to set it as something else instead.
	 */
	void ApplyWorldUpOverride(ESplineCollisionWorldUp InWorldUp, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		WorldUp.Apply(InWorldUp, Instigator, Priority);
	}

	void ClearWorldUpOverride(FInstigator Instigator)
	{
		WorldUp.Clear(Instigator);
	}

	access:SplineCollision
	ASplineActor GetClosestSpline(FVector Location) const
	{
		ASplineActor Closest = nullptr;
		float ClosestDistance = BIG_NUMBER;

		for(auto Spline : Splines)
		{
			FVector ClosestLocation = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(Location);
			const float Distance = ClosestLocation.DistXY(Location);
			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				Closest = Spline;
			}
		}

		return Closest;
	}

	private void RecreateSplineArray()
	{
		Splines.Reset(SplineMap.Num());
		for(auto SplineEntry : SplineMap)
			Splines.Add(SplineEntry.Key);
	}
};