struct FScenepointPerchPosition
{
	UPerchScenepointComponent Perch;
	float DistAlongPerch;
	FVector Location;
	FVector UpVector;
	float ClaimedTime;

	bool IsValid() const
	{
		return (Perch != nullptr) && !Perch.IsBeingDestroyed();
	}

	void Release()
	{
		Perch.ReleasePerch(DistAlongPerch);
		Perch = nullptr;
	}
}

class APerchScenepointActor : AScenepointActorBase
{
	UPROPERTY(DefaultComponent)
	private UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	UHazeSplineComponent PerchSpline;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	UPerchScenepointComponent PerchComp;
	default PerchComp.Spline = PerchSpline;

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}

class UPerchScenepointComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float PerchIntervalFromStart = 500.0;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float PerchIntervalFromEnd = 500.0;

	UHazeSplineComponent Spline;
	TArray<float> ClaimedPerches;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Spline == nullptr)
			return;

		if (PerchIntervalFromStart + PerchIntervalFromEnd > Spline.SplineLength)
		{
			float Scale = (Spline.SplineLength - 1.0) / (PerchIntervalFromStart + PerchIntervalFromEnd);
			PerchIntervalFromStart *= Scale;
			PerchIntervalFromEnd *= Scale;
		}
	}

	bool IsValidTarget(AHazeActor Target, float DistanceAlongPerch, float MaxSectionWidth = BIG_NUMBER) const
	{
		if (Spline == nullptr)
			return false;	

		// Simple check to see if target is below/above the perch spline section.
		// This will not work well if spline curves back and forth. If we want that 
		// we should step along spline in when checking if within section distance instead.
		FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(DistanceAlongPerch);
		FVector TargetOffset = SplineTransform.InverseTransformPositionNoScale(Target.ActorCenterLocation);
		if (TargetOffset.X > 0.0) 
		{
			// Ahead along spline
			float SectionMax = Math::Min(Spline.SplineLength - DistanceAlongPerch, MaxSectionWidth);
			return (TargetOffset.X < SectionMax);
		}

		// Behind along spline
		float SectionMin = Math::Max(-DistanceAlongPerch, -MaxSectionWidth);
		return (TargetOffset.X > SectionMin);		
	}

	FScenepointPerchPosition GetClosestAvailablePerch(FVector Location, float MinInterval)
	{
		return GetClosestAvailablePerch(Spline.GetClosestSplineDistanceToWorldLocation(Location), MinInterval);
	}

	FScenepointPerchPosition GetClosestAvailablePerch(float DistAlongPerch, float MinInterval)
	{
		float ClosestDist = DistAlongPerch;
		ClosestDist = Math::Clamp(ClosestDist, PerchIntervalFromStart, Spline.SplineLength - PerchIntervalFromEnd); 
		int Interval = FindClaimedInterval(ClosestDist);
		float FwdDist = ClosestDist;
		for (int i = Interval; i < ClaimedPerches.Num(); i++)
		{
			// Did we find an interval with enough space?
			if (FwdDist < ClaimedPerches[i] - MinInterval)
				break; 

			// Do we need to push position past this claimed perch?
			if (FwdDist < ClaimedPerches[i] + MinInterval)
				FwdDist = ClaimedPerches[i] + MinInterval; 
		}
		if (FwdDist > Spline.SplineLength - PerchIntervalFromEnd)
			FwdDist = BIG_NUMBER; // No interval available in forward direction
		
		// Search backwards in similar fashion
		float BwdDist = ClosestDist;
		for (int i = Interval - 1; i >= 0; i--)
		{
			if (BwdDist > ClaimedPerches[i] + MinInterval)
				break; 
			if (BwdDist > ClaimedPerches[i] - MinInterval)
				BwdDist = ClaimedPerches[i] - MinInterval; 
		}
		if (BwdDist < PerchIntervalFromStart)
		{
			BwdDist = -BIG_NUMBER; // No interval available in backward direction
			if (FwdDist == BIG_NUMBER)
				return FScenepointPerchPosition(); // No available intervals
		}

		// We have an available position, use closest one
		FScenepointPerchPosition Pos;
		Pos.Perch = this;
		Pos.DistAlongPerch = ((FwdDist - ClosestDist) < (ClosestDist - BwdDist)) ? FwdDist : BwdDist;
		FTransform PerchTransform = Spline.GetWorldTransformAtSplineDistance(Pos.DistAlongPerch);
		Pos.Location = PerchTransform.Location;
		Pos.UpVector  = PerchTransform.Rotation.UpVector; 
		return Pos;
	}

	int FindClaimedInterval(float DistAlongPerch) const 
	{
		for (int i = 0; i < ClaimedPerches.Num(); i++)
		{
			if (DistAlongPerch < ClaimedPerches[i])
				return i;
		}
		return ClaimedPerches.Num();
	}

	void ClaimPerch(float DistAlongPerch)
	{
		ClaimedPerches.Insert(DistAlongPerch, FindClaimedInterval(DistAlongPerch));
	}

	void ReleasePerch(float DistAlongPerch)
	{
		for (int i = 0; i < ClaimedPerches.Num(); i++)
		{
			if (Math::IsNearlyEqual(DistAlongPerch, ClaimedPerches[i], 0.1))
			{
				ClaimedPerches.RemoveAt(i);				
				return;
			}
		}
	}
}

#if EDITOR
class UPerchScenepointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPerchScenepointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UPerchScenepointComponent Comp = Cast<UPerchScenepointComponent>(Component);

		if (!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;
		if (Comp.Spline == nullptr)
			return;

		float FromStart = Comp.PerchIntervalFromStart;
		float FromEnd = Comp.PerchIntervalFromEnd;
		if (FromStart + FromEnd > Comp.Spline.SplineLength)
		{
			float Scale = (Comp.Spline.SplineLength - 1.0) / (FromStart + FromEnd);
			FromStart *= Scale;
			FromEnd *= Scale;
		}
		DrawWireDiamond(Comp.Spline.GetWorldLocationAtSplineDistance(FromStart), FRotator::ZeroRotator, 20, FLinearColor::Green, 3.0);	
		DrawWireDiamond(Comp.Spline.GetWorldLocationAtSplineDistance(Comp.Spline.SplineLength - FromEnd), FRotator::ZeroRotator, 20, FLinearColor::Yellow, 3.0);	
	}
} 
#endif

