struct FTundraPlayerSnowMonkeyCeilingBlockingData
{
	FTransform BlockerTransform;
	FBox BlockerLocalBounds;
	TArray<FVector> ProjectedWorldPoints;
	
	/**
	 * Array of points (in world space) representing lines, index 0 -> 1 is one line, 2 -> 3 etc.
	 * These lines intersect with the climbing shape and are on the edges of the blocking shape so that the players can safely be on these lines and climb.
	 */
	TArray<FVector> ClimbableLines;

	bool IsPointInside(FVector Point)
	{
		const bool bDebug = false;
		if(bDebug)
			Debug::DrawDebugSphere(Point, 10.0, 12, FLinearColor::Yellow, 5.0);

		bool bPointInside = true;
		for(int i = 0; i < ProjectedWorldPoints.Num(); i++)
		{
			FVector A = ProjectedWorldPoints[i];
			FVector B = ProjectedWorldPoints[Math::WrapIndex(i + 1, 0, ProjectedWorldPoints.Num())];
			FVector AToBDir = (B - A).GetSafeNormal();

			FVector CurrentLineNormal = AToBDir.CrossProduct(FVector::UpVector).GetSafeNormal();
			FVector LineMiddlePoint = (A + B) * 0.5;

			FVector LineToPoint = Point - LineMiddlePoint;
			bool bOutsidePlane = CurrentLineNormal.DotProduct(LineToPoint) < 0.0;

			if(!bDebug && bOutsidePlane)
				return false;

			if(bDebug)
			{
				if(bPointInside && bOutsidePlane)
					bPointInside = false;

				Debug::DrawDebugArrow(LineMiddlePoint, LineMiddlePoint + CurrentLineNormal * 50.0, 5.0, bOutsidePlane ? FLinearColor::Red : FLinearColor::Green, 5.0);
			}
		}

		return bPointInside;
	}

	FVector GetClosestPointOutsideBlocker(FVector Point)
	{
		const bool bDebug = false;
		if(bDebug)
			Debug::DrawDebugSphere(Point, 10.0, 12, FLinearColor::Yellow, 5.0);

		devCheck(ClimbableLines.Num() >= 2, "Need at least one line to get the closest point on one");
		FVector ClosestPoint;
		float ClosestSqrDist = MAX_flt;
		for(int i = 0; i < ClimbableLines.Num() - 1; i+=2)
		{
			FVector A = ClimbableLines[i];
			FVector B = ClimbableLines[i + 1];

			FVector CurrentClosestPoint = Math::ClosestPointOnLine(A, B, Point);
			float SqrDist = Point.DistSquared(CurrentClosestPoint);
			if(SqrDist < ClosestSqrDist)
			{
				ClosestPoint = CurrentClosestPoint;
				ClosestSqrDist = SqrDist;
			}

			if(bDebug)
				Debug::DrawDebugSphere(CurrentClosestPoint, 10.0, 12, FLinearColor::Red, 5.0);
		}

		if(bDebug)
			Debug::DrawDebugSphere(ClosestPoint, 10.0, 12, FLinearColor::Green, 5.0);

		return ClosestPoint;
	}
}

struct FTundraPlayerSnowMonkeyCeilingBlockingCacheData
{
	TOptional<uint> FrameOfCalculation;
	FTundraPlayerSnowMonkeyCeilingBlockingData BlockingData;
}

/**
 * Place this as a child of a primitive component you wish to act as a blocking component for ceiling climbs!
 */
class UTundraPlayerSnowMonkeyCeilingClimbBlockingComponent : USceneComponent
{
	UPROPERTY(EditInstanceOnly)
	TArray<AActor> CeilingsToBlock;

	UPROPERTY(EditAnywhere)
	float CapsuleMargins = 10.0;

	UPrimitiveComponent BlockingComponent;
	TMap<UTundraPlayerSnowMonkeyCeilingClimbComponent, FTundraPlayerSnowMonkeyCeilingBlockingCacheData> CachedData;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		for(int i = CeilingsToBlock.Num() - 1; i >= 0; i--)
		{
			AActor Actor = CeilingsToBlock[i];
			if(Actor == nullptr)
				continue;

			auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Actor);
			if(ClimbComp == nullptr)
			{
				CeilingsToBlock[i] = nullptr;
				PrintScaled("Select an actor with a ceiling climb component!", 5.f, FLinearColor::Red, 3.f);
			}
			else
			{
				FTundraPlayerSnowMonkeyCeilingData CeilingData = ClimbComp.GetCeilingData(true, false);

				if(CeilingData.Spline != nullptr)
					ClimbComp.GetOrCreateSplineCeilingEdgeSpline(true);
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BlockingComponent = GetBlockingComponent();
		devCheck(BlockingComponent != nullptr, "Ceiling climb blocking component attached to a component that isn't a primitive component!");

		for(int i = CeilingsToBlock.Num() - 1; i >= 0; i--)
		{
			AActor Actor = CeilingsToBlock[i];
			if(Actor == nullptr)
			{
				CeilingsToBlock.RemoveAt(i);
				continue;
			}

			auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Actor);
			devCheck(ClimbComp != nullptr, "Ceiling Climb Blocking Component had an actor with no climb comp in CeilingsToBlock");
			ClimbComp.CeilingBlockingComps.AddUnique(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(int i = CeilingsToBlock.Num() - 1; i >= 0; i--)
		{
			AActor Actor = CeilingsToBlock[i];
			if(Actor == nullptr)
				continue;

			auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Actor);
			if(ClimbComp == nullptr)
				continue;

			ClimbComp.CeilingBlockingComps.RemoveSingleSwap(this);
		}
	}

	UPrimitiveComponent GetBlockingComponent() const
	{
		return Cast<UPrimitiveComponent>(AttachParent);
	}

	FTundraPlayerSnowMonkeyCeilingBlockingData GetBlockingDataForCeiling(UTundraPlayerSnowMonkeyCeilingClimbComponent Ceiling, bool bCalledFromEditor = false)
	{
		FTundraPlayerSnowMonkeyCeilingData CeilingData = Ceiling.GetCeilingData(bCalledFromEditor, false);
		return GetBlockingDataForCeiling(CeilingData, bCalledFromEditor);
	}

	FTundraPlayerSnowMonkeyCeilingBlockingData GetBlockingDataForCeiling(FTundraPlayerSnowMonkeyCeilingData CeilingData, bool bCalledFromEditor = false)
	{
		if(ShouldCalculateDataForCeiling(CeilingData.ClimbComp))
		{
			FTundraPlayerSnowMonkeyCeilingBlockingData Data = CalculateBlockingDataForCeiling(CeilingData, bCalledFromEditor);

			if(!bCalledFromEditor)
			{
				FTundraPlayerSnowMonkeyCeilingBlockingCacheData CacheData;
				CacheData.BlockingData = Data;
				CacheData.FrameOfCalculation.Set(Time::FrameNumber);
				CachedData.Add(CeilingData.ClimbComp, CacheData);
			}

			return Data;
		}

		return CachedData[CeilingData.ClimbComp].BlockingData;
	}

	void GetWorldPointsOfBlockingSquare(TArray<FVector>&out Points) const
	{
		Points.Reset();
		FBox BlockerLocalBounds;
		FTransform BlockerTransform;
		UPrimitiveComponent Comp = GetBlockingComponent();
		GetBlockerLocalBoundsAndTransform(Comp, BlockerLocalBounds, BlockerTransform);

		FVector Extent = BlockerLocalBounds.Extent;
		Points.Add(BlockerLocalBounds.Center + FVector::ForwardVector * Extent.X + FVector::RightVector * Extent.Y);
		Points.Add(BlockerLocalBounds.Center + FVector::ForwardVector * Extent.X - FVector::RightVector * Extent.Y);
		Points.Add(BlockerLocalBounds.Center - FVector::ForwardVector * Extent.X - FVector::RightVector * Extent.Y);
		Points.Add(BlockerLocalBounds.Center - FVector::ForwardVector * Extent.X + FVector::RightVector * Extent.Y);

		for(FVector& Point : Points)
			Point = BlockerTransform.TransformPosition(Point);
	}

	void GetProjectedWorldPointsOnCeiling(FTundraPlayerSnowMonkeyCeilingData CeilingData, TArray<FVector>&out WorldPoints) const
	{
		TArray<FSplinePosition> DummySplinePositions;
		GetProjectedWorldPointsOnCeiling(CeilingData, WorldPoints, DummySplinePositions);
	}

	void GetProjectedWorldPointsOnCeiling(FTundraPlayerSnowMonkeyCeilingData CeilingData, TArray<FVector>&out WorldPoints, TArray<FSplinePosition>&out SplinePositions) const
	{
		WorldPoints.Reset();
		FBox BlockerLocalBounds;
		FTransform BlockerTransform;
		UPrimitiveComponent Comp = GetBlockingComponent();
		GetBlockerLocalBoundsAndTransform(Comp, BlockerLocalBounds, BlockerTransform);

		TArray<FVector> Points;
		GetWorldPointsOfBlockingSquare(Points);

		for(FVector Point : Points)
		{
			FVector ProjectedPoint;
			if(CeilingData.Spline != nullptr)
			{
				FSplinePosition SplinePosition = CeilingData.Spline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(Point, FVector::UpVector, false);
				SplinePositions.Add(SplinePosition);

				ProjectedPoint = FVector(Point.X, Point.Y, SplinePosition.WorldLocation.Z);
				bool bAtBeginningOfSpline = Math::IsNearlyEqual(SplinePosition.CurrentSplineDistance, 0.0);
				bool bAtEndOfSpline = Math::IsNearlyEqual(SplinePosition.CurrentSplineDistance, CeilingData.Spline.SplineLength);
				if(bAtBeginningOfSpline || bAtEndOfSpline)
				{
					ProjectedPoint = Math::RayPlaneIntersection(ProjectedPoint, FVector::DownVector, FPlane(SplinePosition.WorldLocation, SplinePosition.WorldUpVector));
				}
			}
			else
			{
				FVector BoundsLocation = CeilingData.CeilingTransform.TransformPosition(CeilingData.CeilingLocalBounds.Center);
				BoundsLocation += CeilingData.CeilingTransform.Rotation.UpVector * -CeilingData.CeilingLocalBounds.Extent.Z * CeilingData.CeilingTransform.Scale3D.Z;

				ProjectedPoint = Math::RayPlaneIntersection(Point, FVector::UpVector, FPlane(BoundsLocation, CeilingData.CeilingTransform.Rotation.UpVector));
			}

			WorldPoints.Add(ProjectedPoint);
		}
	}

	void GetValidClimbableLines(FTundraPlayerSnowMonkeyCeilingData CeilingData, TArray<FVector>&out ValidLines, bool bCalledFromEditor) const
	{
		ValidLines.Reset();
		TArray<FVector> ProjectedWorldPoints;
		TArray<FSplinePosition> SplinePositions;
		GetProjectedWorldPointsOnCeiling(CeilingData, ProjectedWorldPoints, SplinePositions);

		for(int i = 0; i < ProjectedWorldPoints.Num(); i++)
		{
			int Ai = i;
			int Bi = Math::WrapIndex(i + 1, 0, ProjectedWorldPoints.Num());

			FVector A = ProjectedWorldPoints[Ai];
			FVector B = ProjectedWorldPoints[Bi];

			bool bAIsInCeiling = CeilingData.IsPointWithinCeiling(A);
			bool bBIsInCeiling = CeilingData.IsPointWithinCeiling(B);

			// If both vertices is within the ceiling we just add the full line!
			if(bAIsInCeiling && bBIsInCeiling)
			{
				ValidLines.Add(A);
				ValidLines.Add(B);
				continue;
			}

			if(CeilingData.Spline != nullptr)
			{
				FSplinePosition SplinePosA = SplinePositions[Ai];
				FSplinePosition SplinePosB = SplinePositions[Bi];

				UHazeSplineComponent EdgeSpline = CeilingData.ClimbComp.GetOrCreateSplineCeilingEdgeSpline(bCalledFromEditor);
				UHazeSplineComponent Spline = CeilingData.Spline;

				// One point is inside the ceiling and one is outside, the line will always intersect exactly one point.
				if(bAIsInCeiling != bBIsInCeiling)
				{
					FVector InCeiling = bAIsInCeiling ? A : B;
					FVector OutCeiling = bAIsInCeiling ? B : A;
					FSplinePosition SplinePos = EdgeSpline.GetClosestSplinePositionToLineSegment(OutCeiling, InCeiling, false);

					ValidLines.Add(InCeiling);
					ValidLines.Add(SplinePos.WorldLocation);
				}
				else // The only other possible case is that both points are outside the ceiling, this is a harder calculation since the line intersects with two points.
				{
					bool bAIsAtStartOrEndOfSpline = SplinePosA.CurrentSplineDistance < CeilingData.Pushback || SplinePosA.CurrentSplineDistance > CeilingData.Spline.SplineLength - CeilingData.Pushback;
					bool bBIsAtStartOrEndOfSpline = SplinePosB.CurrentSplineDistance < CeilingData.Pushback || SplinePosB.CurrentSplineDistance > CeilingData.Spline.SplineLength - CeilingData.Pushback;

					// If either point is at end of spline, don't bother. Designers, please don't make blockers like this!
					if(bAIsAtStartOrEndOfSpline || bBIsAtStartOrEndOfSpline)
						continue;

					bool bAToTheRightOfSpline = SplinePosA.WorldRotation.RightVector.DotProduct(A - SplinePosA.WorldLocation) > 0.0;
					bool bBToTheRightOfSpline = SplinePosB.WorldRotation.RightVector.DotProduct(B - SplinePosB.WorldLocation) > 0.0;

					// Both points are on the same side of the spline, this line is outside the spline
					if(bAToTheRightOfSpline == bBToTheRightOfSpline)
						continue;

					FVector MidPoint = Spline.GetClosestSplinePositionToLineSegment(A, B, false).WorldLocation;
					FVector ValidA = EdgeSpline.GetClosestSplinePositionToLineSegment(A, MidPoint, false).WorldLocation;
					FVector ValidB = EdgeSpline.GetClosestSplinePositionToLineSegment(B, MidPoint, false).WorldLocation;
					ValidLines.Add(ValidA);
					ValidLines.Add(ValidB);
				}
			}
			else
			{
				FVector BoundsLocation;
				FVector BoundsExtents;
				CeilingData.CeilingLocalBounds.GetCenterAndExtents(BoundsLocation, BoundsExtents);

				BoundsExtents *= CeilingData.CeilingTransform.Scale3D;
				BoundsLocation = CeilingData.CeilingTransform.TransformPosition(BoundsLocation);

				BoundsLocation += CeilingData.CeilingTransform.Rotation.UpVector * -BoundsExtents.Z;
				BoundsExtents.X -= CeilingData.Pushback;
				BoundsExtents.Y -= CeilingData.Pushback;
				BoundsExtents.Z = 10.0;

				FTransform CeilingTransform = FTransform(CeilingData.CeilingTransform.Rotation, BoundsLocation);
				FHazeShapeSettings Shape = FHazeShapeSettings::MakeBox(BoundsExtents);

				// One point is inside the ceiling and one is outside, the line will always intersect exactly one point.
				if(bAIsInCeiling != bBIsInCeiling)
				{
					FVector InCeiling = bAIsInCeiling ? A : B;
					FVector OutCeiling = bAIsInCeiling ? B : A;
					FVector Point = Shape.GetClosestPointToLine(CeilingTransform, OutCeiling, (InCeiling - OutCeiling).GetSafeNormal());

					ValidLines.Add(InCeiling);
					ValidLines.Add(Point);
				}
				else // Both points outside ceiling, harder calculation since the line has either zero intersections or two intersections.
				{
					// Hasn't been needed yet, implement if needed!
					continue;
				}
			}
		}
	}

	void GetBlockerLocalBoundsAndTransform(UPrimitiveComponent Comp, FBox&out BlockerLocalBounds, FTransform&out BlockerTransform) const
	{
		float MonkeyCapsuleRadius = TundraShapeshiftingStatics::SnowMonkeyCollisionSize.X + CapsuleMargins;

		BlockerLocalBounds = Comp.GetComponentLocalBoundingBox();
		BlockerTransform = Comp.WorldTransform;
		FVector MonkeyLocalSizeExtents = FVector(MonkeyCapsuleRadius / BlockerTransform.Scale3D.X, MonkeyCapsuleRadius / BlockerTransform.Scale3D.Y, 0.0);
		BlockerLocalBounds = BlockerLocalBounds.ExpandBy(MonkeyLocalSizeExtents);
		BlockerLocalBounds = FBox::BuildAABB( BlockerLocalBounds.Center.VectorPlaneProject(FVector::UpVector), BlockerLocalBounds.Extent.VectorPlaneProject(FVector::UpVector));
	}

	bool ShouldCalculateDataForCeiling(UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp) const
	{
		if(!CachedData.Contains(ClimbComp))
			return true;

		if(!CachedData[ClimbComp].FrameOfCalculation.IsSet())
			return true;

		if(CachedData[ClimbComp].FrameOfCalculation.Value != Time::FrameNumber)
			return true;

		return false;
	}

	FTundraPlayerSnowMonkeyCeilingBlockingData CalculateBlockingDataForCeiling(FTundraPlayerSnowMonkeyCeilingData CeilingData, bool bCalledFromEditor = false) const
	{
		FTundraPlayerSnowMonkeyCeilingBlockingData Data;

		UPrimitiveComponent Comp = BlockingComponent;
		if(bCalledFromEditor)
			Comp = GetBlockingComponent();

		GetBlockerLocalBoundsAndTransform(Comp, Data.BlockerLocalBounds, Data.BlockerTransform);

#if !RELEASE
		if(!bCalledFromEditor)
		{
			TEMPORAL_LOG(Game::Mio, f"Ceiling Blocker on \"{Owner.ActorNameOrLabel}\"")
				.Box(f"Blocker Bounds", Data.BlockerTransform.TransformPosition(Data.BlockerLocalBounds.Center), Data.BlockerLocalBounds.Extent * Data.BlockerTransform.Scale3D, Data.BlockerTransform.Rotator(), FLinearColor::Red, 3.f)
			;
		}
#endif

		GetProjectedWorldPointsOnCeiling(CeilingData, Data.ProjectedWorldPoints);
		GetValidClimbableLines(CeilingData, Data.ClimbableLines, bCalledFromEditor);

#if !RELEASE
		if(!bCalledFromEditor)
		{
			int LineNumber = 0;
			for(int i = 0; i < Data.ClimbableLines.Num(); i += 2)
			{
				LineNumber++;
				TEMPORAL_LOG(Game::Mio, f"Ceiling Blocker on \"{Owner.ActorNameOrLabel}\"")
					.Line(f"{i}#Line {LineNumber};Line", Data.ClimbableLines[i], Data.ClimbableLines[i + 1])
				;
			}

			for(int i = 0; i < Data.ProjectedWorldPoints.Num(); i++)
			{
				TEMPORAL_LOG(Game::Mio, f"Ceiling Blocker on \"{Owner.ActorNameOrLabel}\"")
					.Point(f"Point {i + 1}", Data.ProjectedWorldPoints[i], 20.f, )
				;
			}
		}
#endif
		return Data;
	}
}

#if EDITOR
class UTundraPlayerSnowMonkeyCeilingClimbBlockingComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraPlayerSnowMonkeyCeilingClimbBlockingComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto BlockingComp = Cast<UTundraPlayerSnowMonkeyCeilingClimbBlockingComponent>(Component);

		FBox BlockerLocalBounds;
		FTransform BlockerTransform;
		UPrimitiveComponent Comp = BlockingComp.GetBlockingComponent();
		BlockingComp.GetBlockerLocalBoundsAndTransform(Comp, BlockerLocalBounds, BlockerTransform);

		DrawWireBox(BlockerTransform.TransformPosition(BlockerLocalBounds.Center), BlockerLocalBounds.Extent * BlockerTransform.Scale3D, BlockerTransform.Rotation, FLinearColor::Red, 3.0);

		for(AActor Ceiling : BlockingComp.CeilingsToBlock)
		{
			auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Ceiling);
			auto CeilingData = ClimbComp.GetCeilingData(true, false);
			
			TArray<FVector> ProjectedPoints;
			BlockingComp.GetProjectedWorldPointsOnCeiling(CeilingData, ProjectedPoints);

			for(int i = 0; i < 4; i++)
			{
				FVector ProjectedPoint = ProjectedPoints[i];
				bool bPointIsInsideCeiling = CeilingData.IsPointWithinCeiling(ProjectedPoint);
				DrawPoint(ProjectedPoint, bPointIsInsideCeiling ? FLinearColor::Green : FLinearColor::Red, 30.0);
			}

			TArray<FVector> Lines;
			BlockingComp.GetValidClimbableLines(CeilingData, Lines, true);
			for(int i = 0; i < Lines.Num(); i += 2)
			{
				FVector A = Lines[i];
				FVector B = Lines[i + 1];
				DrawLine(A, B, FLinearColor::Green, 3.0);
			}
		}
	}
}
#endif