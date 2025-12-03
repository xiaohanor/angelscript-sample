class USanctuarySnakeTailCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::AfterPhysics;
	default CapabilityTags.Add(n"SanctuarySnake");

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;
	USanctuarySnakeTailComponent TailComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailComponent = USanctuarySnakeTailComponent::Get(Owner);

/*
		Settings = USanctuarySnakeSettings::GetSettings(Owner);

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		TailComponent = USanctuarySnakeTailComponent::Get(Owner);

		SanctuarySnakeComponent.SnakeLength = Settings.StartLength;

		float SegmentLength = GetSegmentLenght();

		TrailPoints.Add(SnakeHeadGroundLocation);
		TrailUp.Add(SanctuarySnakeComponent.WorldUp);

		for (int i = 0; i < Settings.NumSegments; i++)
		{
			FVector Point = SnakeHeadGroundLocation - Owner.ActorForwardVector * SegmentLength * (i + 1);
			TrailPoints.Add(Point);
			TrailUp.Add(SanctuarySnakeComponent.WorldUp);

			auto Segment = Cast<USanctuarySnakeTailSegmentComponent>(Owner.CreateComponent(SanctuarySnakeComponent.SegmentClass));
			Segment.WorldLocation = Point;
			Segment.WorldRotation = FRotator::MakeFromXZ(Owner.ActorForwardVector, SanctuarySnakeComponent.WorldUp);
			float Scale = 1.0 - (float(i) / Settings.NumSegments) * 0.4;
//			Segment.RelativeScale3D *= FVector(1.0, Scale, 1.0);
			Segment.RelativeScale3D *= FVector(1.0, Scale * (i%2 == 0 ? 1.0 : -1.0), 1.0);
			TailSegments.Add(Segment);
		}
*/
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	/*
		for (int i = 0; i < Settings.NumSegments; i++)
		{
			FHazePlaySlotAnimationParams AnimationParams;
			AnimationParams.Animation = TailSegments[i].Animation;
			AnimationParams.bLoop = true;
			AnimationParams.StartTime = float(i) / Settings.NumSegments;
			TailSegments[i].PlaySlotAnimation(AnimationParams);
		}
	*/
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TailComponent.UpdateTail();
/*
		int LastIndex = TrailPoints.Num() - 1;
		float SegmentLength = GetSegmentLenght();

		if (!SnakeHeadGroundLocation.IsWithinDist(TrailPoints[1], SegmentLength))
		{
			TrailPoints.RemoveAt(LastIndex);
			TrailPoints.Insert(TrailPoints[0], 1);

			TrailUp.RemoveAt(LastIndex);
			TrailUp.Insert(TrailUp[0], 1);
		}
		
		TrailPoints[0] = SnakeHeadGroundLocation;
		TrailUp[0] = SanctuarySnakeComponent.WorldUp;

		float Distance = (TrailPoints[0] - TrailPoints[1]).Size();
		float Alpha = Distance / SegmentLength;
		Print("Alpha: " + Alpha, 0.0, FLinearColor::Green);
		FVector Direction = (TrailPoints[LastIndex - 1] - TrailPoints[LastIndex]).GetSafeNormal();
		TrailPoints[LastIndex] = TrailPoints[LastIndex - 1] - Direction * (SegmentLength - Distance);

		FHazeRuntimeSpline TailSpline;
		TailSpline.Points = TrailPoints;

		TArray<FVector> SplineLocations;
		TArray<FVector> SplineDirections;

		Print("TrailPoints: " + TrailPoints.Num(), 0.0, FLinearColor::Green);
		Print("Segments: " + Settings.NumSegments, 0.0, FLinearColor::Green);

		TailSpline.GetLocations(SplineLocations, TrailPoints.Num());
		TailSpline.GetDirections(SplineDirections, TrailPoints.Num());
		for (int i = 0; i < Settings.NumSegments; i++)
		{
			FVector SegmentUp = TrailUp[i + 1].SlerpTowards(TrailUp[i], Alpha);

			TailSegments[i].WorldRotation = FRotator::MakeFromXZ(-SplineDirections[i + 1], SegmentUp);
			TailSegments[i].WorldLocation = SplineLocations[i + 1] + TailSegments[i].WorldRotation.UpVector * SegmentHeightOffset;
		//	Debug::DrawDebugLine(TailSegments[i].WorldLocation, TailSegments[i].WorldLocation + SegmentUp * 150.0, FLinearColor::Blue, 3.0, 0.0);
		
			float PlayRate = Owner.ActorVelocity.Size() / Settings.Acceleration;

			TailSegments[i].SetSlotAnimationPlayRate(TailSegments[i].Animation, PlayRate * 3.0);
		}

		// Draw trail debug
	//	DebugTrail();

		// Draw spline debug
	//	DebugSpline(TailSpline,  Settings.NumSegments * 8);
*/
	}

	/*
	float GetSegmentLenght()
	{
		return Settings.StartLength / Settings.NumSegments;
	}
	*/

/*
	FVector GetSnakeHeadGroundLocation() property
	{
		return Owner.ActorLocation; // - Owner.MovementWorldUp * SnakeMovementComponent.ShapeComponent.BoundsRadius;
	}
*/

/*
	float GetSegmentHeightOffset() property
	{
		return Settings.SegmentHeightOffset;
	}
*/

/*
	void DebugSpline(FHazeRuntimeSpline Spline, int Res, float VerticalOffset = 0.0)
	{
		float Offset = Spline.Length / Res;

		for (int i = 0; i < Res; i++)
		{
			FVector LineStart = Spline.GetLocationAtDistance(i * Offset);
			FVector LineEnd = Spline.GetLocationAtDistance((i + 1) * Offset);
			Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Red, 5.0, 0.0);
		}
	}

	void DebugTrail()
	{
		for (int i = 0; i < TrailPoints.Num(); i++)
			Debug::DrawDebugLine(TrailPoints[i], TrailPoints[i] + TrailUp[i] * 100.0, FLinearColor::Green, 3.0, 0.0);
	}
*/
}