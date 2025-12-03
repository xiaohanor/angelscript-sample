class USanctuarySnakeTailComponent : UActorComponent
{
	UPROPERTY()
	float SnakeTailLength = 0.0;

	TArray<USanctuarySnakeTailSegmentComponent> TailSegments;
	TArray<FVector> TrailPoints;
	TArray<FVector> TrailUp;
	TArray<FRotator> TrailRotations;

	UPROPERTY()
	TArray<FName> SegmentSocketNames;

	TArray<float> SegmentDistances;

	FHazeRuntimeSpline TailSpline;

	UPROPERTY()
	TArray<FTransform> SegmentTransforms;

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = USanctuarySnakeSettings::GetSettings(Cast<AHazeActor>(Owner));

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);

		SegmentTransforms.SetNum(SegmentSocketNames.Num());

		// Get Distances for all segments from SkeletalMesh
		auto SkeletalMesh = UHazeSkeletalMeshComponentBase::Get(Owner);

		if(SkeletalMesh == nullptr)
		{
			check(false);
			return;
		}

		// TODO: Preferably the spline could be just a few units longer, to support a bit of stretching (right now the spline becomes shorter as you turn?)
		SnakeTailLength = SkeletalMesh.GetDistanceBetweenBones(n"Head", n"Tail12");

		
		// SnakeTailLength = 0;
		// for (int i = 0; i < SegmentSocketNames.Num(); i++)
		// {
		// 	float Length = SkeletalMesh.GetBoneBindLocalTransform(SegmentSocketNames[i]).Location.Size();
		// 	SnakeTailLength += Length;
		// 	SegmentDistances.Add(SnakeTailLength);
		// }

		TrailPoints.Add(Owner.ActorLocation);
		TrailUp.Add(SanctuarySnakeComponent.WorldUp);
		TrailRotations.Add(SkeletalMesh.WorldRotation);

		float SegmentLength = SnakeTailLength / SegmentSocketNames.Num();

		// TODO: The number of points must currently match SegmentSocketNames.Num()
		// This can be tweaked as soon as there exists a GetRotationAtDistance() function that can be used in the ABP node. 
		for (int i = 0; i < SegmentSocketNames.Num(); i++)
		{
			FVector Point = Owner.ActorLocation - Owner.ActorForwardVector * SegmentLength * (i + 1);
			TrailPoints.Add(Point);
			TrailUp.Add(SanctuarySnakeComponent.WorldUp);
			TrailRotations.Add(SkeletalMesh.WorldRotation);
		}


//		SnakeTailLength = Settings.StartLength * Owner.ActorScale3D.X; // Old

/* Old segment creation
		float SegmentLength = GetSegmentLenght();

		TrailPoints.Add(Owner.ActorLocation);
		TrailUp.Add(SanctuarySnakeComponent.WorldUp);

		for (int i = 0; i < Settings.NumSegments; i++)
		{
			FVector Point = Owner.ActorLocation - Owner.ActorForwardVector * SegmentLength * (i + 1);
			TrailPoints.Add(Point);
			TrailUp.Add(SanctuarySnakeComponent.WorldUp);

			auto Segment = Cast<USanctuarySnakeTailSegmentComponent>(Owner.CreateComponent(SanctuarySnakeComponent.SegmentClass));
			Segment.WorldLocation = Point;
			Segment.WorldRotation = FRotator::MakeFromXZ(Owner.ActorForwardVector, SanctuarySnakeComponent.WorldUp);
			float Scale = 1.0 - (float(i) / Settings.NumSegments) * 0.4;
			Segment.RelativeScale3D *= FVector(1.0, Scale * (i%2 == 0 ? 1.0 : -1.0), 1.0);
			TailSegments.Add(Segment);
		}		
	
		// Setup Animations
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

	void UpdateTail()
	{
		if (TrailPoints.Num() <= 1)
			return;

		int LastIndex = TrailPoints.Num() - 1;
		float SegmentLength = SnakeTailLength / Settings.NumSegments;

		if (TrailPoints.Num() > 1 && !Owner.ActorLocation.IsWithinDist(TrailPoints[1], SegmentLength))
		{
			TrailPoints.RemoveAt(LastIndex);
			TrailPoints.Insert(TrailPoints[0], 1);

			TrailUp.RemoveAt(LastIndex);
			TrailUp.Insert(TrailUp[0], 1);

			TrailRotations.RemoveAt(LastIndex);
			TrailRotations.Insert(TrailRotations[0], 1);
		}
		
		TrailPoints[0] = Owner.ActorLocation;
		TrailUp[0] = SanctuarySnakeComponent.WorldUp;

		float Distance = (TrailPoints[0] - TrailPoints[1]).Size();
		float Alpha = Distance / SegmentLength;
		
		FVector Direction = (TrailPoints[LastIndex - 1] - TrailPoints[LastIndex]).GetSafeNormal();
		TrailPoints[LastIndex] = TrailPoints[LastIndex - 1] - Direction * (SegmentLength - Distance);

		Direction = (TrailPoints[1] - TrailPoints[0]).GetSafeNormal();
		TrailRotations[0] = FRotator::MakeFromXZ(Direction, TrailUp[0]);
		
		TailSpline.Points = TrailPoints;
		TailSpline.UpDirections = TrailUp;

		// TailSpline.Rotations = TrailRotations;

		// TArray<FVector> SplineLocations;
		// TArray<FVector> SplineDirections;

//		Print("TrailPoints: " + TrailPoints.Num(), 0.0, FLinearColor::Green);
//		Print("Segments: " + Settings.NumSegments, 0.0, FLinearColor::Green);

/*
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
*/

		// Update Segment Transform Array
		/*
		for (int i = 0; i < SegmentDistances.Num(); i++)
		{
			FVector SegmentUp = TrailUp[i + 1].SlerpTowards(TrailUp[i], Alpha);

			SegmentTransforms[i].Location = TailSpline.GetLocationAtDistance(SegmentDistances[i]);
			
			if (i <= 8)
				// Spline/Neck
				SegmentTransforms[i].Rotation = FQuat::MakeFromZX(-TailSpline.GetDirectionAtDistance(SegmentDistances[i]), SegmentUp);
			else if (i == 10)
				// Hip bone
				SegmentTransforms[i].Rotation = FQuat::MakeFromXZ(-TailSpline.GetDirectionAtDistance(SegmentDistances[i]), SegmentUp);
			else
				// Tail
				SegmentTransforms[i].Rotation = FQuat::MakeFromZX(TailSpline.GetDirectionAtDistance(SegmentDistances[i]), SegmentUp);
			
			Debug::DrawDebugCoordinateSystem(SegmentTransforms[i].Location, SegmentTransforms[i].Rotation.Rotator(), 300.0, 5.0, 0.0);
		//	Print("Segments: " + SegmentDistances[i], 0.0, FLinearColor::Green);
		}
		*/

	}

	// Reset trail behing snake
	void ResetTail(FVector ForwardVector, FVector UpVector)
	{
		if(Settings.NumSegments != TrailPoints.Num())
		{
			check(false);
			return;
		}

		for (int i = 0; i < Settings.NumSegments; i++)
		{
			TrailPoints[i] = Owner.ActorLocation - Owner.ActorForwardVector * GetSegmentLenght() * i;
			TrailUp[i] = SanctuarySnakeComponent.WorldUp;
		}
	}

	float GetSegmentLenght()
	{
		return (Settings.StartLength / Settings.NumSegments) * Owner.ActorScale3D.X;
	}

	float GetSegmentHeightOffset() property
	{
		return Settings.SegmentHeightOffset * Owner.ActorScale3D.Z;
	}

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
}