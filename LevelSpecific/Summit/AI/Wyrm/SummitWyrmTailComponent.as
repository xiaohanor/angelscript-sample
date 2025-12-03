
struct FWyrmSegmentLocationOffsetLerp
{
	FWyrmSegmentLocationOffsetLerp(FHazeAcceleratedVector Targ, float LerpDuration)
	{
		Target = Targ;
		RemainingDuration = LerpDuration;
	}

	FHazeAcceleratedVector Target;
	float RemainingDuration = 0.0;
	int CurrentIndexOffset = 0;
}
class USummitWyrmTailComponent : UActorComponent
{
	UPROPERTY()
	FVector HeadWorldUp = FVector::UpVector;

	UPROPERTY()
	TSubclassOf<USummitWyrmTailSegmentComponent> CrystalSegmentClass;

	UPROPERTY()
	TSubclassOf<USummitWyrmTailSegmentComponent> MetalSegmentClass;

	TArray<USummitWyrmTailSegmentComponent> TailSegments;
	TArray<FVector> TrailPoints;
	TArray<FVector> TrailUp;
	USummitWyrmSettings Settings;
	float TailLength = 0.0;
	
	float DamageReactionTimer = 0.0;
	bool bIsRunningDamageReaction = false;

	TArray<FHazeAcceleratedVector> DamageReactionOffsets;	
	TArray<FVector> DamageReactionOffsetTargetsLocal;
	TArray<FWyrmSegmentLocationOffsetLerp> LocationOffsetLerpParams; // TODO: needs to be reset if respawned

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = USummitWyrmSettings::GetSettings(Cast<AHazeActor>(Owner));

		TailLength = Settings.StartLength * Owner.ActorScale3D.X;

		float SegmentLength = GetSegmentLenght();

		TrailPoints.Add(Owner.ActorLocation);
		TrailUp.Add(FVector::UpVector);

		for (int i = 0; i < Settings.NumSegments; i++)
		{
			FVector Point = Owner.ActorLocation - Owner.ActorForwardVector * SegmentLength * (i + 1);
			TrailPoints.Add(Point);
			TrailUp.Add(HeadWorldUp);

			bool bIsMetal = ((Math::IntegerDivisionTrunc(i,2) % 3) == 0);
			TSubclassOf<USummitWyrmTailSegmentComponent> SegmentClass = bIsMetal ? MetalSegmentClass : CrystalSegmentClass;
			auto Segment = Cast<USummitWyrmTailSegmentComponent>(Owner.CreateComponent(SegmentClass));
			Segment.bIsMetal = bIsMetal;
			Segment.WorldLocation = Point;
			Segment.WorldRotation = FRotator::MakeFromXZ(Owner.ActorForwardVector, HeadWorldUp);
			float Scale = GetGirthAtFraction(float(i) / Settings.NumSegments);
			Segment.RelativeScale3D *= FVector(1.0, Scale * ((i % 2) == 0 ? 1.0 : -1.0), Scale) * Settings.TailScale;
			TailSegments.Add(Segment);
		}

		DamageReactionOffsets.Reserve(TrailPoints.Num());
		DamageReactionOffsetTargetsLocal.Reserve(TrailPoints.Num());
		LocationOffsetLerpParams.Reserve(TrailPoints.Num());

		for (int i = 0; i < TrailPoints.Num(); i++)
		{
			DamageReactionOffsetTargetsLocal.Add(FVector::ZeroVector);
			DamageReactionOffsets.Add(FHazeAcceleratedVector());
			float LerpDuration = Settings.HurtReactionSegmentReattachDuration;
			LocationOffsetLerpParams.Add(FWyrmSegmentLocationOffsetLerp(FHazeAcceleratedVector(), LerpDuration));
		}
	}

	float GetGirthAtFraction(float Fraction)
	{
		// Widen until LargestGirthFraction, then taper off
		float Girth = 1.0;
		if (Fraction < Settings.WidestFraction)
			Girth = Math::EaseInOut(1.0, Settings.MaxGirth, Math::Min(Fraction, Settings.WidestFraction) / Settings.WidestFraction, 2.0);
		else
			Girth = Math::EaseIn(Settings.MaxGirth, Settings.TailGirth, Math::Max(Fraction - Settings.WidestFraction, 0.0) / (1.0 - Settings.WidestFraction), 2.0);
		return Girth;
	}

	
	void UpdateTail(float DeltaTime)
	{
		int LastIndex = TrailPoints.Num() - 1;
		float SegmentLength = GetSegmentLenght();

		if (!Owner.ActorLocation.IsWithinDist(TrailPoints[1], SegmentLength))
		{
			TrailPoints.RemoveAt(LastIndex);
			TrailPoints.Insert(TrailPoints[0], 1);

			TrailUp.RemoveAt(LastIndex);
			TrailUp.Insert(TrailUp[0], 1);
		}

		TrailPoints[0] = Owner.ActorLocation;
		TrailUp[0] = HeadWorldUp;

		float Distance = (TrailPoints[0] - TrailPoints[1]).Size();
		FVector Direction = (TrailPoints[LastIndex - 1] - TrailPoints[LastIndex]).GetSafeNormal();
		TrailPoints[LastIndex] = TrailPoints[LastIndex - 1] - Direction * (SegmentLength - Distance);

		FHazeRuntimeSpline TailSpline;
		TailSpline.Points = TrailPoints;

		UpdateTargetOffsets(TailSpline, DeltaTime);

		UpdateTailSegmentLocations(TailSpline, DeltaTime);			
	}

	// Handle updating Locations and also Lerping for reattaching split segments.
	void UpdateTailSegmentLocations(FHazeRuntimeSpline TailSpline, const float DeltaTime)
	{
		const float Distance = (TrailPoints[0] - TrailPoints[1]).Size();
		const float SegmentLength = GetSegmentLenght();
		const float Alpha = Distance / SegmentLength;

		TArray<FVector> SplineLocations;
		TArray<FVector> SplineDirections;
		TailSpline.GetLocations(SplineLocations, TrailPoints.Num());
		TailSpline.GetDirections(SplineDirections, TrailPoints.Num());

		int CurrentIndexOffset = 0;
		for (int i = 0; i < Settings.NumSegments; i++)
		{
			if (TailSegments[i].IsDisabled())
			{
				CurrentIndexOffset++;
				continue;
			}

			FVector SegmentUp = TrailUp[i + 1].SlerpTowards(TrailUp[i], Alpha);
			const int Idx = Math::Max(i - CurrentIndexOffset, 0);
			TailSegments[i].WorldRotation = FRotator::MakeFromXZ(-SplineDirections[Idx + 1], SegmentUp);

			if (CurrentIndexOffset == 0)
			{
				TailSegments[i].WorldLocation = SplineLocations[Idx + 1] + TailSegments[i].WorldRotation.UpVector * SegmentHeightOffset;				
				LocationOffsetLerpParams[i].Target.SnapTo(TailSegments[i].WorldLocation);
			}
			else
			{
				// Update targeted index, reset lerp timer
				if (CurrentIndexOffset != LocationOffsetLerpParams[i].CurrentIndexOffset)
				{
					LocationOffsetLerpParams[i].RemainingDuration = Settings.HurtReactionSegmentReattachDuration;
					LocationOffsetLerpParams[i].CurrentIndexOffset = CurrentIndexOffset;
				}

				FVector TargetLocation = SplineLocations[Idx + 1] + TailSegments[i].WorldRotation.UpVector * SegmentHeightOffset;				
				FHazeAcceleratedVector& TargetParam = LocationOffsetLerpParams[i].Target;
				TailSegments[i].WorldLocation = TargetParam.AccelerateTo(TargetLocation, LocationOffsetLerpParams[i].RemainingDuration, DeltaTime);
				LocationOffsetLerpParams[i].RemainingDuration -= DeltaTime;
			}

		}

	}

	// Reset trail behind head
	void ResetTail(FVector ForwardVector, FVector UpVector)
	{
		for (int i = 0; i < Settings.NumSegments; i++)
		{
			TrailPoints[i] = Owner.ActorLocation - Owner.ActorForwardVector * GetSegmentLenght() * i;
			TrailUp[i] = HeadWorldUp;
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

	// Damage reaction target offsets
	void UpdateTargetOffsets(FHazeRuntimeSpline& TailSpline, float DeltaTime)
	{
		if (bIsRunningDamageReaction)
		{
			if (DamageReactionTimer > 0.0)
			{
				for (int i = 0; i < TailSpline.Points.Num(); i++)
				{	
					// A cross-sectional plane intersecting a tangent on the spline
					FVector Tangent = TailSpline.GetTangent( float(i) / float(TailSpline.Points.Num())).GetSafeNormal();
					FVector NonParallelVector = FVector::UpVector;
					if (Tangent.DotProduct(FVector::UpVector) > 1.0 - KINDA_SMALL_NUMBER)
					{
						NonParallelVector = FVector::RightVector;
					}
					FVector PlaneVectorX = Tangent.CrossProduct(NonParallelVector);
					FVector PlaneVectorY = Tangent.CrossProduct(PlaneVectorX);
					
					FVector LocalOffset = DamageReactionOffsetTargetsLocal[i];


					FVector WorldOffset = FVector::ZeroVector;
					WorldOffset.X = LocalOffset.DotProduct(Tangent);
					WorldOffset.Y = LocalOffset.DotProduct(PlaneVectorX);
					WorldOffset.Z = LocalOffset.DotProduct(PlaneVectorY);

					DamageReactionOffsets[i].SpringTo(WorldOffset,  2500.0, 0.01, DeltaTime);
					//DamageReactionOffsets[i].AccelerateTo(WorldOffset, 0.5, DeltaTime);
					TailSpline.OffsetPoint(DamageReactionOffsets[i].Value, i);
				}

				// Shift wave towards tail end
				DamageReactionOffsetTargetsLocal.Insert(FVector::ZeroVector, 0);
				DamageReactionOffsetTargetsLocal.RemoveAt(TailSpline.Points.Num()-1);

			}
			else
			{
				bIsRunningDamageReaction = false;
			}
			DamageReactionTimer -= DeltaTime;
		}
		else
		{
			for (int i = 0; i < TailSpline.Points.Num(); i++)
			{
				//DamageReactionOffsets[i].SpringTo(FVector::ZeroVector,  0.0, 0.01, DeltaTime);
				DamageReactionOffsets[i].AccelerateTo(FVector::ZeroVector,  0.2, DeltaTime);
				TailSpline.OffsetPoint(DamageReactionOffsets[i].Value, i);
			}
		}
	}

	UFUNCTION(DevFunction)
	void DEV_OnSegmentDestroyed()
	{
		OnSegmentDestroyed(2.0);
	}

	void OnSegmentDestroyed(float ReactionDuration)
	{		
		if (!bIsRunningDamageReaction)
		{
			bIsRunningDamageReaction = true;
			DamageReactionTimer = ReactionDuration;

			GenerateDamageReactionOffsetTargetsLocal();
		}
	}

	private void GenerateDamageReactionOffsetTargetsLocal()
	{
			FVector2D PointOnCircle = Math::GetRandomPointOnCircle() * 1.0;
			float AxisOffset = 500.0;
			int j = 0;
			for (int i = 0; i < TrailPoints.Num(); i++)
			{
				// Reset old values
				DamageReactionOffsetTargetsLocal[i] = FVector::ZeroVector;

				// Experimenting with just activating parts of the curve
				if (i > TrailPoints.Num() - 20)
					continue;

				FVector OffsetTarget(0.0, AxisOffset * Math::Sin( float(i) * 12.0 ), AxisOffset * Math::Cos( float(i) * 12.0 ));
				DamageReactionOffsetTargetsLocal[i] = OffsetTarget;

			}
	}

	void OnEndHurtReaction()
	{
		bIsRunningDamageReaction = false;
		DamageReactionTimer = 0.0;
	}


	
	UFUNCTION(DevFunction)
	void DEV_DestroyNextSegment()
	{
		for (int i = 0; i < Settings.NumSegments; i++)
		{
			auto Segment = TailSegments[i];
			if (Segment.bIsDisabled)
				continue;

			Segment.TakeDamage(1.0);

			if (Segment.bIsMetal)
			{
				auto MetalSegmentSequence = GetSegmentSequence(Segment);
				for (auto MetalSegment : MetalSegmentSequence)
				{
					MetalSegment.TriggerDestroyedEffect();
				}
			}
			else
			{
					Segment.TriggerDestroyedEffect();
			}


			OnSegmentDestroyed(Settings.HurtReactionDuration);
			break;
		}
	}

	// Only returns Enabled segments
	TArray<USummitWyrmTailSegmentComponent> GetSegmentSequence(USummitWyrmTailSegmentComponent Segment)
	{
		if (Segment.bIsDisabled)		
			return TArray<USummitWyrmTailSegmentComponent>();

		TArray<USummitWyrmTailSegmentComponent> ReturnSegments();		
		ReturnSegments.Reserve(Math::FloorToInt(Settings.NumSegments * 0.5));
		ReturnSegments.Add(Segment); // Segment itself is part of the sequence.
		
		int SegmentIndex = -1;
		for (int i = 0; i < Settings.NumSegments; i++)
		{
			if (Segment == TailSegments[i])
			{
				SegmentIndex = i;
				break;
			}
		}

		// Not found
		if (SegmentIndex < 0)
			return ReturnSegments;	
			
		// Check left
		if (SegmentIndex > 0)
		{
			for (int i = SegmentIndex - 1; i >= 0; i--)
			{			
				 if (TailSegments[i].bIsDisabled)
				 	continue;
				
				if (TailSegments[i].bIsMetal != Segment.bIsMetal)
					break;
				
				ReturnSegments.Add(TailSegments[i]);
			}
		}

		// Check right
		if (SegmentIndex < Settings.NumSegments)
		{
			for (int i = SegmentIndex + 1; i < Settings.NumSegments; i++)
			{
				if (TailSegments[i].bIsDisabled)
					continue;
				
				if (TailSegments[i].bIsMetal != Segment.bIsMetal)
					break;
				
				ReturnSegments.Add(TailSegments[i]);
			}			
		}
		
		return ReturnSegments;
	}

	// Currently biased towards getting prev segment.	
	USummitWyrmTailSegmentComponent GetNearestMetalNeighbour(USummitWyrmTailSegmentComponent Segment, int Steps = 1)
	{
		for (int i = 0; i < Settings.NumSegments; i++)
		{
			if (TailSegments[i] == Segment)
			{
				for (int j = 1; j <= Steps; j++)
				{
					const int Prev = i - j;
					if (Prev >= 0 && TailSegments[Prev].bIsMetal && !TailSegments[Prev].bIsDisabled)
						return TailSegments[Prev];
					const int Next = i + j;
					if (Next < Settings.NumSegments && TailSegments[Next].bIsMetal && !TailSegments[Next].bIsDisabled)
						return TailSegments[Next];
				}
			}
		}
		
		return nullptr;
	}
	
}
