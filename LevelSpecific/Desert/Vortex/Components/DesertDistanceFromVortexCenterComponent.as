struct FDesertDistanceFromVortexCenterEntry
{
	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0", ClampMax = "360", UIMin = "0", UIMax = "360"))
	float YawAngle = 0;

	UPROPERTY(EditAnywhere)
	float DistanceFromCenter = 0;

	int opCmp(FDesertDistanceFromVortexCenterEntry Other) const
	{
		if(YawAngle > Other.YawAngle)
			return 1;

		if(YawAngle < Other.YawAngle)
			return -1;

		return 0;
	}
};

class UDesertDistanceFromVortexCenterComponent : UActorComponent
{
	access Internal = private, UDesertDistanceFromVortexCenterComponentVisualizer;

	UPROPERTY(VisibleInstanceOnly, Category = "Distance From Vortex Center")
	ADesertVortexSpinningCenter SpinningCenter;

	UPROPERTY(EditInstanceOnly, Category = "Distance From Vortex Center")
	TArray<FDesertDistanceFromVortexCenterEntry> Distances;

	FVector InitialRelativeHorizontalDirection;
	float InitialYawOffset = 0;

#if EDITOR
	int PreviousDistances = 0;

	UFUNCTION(CallInEditor, Category = "Distance From Vortex Center")
	private void SetSpinningCenterFromAttachParentActor()
	{
		SpinningCenter = Cast<ADesertVortexSpinningCenter>(Owner.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		SetSpinningCenterFromAttachParentActor();

		if(SpinningCenter != nullptr)
		{
			if(Distances.Num() > PreviousDistances)
			{
				auto& NewDistance = Distances[Distances.Num() - 1];
				NewDistance.DistanceFromCenter = SpinningCenter.ActorLocation.Dist2D(Owner.ActorLocation);

				if(PreviousDistances >= 1)
				{
					auto SortedDistances = Distances;
					SortedDistances.Sort();
					NewDistance.YawAngle = Math::Clamp(SortedDistances[SortedDistances.Num() - 2].YawAngle + 1, 0, 359.999);
				}
				else
				{
					NewDistance.YawAngle = GetYawOffset();
				}
			}
		}


		PreviousDistances = Distances.Num();
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	void Initialize()
	{
		Distances.Sort();
		
		InitialRelativeHorizontalDirection = Owner.ActorRelativeLocation;
		InitialRelativeHorizontalDirection.Z = 0;
		InitialRelativeHorizontalDirection.Normalize();

		InitialYawOffset = FVector::ForwardVector.GetAngleDegreesTo(InitialRelativeHorizontalDirection);
		if(InitialRelativeHorizontalDirection.Y < 0)
			InitialYawOffset = 360 - InitialYawOffset;
	}

	FVector CalculateLocation() const
	{
		float YawAngle = GetCurrentYawAngle();
		float Distance = GetDistanceFromYawAngle(YawAngle);
		return Owner.AttachParentActor.ActorTransform.TransformPositionNoScale(InitialRelativeHorizontalDirection * Distance);
	}

	float GetYawOffset() const
	{
		return GetYawOffsetRelative(Owner.ActorRelativeLocation);
	}

	access:Internal
	float GetYawOffsetRelative(FVector RelativeLocation) const
	{
		FVector RelativeHorizontalDirection = RelativeLocation;
		RelativeHorizontalDirection.Z = 0;
		RelativeHorizontalDirection.Normalize();

		float YawOffset = FVector::ForwardVector.GetAngleDegreesTo(RelativeHorizontalDirection);
		if(RelativeHorizontalDirection.Y < 0)
			YawOffset = 360 - YawOffset;

		return YawOffset;
	}

	access:Internal
	float GetYawOffsetWorld(FVector WorldLocation) const
	{
		const FVector RelativeLocation = SpinningCenter.ActorTransform.InverseTransformPositionNoScale(WorldLocation);
		return GetYawOffsetRelative(RelativeLocation);
	}

	access:Internal
	float GetCurrentYawAngle() const
	{
		float YawAngle = SpinningCenter.ActorRotation.Yaw;
		YawAngle = Math::GetMappedRangeValueClamped(FVector2D(-180, 180), FVector2D(0, 360), YawAngle);
		YawAngle -= 180;
		YawAngle += InitialYawOffset;
		YawAngle = Math::Wrap(YawAngle, 0, 360);
		return YawAngle;
	}

	access:Internal
	float GetDistanceFromYawAngle(float YawAngle) const
	{
		check(YawAngle >= 0 && YawAngle <= 360);

		FDesertDistanceFromVortexCenterEntry Previous;
		FDesertDistanceFromVortexCenterEntry Next;
		float Alpha;
		GetDistancesAndAlpha(YawAngle, Previous, Next, Alpha);
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);
		return Math::Lerp(Previous.DistanceFromCenter, Next.DistanceFromCenter, Alpha);
	}

	// @return False if only one or no components are valid, thus not making interpolation possible
	access:Internal
	bool GetDistancesAndAlpha(float YawAngle, FDesertDistanceFromVortexCenterEntry&out OutPrevious, FDesertDistanceFromVortexCenterEntry&out OutNext, float&out OutAlpha) const
	{
		auto SortedDistances = Distances;
		SortedDistances.Sort();

		if(Distances.Num() == 0)
		{
			OutPrevious = FDesertDistanceFromVortexCenterEntry();
			OutNext = FDesertDistanceFromVortexCenterEntry();
			OutAlpha = 0;
			return false;
		}

		if(Distances.Num() == 1)
		{
			OutPrevious = FDesertDistanceFromVortexCenterEntry();
			OutNext = SortedDistances[0];
			OutAlpha = 1;
			return false;
		}

		if(YawAngle <= 0 || YawAngle < SortedDistances[0].YawAngle)
		{
			// If before first distance, go from previous to first
			OutPrevious = SortedDistances[SortedDistances.Num() - 1];
			OutNext = SortedDistances[0];
			OutAlpha = Math::NormalizeToRange(YawAngle, OutPrevious.YawAngle - 360, OutNext.YawAngle);
			check(OutAlpha >= 0 && OutAlpha <= 1);
			return true;
		}

		if(YawAngle >= 360 || YawAngle > SortedDistances.Last().YawAngle)
		{
			OutPrevious = SortedDistances[SortedDistances.Num() - 1];
			OutNext = SortedDistances[0];
			OutAlpha = Math::NormalizeToRange(YawAngle, OutPrevious.YawAngle, OutNext.YawAngle + 360);
			check(OutAlpha >= 0 && OutAlpha <= 1);
			return true;
		}

		// FB TODO: Faster search
		for(int i = 1; i < SortedDistances.Num(); i++)
		{
			FDesertDistanceFromVortexCenterEntry Previous = SortedDistances[i - 1];
			if(Previous.YawAngle > YawAngle)
				continue;

			FDesertDistanceFromVortexCenterEntry Next = SortedDistances[i];
			if(Next.YawAngle < YawAngle)
				continue;
			
			OutPrevious = Previous;
			OutNext = Next;

			OutAlpha = Math::NormalizeToRange(YawAngle, Previous.YawAngle, Next.YawAngle);
			return true;
		}

		check(false);
		return false;
	}

	FVector GetLocationFromYawAngle(float YawAngle) const
	{
		check(YawAngle >= 0 && YawAngle <= 360);

		if(SpinningCenter == nullptr)
			return FVector::ZeroVector;

		float Distance = GetDistanceFromYawAngle(YawAngle);

		return SpinningCenter.ActorLocation + FQuat(FVector::UpVector, Math::DegreesToRadians(YawAngle)).RotateVector(FVector::ForwardVector * Distance);
	}
};

#if EDITOR
class UDesertDistanceFromVortexCenterComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDesertDistanceFromVortexCenterComponent;

	int SelectedDistance = -1;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto DistanceComp = Cast<UDesertDistanceFromVortexCenterComponent>(Component);
		if(DistanceComp == nullptr)
			return;

		if(DistanceComp.SpinningCenter == nullptr)
			return;

		if(Game::Mio != nullptr)
		{
			FVector ActorLocation = Desert::GetLandscapeLocation(DistanceComp.Owner.ActorLocation);
			float YawAngle = DistanceComp.GetCurrentYawAngle();
			DrawWireSphere(ActorLocation, 500, FLinearColor::Red, 3, 12, true);
			DrawWorldString(f"Distance Actor:\nYawAngle:{Math::RoundToInt(YawAngle)}\nDistanceFromCenter: {Math::RoundToInt(DistanceComp.GetDistanceFromYawAngle(YawAngle))}", ActorLocation, FLinearColor::Red, 1.2, -1, false, false);
		}

		for(int i = 0; i < DistanceComp.Distances.Num(); i++)
		{
			auto DistanceEntry = DistanceComp.Distances[i];
			FVector CurrentLocation = DistanceComp.GetLocationFromYawAngle(DistanceEntry.YawAngle);
			
			FName DistanceProxy = n"Distance";
			DistanceProxy.SetNumber(i);
			SetHitProxy(DistanceProxy, EVisualizerCursor::GrabHand);
			FLinearColor Color = SelectedDistance == i ? FLinearColor::White : FLinearColor::Blue;
			DrawWireSphere(CurrentLocation, 200, Color, 5, 12, true);
			ClearHitProxy();
			
			DrawWorldString(f"Distance Entry {i}:\nYawAngle:{Math::RoundToInt(DistanceEntry.YawAngle)}\nDistanceFromCenter: {Math::RoundToInt(DistanceEntry.DistanceFromCenter)}", CurrentLocation, FLinearColor::White, 1.2, -1, false, false);
		}

		float Time = 0;
		const float Duration = 5;
		float BoundsTime = Time::GameTimeSeconds % Duration;
		bool bHasDrawnBounds = false;
		FHazeRuntimeSpline Spline = ConstructRuntimeSplineFromDistances(DistanceComp, 50);

		for(int i = 0; i < 50; i++)
		{
			float Alpha = i / float(50);
			float Angle = Alpha * 360;
			FVector Location = DistanceComp.GetLocationFromYawAngle(Angle);
			Location.Z = Desert::GetLandscapeHeightByLevel(Location, ESandSharkLandscapeLevel::Upper);
			DrawPoint(Location, FLinearColor::Red, 20);
		}

		Spline.VisualizeSplineSimple(this, 150, 20, FLinearColor::White);

		while(Time < Duration)
		{
			float Alpha = Time / Duration;
			float Angle = Alpha * 360;

			Time += 0.0333;
			if(!bHasDrawnBounds && BoundsTime < Time)
			{
				bHasDrawnBounds = true;

				FTransform Transform = GetActorTransformFromYawAngleOnSpline(Spline, Angle);

				FVector Origin;
				FVector Extents;
				DistanceComp.Owner.GetActorLocalBounds(true, Origin, Extents, true);

				DrawWireBox(Transform.Location, Extents * DistanceComp.Owner.ActorScale3D, Transform.Rotation, FLinearColor::LucBlue, 2, true);
			}
		}
	}

	FHazeRuntimeSpline ConstructRuntimeSplineFromDistances(UDesertDistanceFromVortexCenterComponent DistanceComp, int Resolution) const
	{
		FHazeRuntimeSpline Spline;
		Spline.SetLooping(true);

		for(int i = 0; i < Resolution; i++)
		{
			float Alpha = i / float(Resolution);
			float Angle = Alpha * 360;
			FVector Location = DistanceComp.GetLocationFromYawAngle(Angle);
			Location.Z = Desert::GetLandscapeHeightByLevel(Location, ESandSharkLandscapeLevel::Upper);
			Spline.AddPoint(Location);
		}

		return Spline;
	}

	FVector GetLocationOnSplineFromYawAngle(FHazeRuntimeSpline Spline, float YawAngle) const
	{
		float Alpha = YawAngle / 360;
		return Spline.GetLocation(Alpha);
	}


	FTransform GetActorTransformFromYawAngleOnSpline(FHazeRuntimeSpline Spline, float YawAngle) const
	{
		float Alpha = YawAngle / 360;
		FVector Location = Spline.GetLocation(Alpha);
		FQuat Rotation = Spline.GetQuat(Alpha);
		return FTransform(Rotation, Location);
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key,
	                         EInputEvent Event)
	{
		if(HitProxy.IsEqual(n"Distance", bCompareNumber = false))
		{
			if(Event == EInputEvent::IE_Released)
			{
				SelectedDistance = HitProxy.GetNumber();
			}

			return true;
		}

		SelectedDistance = -1;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		if(SelectedDistance < 0)
			return false;

		auto DistanceComp = Cast<UDesertDistanceFromVortexCenterComponent>(EditingComponent);
		if(DistanceComp == nullptr)
			return false;

		if(!DistanceComp.Distances.IsValidIndex(SelectedDistance))
			return false;

		auto& Distance = DistanceComp.Distances[SelectedDistance];
		OutLocation = DistanceComp.GetLocationFromYawAngle(Distance.YawAngle);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if(WidgetMode != EVisualizerWidgetMode::Translate)
			return false;

		if(CoordSystem != EVisualizerCoordinateSystem::World)
			return false;

		if(SelectedDistance < 0)
			return false;

		auto DistanceComp = Cast<UDesertDistanceFromVortexCenterComponent>(EditingComponent);
		if(DistanceComp == nullptr)
			return false;

		if(!DistanceComp.Distances.IsValidIndex(SelectedDistance))
			return false;

		auto& Distance = DistanceComp.Distances[SelectedDistance];
		FVector Location = DistanceComp.GetLocationFromYawAngle(Distance.YawAngle);
		FVector ToLocationFromCenter = (Location - DistanceComp.SpinningCenter.ActorLocation).VectorPlaneProject(FVector::UpVector);
		FRotator Rotation = FRotator::MakeFromYZ(-ToLocationFromCenter, FVector::UpVector);

		FRotator RelativeRotation = DistanceComp.Owner.ActorTransform.InverseTransformRotation(Rotation);
		OutTransform = FTransform(RelativeRotation);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if(SelectedDistance < 0)
			return false;

		auto DistanceComp = Cast<UDesertDistanceFromVortexCenterComponent>(EditingComponent);
		if(DistanceComp == nullptr)
			return false;

		if(!DistanceComp.Distances.IsValidIndex(SelectedDistance))
			return false;

		auto& Distance = DistanceComp.Distances[SelectedDistance];
		FVector Location = DistanceComp.GetLocationFromYawAngle(Distance.YawAngle);
		Location += DeltaTranslate.VectorPlaneProject(FVector::UpVector);
		Distance.YawAngle = DistanceComp.GetYawOffsetWorld(Location);

		Distance.DistanceFromCenter = DistanceComp.SpinningCenter.ActorLocation.Dist2D(Location);
		DeltaTranslate = FVector::ZeroVector;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		SelectedDistance = -1;
	}
};
#endif