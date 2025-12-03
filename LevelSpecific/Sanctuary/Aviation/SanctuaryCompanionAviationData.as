struct FSanctuaryCompanionAviationDestinationSplineData
{
	FVector NextSplineLocation; 
	FVector SplineDirection; 
	bool bIsAtEnd;
	float TraversedPercent;

	// bool bGuaranteeProgress = false;
	// float SplineDistance = 0.0;
}

event void FOnSanctuaryCompanionAviationDestinationRemoved();
struct FSanctuaryCompanionAviationDestinationData
{
	FHazeRuntimeSpline RuntimeSpline;
	AHazeActor Actor = nullptr;
	USkeletalMeshComponent SkellyMesh = nullptr;
	FName BoneName;

	FOnSanctuaryCompanionAviationDestinationRemoved OnRemoved;
	EAviationState AviationState;
	bool bDisableSidescroll = true;
	bool bLerp = false;

	bool IsTargetingBone() const
	{
		return !BoneName.IsNone();
	}

	bool HasRuntimeSpline() const
	{
		return RuntimeSpline.Points.Num() > 0; 
	}

	FVector GetLocation() const
	{
		check(!HasRuntimeSpline(), "Don't fetch location directly if using a spline!");
		if (!BoneName.IsNone() && SkellyMesh != nullptr)
			return SkellyMesh.GetSocketLocation(BoneName);
		if (Actor != nullptr)
			return Actor.ActorLocation;
		check(false, "No location assigned in FSanctuaryCompanionAviationDestinationData");
		return FVector::ZeroVector;
	}

	bool IsValid() const
	{
		if (HasRuntimeSpline())
			return true;
		if (!BoneName.IsNone() && SkellyMesh != nullptr)
			return true;
		if (Actor != nullptr)
			return true;
		return false;
	}

	void GetSplineData(FVector WorldLocation, float AddedDistance, FSanctuaryCompanionAviationDestinationSplineData& OutData) const
	{
		if (RuntimeSpline.Points.Num() == 2)
		{
			FVector StartLocation = RuntimeSpline.GetLocationAtDistance(0.0);
			FVector EndLocation = RuntimeSpline.GetLocationAtDistance(RuntimeSpline.Length);

			FVector ClosestPoint = Math::ClosestPointOnLine(StartLocation, EndLocation, WorldLocation);
			float MaxDistance = (EndLocation - StartLocation).Size();
			float CurrentDistance = (ClosestPoint - StartLocation).Size();
			float DistanceInFuture = CurrentDistance + AddedDistance;
			if (DistanceInFuture >= MaxDistance)
			{
				OutData.bIsAtEnd = true;
				DistanceInFuture = Math::Clamp(DistanceInFuture, 0.0, MaxDistance);
			}
			OutData.SplineDirection = (EndLocation - StartLocation).GetSafeNormal();
			OutData.NextSplineLocation = StartLocation + OutData.SplineDirection * DistanceInFuture;
			OutData.TraversedPercent = CurrentDistance / MaxDistance;
		}
		else
		{
			FVector ClosestLocation = RuntimeSpline.GetClosestLocationToLocation(WorldLocation);
			float SplineDistance = RuntimeSpline.GetClosestSplineDistanceToLocation(ClosestLocation);
			// if (OutData.bGuaranteeProgress)
			// {
			// 	if (SplineDistance < OutData.SplineDistance)
			// 		SplineDistance = OutData.SplineDistance;
			// 	OutData.SplineDistance = SplineDistance;
			// }
			float NewDistance = SplineDistance + AddedDistance;
			if (NewDistance >= RuntimeSpline.Length - KINDA_SMALL_NUMBER)
				OutData.bIsAtEnd = true;
			SplineDistance = Math::Clamp(NewDistance, 0.0, RuntimeSpline.Length);
			FQuat SplineRot;
			RuntimeSpline.GetLocationAndQuatAtDistance(SplineDistance, OutData.NextSplineLocation, SplineRot);
			OutData.SplineDirection = SplineRot.ForwardVector;
			OutData.TraversedPercent = SplineDistance / RuntimeSpline.Length;
		}
	}
}

enum ESanctuaryAviationLane
{
	Left = 0,
	Middle,
	Right
}

struct FSanctuaryAviationLane
{
	FVector StartLocation;
	FVector EndLocation;
}

// not REALLY left & right but we need to discern two opposite sides, so now they are left and right.
// Left is considered to be the negative side of origo (X,Y) while Right is the positive side of origo (X,Y)
enum ESanctuaryArenaSide
{
	Left = 0,
	Right
}

// So if you are in a quadrant (ESanctuaryArenaSide), are you in the left or the right half of that quadrant?
enum ESanctuaryArenaSideOctant
{
	Left = 0,
	Right
}
