class APaddleRaftPushingForceSpline : ASplineActor
{
	UPROPERTY(EditAnywhere)
	float PushingForce = 500;

	UPROPERTY(EditAnywhere)
	float AttenuationDistance = 500;

	UPROPERTY(EditAnywhere)
	bool bFlipForceDirection = false;

	UPROPERTY(EditAnywhere)
	float VisualizeInterval = 100.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UFUNCTION()
	FVector GetForceAtLocation(FVector WorldLocation)
	{
		FSplinePosition SplinePos = Spline.GetClosestSplinePositionToWorldLocation(WorldLocation);
		FVector ForceDirection = SplinePos.WorldRightVector;
		if (bFlipForceDirection)
			ForceDirection = -ForceDirection;

		float Attenuation = GetScaledAttenuationAtSplinePosition(SplinePos);
		if (SplinePos.WorldLocation.DistSquared(WorldLocation) > Attenuation * Attenuation)
			return FVector::ZeroVector;

		float Dot = (WorldLocation - SplinePos.WorldLocation).DotProduct(ForceDirection);

		if (Dot > Attenuation)
			return FVector::ZeroVector;

		// Max Force (Pushing Force) at 0 Dist
		// Min Force (0) at AttenuationDistance

		//Debug::DrawDebugSphere(SplinePos.WorldLocation, 300, 12, FLinearColor::Yellow, 10);

		float Alpha = 1 - Math::Saturate(Math::NormalizeToRange(Dot, 0, Attenuation));
		float Force = GetScaledForceAtSplinePosition(SplinePos) * Alpha;

		//Print(f"{Force=}", 1);

		return ForceDirection * Force;
	}

	float GetScaledForceAtSplinePosition(FSplinePosition SplinePos) const
	{
		return SplinePos.WorldScale3D.Y * PushingForce;
	}

	float GetScaledAttenuationAtSplinePosition(FSplinePosition SplinePos) const
	{
		return SplinePos.WorldScale3D.Y * AttenuationDistance;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		float Dist = 0;
		FVector PreviousAttenuationVisualizePoint = Spline.GetWorldLocationAtSplineFraction(0);
		while (Dist < Spline.SplineLength)
		{
			FSplinePosition SplinePos = Spline.GetSplinePositionAtSplineDistance(Dist);
			FVector Direction = bFlipForceDirection ? -SplinePos.WorldRightVector : SplinePos.WorldRightVector;
			float Attenuation = GetScaledAttenuationAtSplinePosition(SplinePos);
			Debug::DrawDebugDirectionArrow(SplinePos.WorldLocation, Direction, Attenuation, 40, FLinearColor::Red, 10);
			FVector AttenuationStart = PreviousAttenuationVisualizePoint;
			FVector AttenuationEnd = SplinePos.WorldLocation - FVector::UpVector * 10 + Direction * GetScaledAttenuationAtSplinePosition(SplinePos);
			if (Dist >= SMALL_NUMBER)
			{
				Debug::DrawDebugLine(AttenuationStart, AttenuationEnd, FLinearColor::Yellow, 5);
			}

			PreviousAttenuationVisualizePoint = AttenuationEnd;

			Dist += VisualizeInterval;
		}
	}

#endif
};