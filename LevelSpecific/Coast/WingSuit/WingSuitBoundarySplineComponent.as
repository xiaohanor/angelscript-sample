class UWingSuitBoundarySplineContainerComponent : UActorComponent
{
	TArray<UWingSuitBoundarySplineComponent> BoundarySplineComponents;
}

enum EWingSuitBoundarySplineAngleOffsetMode
{
	Clamp,
	EqualOffset
}

struct FWingSuitBoundaryVolumeDisableInfo
{
	TArray<FInstigator> DisableInstigators;

	bool IsDisabled() const
	{
		return DisableInstigators.Num() > 0;
	}
}

UCLASS(HideCategories = "Physics Collision Lighting Rendering Navigation Debug Activation Cooking Tags Lod TextureStreaming")
class UWingSuitBoundarySplineComponent : UActorComponent
{
	/* When at the top of the volume, this max angle will be used instead so you can't steer upwards. */
	UPROPERTY(EditAnywhere)
	float PitchUpMinMaxAngle = -10.0;

	UPROPERTY(EditAnywhere)
	float BoundaryHeight = 500.0;

	UPROPERTY(EditAnywhere)
	float BoundaryHeightOffset = 0.0;

	UPROPERTY(EditAnywhere)
	float BoundaryWidthExtents = 250.0;

	UPROPERTY(EditAnywhere)
	bool bEnableHorizontalSteerback = true;

	/* When this percentage away from the center the wingsuit will start steering back towards the spline. If this is 1 or above it will not apply any steerback regardless of horizontal position in boundary */
	UPROPERTY(EditAnywhere)
	float BoundaryWidthSteerbackPercentage = 0.5;

	UPROPERTY(EditAnywhere)
	EWingSuitBoundarySplineAngleOffsetMode AngleOffsetMode = EWingSuitBoundarySplineAngleOffsetMode::EqualOffset;

	UPROPERTY(EditAnywhere)
	bool bOffsetDefaultAngleAlso = true;

	UPROPERTY(EditAnywhere)
	bool bOffsetMinAngleAlso = true;

	UPROPERTY(EditAnywhere, Category = "Visualizer")
	FVector AngleVisualizerRelativeLocation;

	UPROPERTY(EditAnywhere, Category = "Visualizer")
	float TestBasePitchUpMaxAngle = 20.0;

	private TPerPlayer<FWingSuitBoundaryVolumeDisableInfo> DisableInstigators;
	private FTransform Internal_ClosestSplineTransform;
	private bool bGottenClosestSplineTransform = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UWingSuitBoundarySplineContainerComponent::GetOrCreate(Game::Mio).BoundarySplineComponents.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UWingSuitBoundarySplineContainerComponent::GetOrCreate(Game::Mio).BoundarySplineComponents.Remove(this);
	}

	void DisableTrigger(FInstigator Instigator)
	{
		DisableInstigators[0].DisableInstigators.AddUnique(Instigator);
		DisableInstigators[1].DisableInstigators.AddUnique(Instigator);
	}

	void EnableTrigger(FInstigator Instigator)
	{
		DisableInstigators[0].DisableInstigators.RemoveSingleSwap(Instigator);
		DisableInstigators[1].DisableInstigators.RemoveSingleSwap(Instigator);
	}

	void DisableTriggerForPlayer(FInstigator Instigator, AHazePlayerCharacter Player)
	{
		DisableInstigators[Player].DisableInstigators.AddUnique(Instigator);
	}

	void EnableTriggerForPlayer(FInstigator Instigator, AHazePlayerCharacter Player)
	{
		DisableInstigators[Player].DisableInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsDisabledForPlayer(AHazePlayerCharacter Player) const
	{
		return DisableInstigators[Player].IsDisabled();
	}

	bool IsLocationWithinVolume(FVector Location) const
	{
		FTransform ClosestTransform = Spline::GetGameplaySpline(Owner).GetClosestSplineWorldTransformToWorldLocation(Location);
		FVector LocalLocation = ClosestTransform.InverseTransformPosition(Location);

		return SplineTransformLocalBox.IsInside(LocalLocation);
	}

	bool IsLocationWithinSplineBounds(FVector Location) const
	{
		UHazeSplineComponent Spline = Spline::GetGameplaySpline(Owner);
		float SplineDist = Spline.GetClosestSplineDistanceToWorldLocation(Location);
		if(Math::IsNearlyEqual(SplineDist, 0.0) || Math::IsNearlyEqual(SplineDist, Spline.SplineLength))
			return false;

		return true;
	}

	FVector GetClosestLocationToVolume(FVector Location) const
	{
		FTransform ClosestTransform = Spline::GetGameplaySpline(Owner).GetClosestSplineWorldTransformToWorldLocation(Location);
		FVector LocalLocation = ClosestTransform.InverseTransformPosition(Location);

		FVector ClosestLocalPoint = SplineTransformLocalBox.GetClosestPointTo(LocalLocation);
		FVector ClosestPoint = ClosestTransform.TransformPosition(ClosestLocalPoint);
		return ClosestPoint;
	}

	// Get alpha for location in volume. X is horizontal and Y is vertical. X is 0 at center, and 1 at the edge
	FVector2D GetVolumeAlphaForLocation(FVector Location) const
	{
		FTransform ClosestTransform = Spline::GetGameplaySpline(Owner).GetClosestSplineWorldTransformToWorldLocation(Location);
		FVector LocalLocation = ClosestTransform.InverseTransformPosition(Location);

		FVector ClosestLocalPoint = SplineTransformLocalBox.GetClosestPointTo(LocalLocation);
		FVector PointLocalToCenterOfBox = ClosestLocalPoint - SplineTransformLocalBox.Center;
		FVector SignedAlpha = PointLocalToCenterOfBox / SplineTransformLocalBox.Extent;
		float Horizontal = Math::Saturate(Math::NormalizeToRange(Math::Abs(SignedAlpha.Y), BoundaryWidthSteerbackPercentage, 1.0));
		Horizontal = !bEnableHorizontalSteerback || BoundaryWidthSteerbackPercentage >= 1.0 || BoundaryWidthSteerbackPercentage < 0.0 ? 0.0 : Horizontal;
		return FVector2D(Horizontal, Math::NormalizeToRange(SignedAlpha.Z, -1.0, 1.0));
	}

	FBox GetSplineTransformLocalBox() const property
	{
		return FBox::BuildAABB(FVector::UpVector * (BoundaryHeightOffset + BoundaryHeight * 0.5), FVector(0.0, BoundaryWidthExtents, BoundaryHeight * 0.5));
	}
}

#if EDITOR
class UWingSuitBoundarySplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UWingSuitBoundarySplineComponent;

	bool bIsAngleVisualizerSelected = false;

	const float VolumeLineThickness = 50.0;
	const FLinearColor VolumeColor = FLinearColor::LucBlue;
	const FLinearColor HorizontalPercentageLineColor = FLinearColor::Red;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Boundary = Cast<UWingSuitBoundarySplineComponent>(Component);

		const float LineLength = 5000.0;
		const float LineThickness = 50.0;
		FVector WorldLocationOfAngleVisualizer = Boundary.Owner.ActorTransform.TransformPositionNoScale(Boundary.AngleVisualizerRelativeLocation);
		UHazeSplineComponent Spline = Spline::GetGameplaySpline(Boundary.Owner);
		FTransform ClosestTransform = Spline.GetClosestSplineWorldTransformToWorldLocation(WorldLocationOfAngleVisualizer);
		FVector HorizontalForward = ClosestTransform.Rotation.ForwardVector.VectorPlaneProject(FVector::UpVector);

		SetHitProxy(n"AngleVisualizer");
		DrawWireDiamond(WorldLocationOfAngleVisualizer, FRotator::MakeFromXZ(HorizontalForward, FVector::UpVector), 500.0, FLinearColor::LucBlue, LineThickness);
		ClearHitProxy();

		FVector2D VolumeAlpha = Boundary.GetVolumeAlphaForLocation(WorldLocationOfAngleVisualizer);
		float CurrentAngle = Math::Lerp(Boundary.TestBasePitchUpMaxAngle, Boundary.PitchUpMinMaxAngle, VolumeAlpha.Y);

		DrawLine(WorldLocationOfAngleVisualizer, WorldLocationOfAngleVisualizer + FRotator(Boundary.TestBasePitchUpMaxAngle, 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, FLinearColor::Red, LineThickness);
		DrawLine(WorldLocationOfAngleVisualizer, WorldLocationOfAngleVisualizer + FRotator(Boundary.PitchUpMinMaxAngle, 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, FLinearColor::Green, LineThickness);
		DrawLine(WorldLocationOfAngleVisualizer, WorldLocationOfAngleVisualizer + FRotator(CurrentAngle, 0.0, 0.0).RotateVector(HorizontalForward) * LineLength, FLinearColor::Yellow, LineThickness);

		// Draw volume
		const float StepDistance = 5000.0;

		float CurrentDist = 0.0;
		FTransform CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentDist);
		FVector Point1, Point2, Point3, Point4;
		GetFourPoints(CurrentTransform, Boundary, Point1, Point2, Point3, Point4);
		DrawSquare(Point1, Point2, Point3, Point4);

		FVector HorizontalPctPoint1, HorizontalPctPoint2;
		GetHorizontalPercentagePoints(CurrentTransform, Boundary, HorizontalPctPoint1, HorizontalPctPoint2);

		while(CurrentDist < Spline.SplineLength)
		{
			bool bFinal = false;
			CurrentDist += StepDistance;
			if(CurrentDist >= Spline.SplineLength)
			{
				CurrentDist = Spline.SplineLength;
				bFinal = true;
			}
			CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentDist);
			FVector Temp1, Temp2, Temp3, Temp4;
			FVector TempHorizontalPct1, TempHorizontalPct2;

			GetFourPoints(CurrentTransform, Boundary, Temp1, Temp2, Temp3, Temp4);
			GetHorizontalPercentagePoints(CurrentTransform, Boundary, TempHorizontalPct1, TempHorizontalPct2);

			DrawLine(Point1, Temp1, VolumeColor, VolumeLineThickness);
			DrawLine(Point2, Temp2, VolumeColor, VolumeLineThickness);
			DrawLine(Point3, Temp3, VolumeColor, VolumeLineThickness);
			DrawLine(Point4, Temp4, VolumeColor, VolumeLineThickness);

			if(Boundary.bEnableHorizontalSteerback && Boundary.BoundaryWidthSteerbackPercentage < 1.0 && Boundary.BoundaryWidthSteerbackPercentage >= 0.0)
			{
				DrawLine(HorizontalPctPoint1, TempHorizontalPct1, HorizontalPercentageLineColor, VolumeLineThickness);
				DrawLine(HorizontalPctPoint2, TempHorizontalPct2, HorizontalPercentageLineColor, VolumeLineThickness);
			}

			Point1 = Temp1;
			Point2 = Temp2;
			Point3 = Temp3;
			Point4 = Temp4;

			HorizontalPctPoint1 = TempHorizontalPct1;
			HorizontalPctPoint2 = TempHorizontalPct2;

			if(bFinal)
				DrawSquare(Point1, Point2, Point3, Point4);
		}
	}

	void GetFourPoints(FTransform CurrentTransform, UWingSuitBoundarySplineComponent Boundary, FVector&out Point1, FVector&out Point2, FVector&out Point3, FVector&out Point4)
	{
		Point1 = CurrentTransform.TransformPosition(FVector::RightVector * Boundary.BoundaryWidthExtents + FVector::UpVector * Boundary.BoundaryHeightOffset);
		Point2 = CurrentTransform.TransformPosition(FVector::RightVector * Boundary.BoundaryWidthExtents + FVector::UpVector * (Boundary.BoundaryHeightOffset + Boundary.BoundaryHeight));
		Point3 = CurrentTransform.TransformPosition(FVector::LeftVector * Boundary.BoundaryWidthExtents + FVector::UpVector * (Boundary.BoundaryHeightOffset + Boundary.BoundaryHeight));
		Point4 = CurrentTransform.TransformPosition(FVector::LeftVector * Boundary.BoundaryWidthExtents + FVector::UpVector * Boundary.BoundaryHeightOffset);
	}

	void GetHorizontalPercentagePoints(FTransform CurrentTransform, UWingSuitBoundarySplineComponent Boundary, FVector&out HorizontalPctPoint1, FVector&out HorizontalPctPoint2)
	{
		HorizontalPctPoint1 = CurrentTransform.TransformPosition(FVector::RightVector * (Boundary.BoundaryWidthExtents * Boundary.BoundaryWidthSteerbackPercentage) + FVector::UpVector * (Boundary.BoundaryHeightOffset + Boundary.BoundaryHeight));
		HorizontalPctPoint2 = CurrentTransform.TransformPosition(FVector::LeftVector * (Boundary.BoundaryWidthExtents * Boundary.BoundaryWidthSteerbackPercentage) + FVector::UpVector * (Boundary.BoundaryHeightOffset + Boundary.BoundaryHeight));
	}

	void DrawSquare(FVector Point1, FVector Point2, FVector Point3, FVector Point4)
	{
		DrawLine(Point1, Point2, VolumeColor, VolumeLineThickness);
		DrawLine(Point2, Point3, VolumeColor, VolumeLineThickness);
		DrawLine(Point3, Point4, VolumeColor, VolumeLineThickness);
		DrawLine(Point4, Point1, VolumeColor, VolumeLineThickness);
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsAngleVisualizerSelected = false;
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if (HitProxy == n"AngleVisualizer")
		{
			bIsAngleVisualizerSelected = !bIsAngleVisualizerSelected;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Boundary = Cast<UWingSuitBoundarySplineComponent>(EditingComponent);

		if (bIsAngleVisualizerSelected)
		{
			OutLocation = Boundary.Owner.ActorTransform.TransformPositionNoScale(Boundary.AngleVisualizerRelativeLocation);
			return true;
		}

		return false;
	}

	// Used by the editor to determine what the coordinate system for the transform gizmo should be
	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if (!bIsAngleVisualizerSelected)
			return false;

		auto Boundary = Cast<UWingSuitBoundarySplineComponent>(EditingComponent);
		FVector VisualizerWorldLocation = Boundary.Owner.ActorTransform.TransformPositionNoScale(Boundary.AngleVisualizerRelativeLocation);
		FTransform ClosestTransform = Spline::GetGameplaySpline(Boundary.Owner).GetClosestSplineWorldTransformToWorldLocation(VisualizerWorldLocation);
		OutTransform = FTransform::MakeFromZX(FVector::UpVector, ClosestTransform.Rotation.ForwardVector.VectorPlaneProject(FVector::UpVector));
		return true;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if (!bIsAngleVisualizerSelected)
			return false;

		auto Boundary = Cast<UWingSuitBoundarySplineComponent>(EditingComponent);
		if (!DeltaTranslate.IsNearlyZero())
		{
			FVector LocalTranslation = Boundary.Owner.ActorTransform.InverseTransformVectorNoScale(DeltaTranslate);
			Boundary.AngleVisualizerRelativeLocation += LocalTranslation;
		}

		return true;
	}
}
#endif