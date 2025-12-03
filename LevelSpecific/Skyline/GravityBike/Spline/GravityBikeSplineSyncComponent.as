struct FGravityBikeSplineSyncData
{
	FSplinePosition SplinePosition;
	float SpeedAlongSpline;

	float Steering;
	float StickyThrottle;
	float ImmediateThrottle;
};

UCLASS(NotBlueprintable)
class UGravityBikeSplineSyncComponent : UHazeCrumbSyncedStructComponent
{
	void FillFromLocal(const AGravityBikeSpline GravityBike)
	{
		FGravityBikeSplineSyncData SyncData;
		
		SyncData.SplinePosition = GravityBike.GetSplinePosition();
		SyncData.SpeedAlongSpline = GravityBike.MoveComp.Velocity.DotProduct(SyncData.SplinePosition.WorldForwardVector);

		SyncData.Steering = GravityBike.Input.GetSteering();
		SyncData.StickyThrottle = GravityBike.Input.GetStickyThrottle();
		SyncData.ImmediateThrottle = GravityBike.Input.GetImmediateThrottle();

		SetValue(SyncData);
	}

	FGravityBikeSplineSyncData GetValue()
	{
		FGravityBikeSplineSyncData SyncData;
		GetCrumbValueStruct(SyncData);
		return SyncData;
	}

	void SetValue(const FGravityBikeSplineSyncData& NewValue)
	{
		SetCrumbValueStruct(NewValue);
	}

	void ResetInput()
	{
		FGravityBikeSplineSyncData SyncData = GetValue();
		SyncData.Steering = 0;
		SyncData.StickyThrottle = 0;
		SyncData.ImmediateThrottle = 0;
		SetValue(SyncData);
	}
	
	void InterpolateValues(FGravityBikeSplineSyncData& OutValue, FGravityBikeSplineSyncData A, FGravityBikeSplineSyncData B, float64 Alpha)
	{
		OutValue.SplinePosition = InterpolateSplinePosition(A.SplinePosition, B.SplinePosition, Alpha);
		OutValue.SpeedAlongSpline = Math::Lerp(A.SpeedAlongSpline, B.SpeedAlongSpline, Alpha);

		OutValue.Steering = Math::Lerp(A.Steering, B.Steering, Alpha);
		OutValue.StickyThrottle = Math::Lerp(A.StickyThrottle, B.StickyThrottle, Alpha);
		OutValue.ImmediateThrottle = Math::Lerp(A.ImmediateThrottle, B.ImmediateThrottle, Alpha);
	}

	private FSplinePosition InterpolateSplinePosition(FSplinePosition A, FSplinePosition B, float Alpha) const
	{
		if (!A.IsValid())
		{
			return B;
		}

		if (!B.IsValid())
		{
			return A;
		}


		float DeltaDistance = A.DeltaToReachClosest(B);
		if (DeltaDistance == MAX_flt)
		{
			// Spline points are not connected
			return A;
		}

		// First lerp the spline position between the two spline positions we have
		FSplinePosition Out = A;
		Out.Move(Alpha * DeltaDistance);
		return Out;
	}
};