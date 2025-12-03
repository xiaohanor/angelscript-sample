
mixin void ApplySplineRelativePositionSync(
	UHazeCrumbSyncedActorPositionComponent Comp,
	FInstigator Instigator, FSplinePosition SplinePosition,
	EInstigatePriority Priority = EInstigatePriority::Normal)
{
	Comp.InternalApplyRelativeSplinePositionSync(
		Instigator,
		SplinePosition.CurrentSpline,
		SplinePosition.CurrentSplineDistance,
		SplinePosition.IsForwardOnSpline(),
		Priority,
	);
}

mixin FSplinePosition GetSyncedSplinePosition(FHazeSyncedActorPosition ActorPosition)
{
	FSplinePosition SplinePos(Cast<UHazeSplineComponent>(ActorPosition.RelativeComponent), ActorPosition.RelativeSplineDistance, ActorPosition.bRelativeSplineForward);
	return SplinePos;
}

class UCrumbSplineHelper : UHazeCrumbSplinePositionHelper
{
	UFUNCTION(BlueprintOverride)
	FTransform GetTransformForSplinePosition(USceneComponent Spline, float SplineDistance)
	{
		FSplinePosition Pos(Cast<UHazeSplineComponent>(Spline), SplineDistance, true);
		if (!Pos.IsValid())
			return FTransform::Identity;
		else
			return Pos.WorldTransform;
	}

	UFUNCTION(BlueprintOverride)
	void PerformSplinePositionLerp(FHazeSyncedActorPosition A, FHazeSyncedActorPosition B, float Alpha,
	                               FHazeSyncedActorPosition& OutPosition)
	{
		if (A.RelativeType != B.RelativeType)
		{
			// We're switching away from a spline-relative position
			MakeFallbackRelativeSplinePosition(A, B, Alpha, OutPosition);
			return;
		}

		FSplinePosition SplinePosA(Cast<UHazeSplineComponent>(A.RelativeComponent), A.RelativeSplineDistance, A.bRelativeSplineForward);
		FSplinePosition SplinePosB(Cast<UHazeSplineComponent>(B.RelativeComponent), B.RelativeSplineDistance, B.bRelativeSplineForward);

		if (!SplinePosA.IsValid() || !SplinePosB.IsValid())
		{
			// We're leaving a spline's relative space
			MakeFallbackRelativeSplinePosition(A, B, Alpha, OutPosition);
			return;
		}

		float DeltaDistance = SplinePosA.DeltaToReachClosest(SplinePosB);
		if (DeltaDistance == MAX_flt)
		{
			// Spline points are not connected
			MakeFallbackRelativeSplinePosition(A, B, Alpha, OutPosition);
			return;
		}

		// First lerp the spline position between the two spline positions we have
		FSplinePosition SplinePosLerped = SplinePosA;
		SplinePosLerped.Move(Alpha * DeltaDistance);

		OutPosition.RelativeComponent = SplinePosLerped.CurrentSpline;
		OutPosition.RelativeSplineDistance = SplinePosLerped.CurrentSplineDistance;
		OutPosition.bRelativeSplineForward = SplinePosLerped.IsForwardOnSpline();

		FTransform PosTransformA = SplinePosA.WorldTransform;
		FTransform PosTransformB = SplinePosB.WorldTransform;

		FTransform LerpedPosTransform = SplinePosLerped.WorldTransform;

		// Re-lerp the world location, so instead of lerping between the two world locations on the spline,
		// it lerps *along* the spline. We do that by lerping the offsets instead.
		FVector OffsetA = PosTransformA.InverseTransformPositionNoScale(A.WorldLocation);
		FVector OffsetB = PosTransformB.InverseTransformPositionNoScale(B.WorldLocation);

		OutPosition.RelativeLocation = Math::Lerp(OffsetA, OffsetB, Alpha);
		OutPosition.WorldLocation = LerpedPosTransform.TransformPositionNoScale(OutPosition.RelativeLocation);
		OutPosition.RelativeVelocity = Math::Lerp(A.RelativeVelocity, B.RelativeVelocity, Alpha);
		OutPosition.WorldVelocity = LerpedPosTransform.TransformVectorNoScale(OutPosition.RelativeVelocity);

		// Re-lerp the world rotation
		FQuat RotationA = PosTransformA.InverseTransformRotation(A.WorldRotation.Quaternion());
		FQuat RotationB = PosTransformB.InverseTransformRotation(B.WorldRotation.Quaternion());

		FQuat LerpedRotation = FQuat::Slerp(RotationA, RotationB, Alpha);
		OutPosition.RelativeRotation = LerpedRotation.Rotator();
		OutPosition.WorldRotation = LerpedPosTransform.TransformRotation(LerpedRotation).Rotator();
	}

	void MakeFallbackRelativeSplinePosition(FHazeSyncedActorPosition A, FHazeSyncedActorPosition B,
	                                        float Alpha, FHazeSyncedActorPosition& OutPosition)
	{
		FSplinePosition SplinePosB(Cast<UHazeSplineComponent>(B.RelativeComponent), B.RelativeSplineDistance, B.bRelativeSplineForward);
		if (SplinePosB.IsValid())
		{
			FTransform RelativeToTransform = SplinePosB.WorldTransform;
			OutPosition.RelativeLocation = RelativeToTransform.InverseTransformPositionNoScale(OutPosition.WorldLocation);
			OutPosition.RelativeRotation = RelativeToTransform.InverseTransformRotation(OutPosition.WorldRotation.Quaternion()).Rotator();
			OutPosition.RelativeVelocity = RelativeToTransform.InverseTransformVectorNoScale(OutPosition.WorldVelocity);
		}
		else
		{

			OutPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;
			OutPosition.RelativeLocation = FVector::ZeroVector;
			OutPosition.RelativeVelocity = FVector::ZeroVector;
			OutPosition.RelativeRotation = FRotator::ZeroRotator;
		}
	}
}