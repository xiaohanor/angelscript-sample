struct FTrailSegmentSpecification
{
	UPROPERTY()
	float SegmentInterval = 0.1;

	UPROPERTY()
	int SegmentSize = 10;

	FTrailSegmentSpecification(float Interval, int Size)
	{
		SegmentInterval = Interval;
		SegmentSize = Size;
	}
}

struct FTargetTrailSegment
{
	float Interval;
	TArray<FVector> Locations;
	int HeadIndex = 0;
	float AccumulatedHeadTime = 0.0;

	FTargetTrailSegment(float IntervalDuration, int NumSlots, FVector InitialLocation)
	{
		Interval = IntervalDuration;
		Locations.SetNum(NumSlots);
		for (int i = 0; i < NumSlots; i++)
		{
			Locations[i] = InitialLocation;
		}
	}

	float GetDuration() const property
	{
		// Note that as we have n locations there are n-1 intervals.
		return Interval * (Locations.Num() - 1) + AccumulatedHeadTime;
	}

	FVector GetLocation(float Age, FVector PrevLastLoc) const
	{
		if ((Interval < SMALL_NUMBER) || (Age < 0.0))
			return PrevLastLoc;

		// Before head of trail?
		if (Age < AccumulatedHeadTime)
			return Math::Lerp(PrevLastLoc, Locations[HeadIndex], Age / AccumulatedHeadTime);		

		// Within trail segment. 
		float AdjustedAge = Age - AccumulatedHeadTime;
		int iStart = (HeadIndex + Math::TruncToInt(AdjustedAge / Interval)) % Locations.Num();
		int iEnd = (iStart + 1) % Locations.Num();
		return Math::Lerp(Locations[iStart], Locations[iEnd], Math::Fmod(AdjustedAge, Interval) / Interval);		
	}

	FVector GetHeadLocation() const
	{
		return Locations[HeadIndex];
	}

	FVector GetLastLocation() const
	{
		return Locations[(HeadIndex - 1 + Locations.Num()) % Locations.Num()];
	}

	bool ConsumeTime(float TimeInterval)
	{
		AccumulatedHeadTime += TimeInterval;
		if (AccumulatedHeadTime < Interval)
			return false;
		AccumulatedHeadTime = Math::Min(AccumulatedHeadTime - Interval, Interval);	
		return true;
	}

	FVector UpdateTrail(FVector HeadLocation)
	{
		// Move trail one step backward (older points in trail are at higher wrapped indices)
		HeadIndex = (HeadIndex - 1 + Locations.Num()) % Locations.Num();

		// Overwrite last point on trail 
		FVector LastLocation = Locations[HeadIndex];
		Locations[HeadIndex] = HeadLocation;

		// Return the expired location at the end of this segment so we can pass that to any following segment
		return LastLocation;
	}
}

class UTargetTrailComponent : UActorComponent
{
	// Tick after movement but before gameplay
	default TickGroup = ETickingGroup::TG_PrePhysics;

	private TArray<FTargetTrailSegment> Trail;

	UPROPERTY()
	TArray<FTrailSegmentSpecification> TrailSpecification;
	default TrailSpecification.SetNum(4);
	default TrailSpecification[0] = FTrailSegmentSpecification(0.1, 20); // Recent points
	default TrailSpecification[1] = FTrailSegmentSpecification(0.2, 10); // Intermediate points
	default TrailSpecification[2] = FTrailSegmentSpecification(0.5, 10); // Old points
	default TrailSpecification[3] = FTrailSegmentSpecification(5.0 , 10); // Ancient points

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResetTrail();
		UTeleportResponseComponent::GetOrCreate(Owner).OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	void ResetTrail()
	{
		Trail.Empty(TrailSpecification.Num() + 1);
		FVector InitialLoc = Owner.ActorLocation;

		// Add a 'trail head' segment containing only the latest updated location
		Trail.Add(FTargetTrailSegment(0.0, 1, InitialLoc));

		// Add any specified trail segments
		for (FTrailSegmentSpecification Spec : TrailSpecification)
		{
			Trail.Add(FTargetTrailSegment(Spec.SegmentInterval, Spec.SegmentSize, InitialLoc));
		}	
	}

	UFUNCTION()
	private void OnTeleported()
	{
		ResetTrail();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TimeInterval = DeltaTime;
		FVector Location = Owner.ActorLocation;		
		for (FTargetTrailSegment& Segment : Trail)
		{
			// Check if segment should be updated
			if (!Segment.ConsumeTime(TimeInterval))
				break; // No time for later segments to consume
			Location = Segment.UpdateTrail(Location);
			TimeInterval = Math::Max(Segment.Interval, DeltaTime);
		}
	}

	FVector GetTrailLocation(float Age) const
	{
		float AdjustedAge = Age - SMALL_NUMBER;
		FVector PrevLastLoc = Trail[0].GetHeadLocation();
		for (FTargetTrailSegment Segment : Trail)
		{
			if (AdjustedAge < Segment.Duration)
				return Segment.GetLocation(AdjustedAge, PrevLastLoc);
			AdjustedAge -= Segment.Duration;
			PrevLastLoc = Segment.GetLastLocation();		
		}

		// We know nothing of this ancient past, use last trail location
		return Trail.Last().GetLastLocation();	
	}

	// Gets the average velocity for the interval Age..(Age + Duration) seconds ago.
	FVector GetAverageVelocity(float Duration, float Age = 0.0) const
	{
		FVector RecentLocation = (Age < SMALL_NUMBER) ? Owner.ActorLocation : GetTrailLocation(Age);
		FVector OlderLocation = GetTrailLocation(Age + Duration);
		return (RecentLocation - OlderLocation) / Math::Max(Duration, 0.0001); 
	}

	void DrawDebug(FLinearColor Color)
	{
		FVector PrevLoc = Owner.ActorLocation;
		for (float Age = 0.1; Age < 60.0; Age += 0.17)
		{
			FVector Loc = GetTrailLocation(Age);
			Debug::DrawDebugLine(Loc, PrevLoc, FLinearColor::Yellow, 5.0);
			PrevLoc = Loc;
		}

		PrevLoc = Owner.ActorLocation;
		for (FTargetTrailSegment Segment : Trail)
		{
			for (int i = 0; i < Segment.Locations.Num(); i++)
			{
				FVector Loc = Segment.Locations[(Segment.HeadIndex + i) % Segment.Locations.Num()];
				Debug::DrawDebugLine(Loc, PrevLoc, Color, 6.0);
				Debug::DrawDebugSphere(Loc, 10, 4, Color);
				PrevLoc = Loc;
			}	
		}

	}
}
