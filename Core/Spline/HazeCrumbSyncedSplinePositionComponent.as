
class UHazeCrumbSyncedSplinePositionComponent : UHazeCrumbSyncedStructComponent
{
	private FSplinePosition CachedPosition;

	const FSplinePosition& GetValue() property
	{
		GetCrumbValueStruct(CachedPosition);
		return CachedPosition;
	}

	void SetValue(FSplinePosition NewValue) property
	{
		SetCrumbValueStruct(NewValue);
	}
	
	void InterpolateValues(FSplinePosition& OutValue, FSplinePosition A, FSplinePosition B, float64 Alpha)
	{
		if (!A.IsValid())
		{
			OutValue = B;
			return;
		}

		if (!B.IsValid())
		{
			OutValue = A;
			return;
		}


		float DeltaDistance = A.DeltaToReachClosest(B);
		if (DeltaDistance == MAX_flt)
		{
			// Spline points are not connected
			OutValue = A;
			return;
		}

		// First lerp the spline position between the two spline positions we have
		OutValue = A;
		OutValue.Move(Alpha * DeltaDistance);
	}
}