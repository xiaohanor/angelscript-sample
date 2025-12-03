#if EDITORONLY_DATA
struct FPropLineGenerationParams
{
	// Mesh settings to generate with
	UPROPERTY(EditAnywhere)
	FPropLineSettings Settings;

	// What kind of generation method to use for this prop line
	UPROPERTY(EditAnywhere)
	EPropLineType Type = EPropLineType::StaticMeshes;

	// How to distribute meshes along the spline
	UPROPERTY(EditAnywhere)
	EPropLineDistributionType MeshDistribution = EPropLineDistributionType::DistributePerSegment;

	// When to stretch meshes when they don't fit exactly into spline segments
	UPROPERTY(EditAnywhere)
	EPropLineStretchType MeshStretching = EPropLineStretchType::StretchLastMeshInSegment;

	// Settings for each line segment in the prop line
	UPROPERTY(EditAnywhere)
	TArray<FPropLineSegment> PerSegmentConfig;

	// Tweak the randomization seed of the meshes, different numbers create different randomization
	UPROPERTY(EditAnywhere)
	int RandomizeTweak = 0;

	// Maximum amount of meshes to generate. If more than this are generated, error out.
	UPROPERTY(EditAnywhere)
	int MaximumTotalMeshes = 1000;

	// Whether created components should be shown in the details view
	UPROPERTY(EditAnywhere)
	bool bShowMeshesInDetailsView = false;
};

namespace FPropLineGenerationParams
{

FPropLineGenerationParams FromPropLine(APropLine PropLine)
{
	FPropLineGenerationParams Params;
	Params.Settings = PropLine.Settings;
	Params.Type = PropLine.Type;
	Params.MeshDistribution = PropLine.MeshDistribution;
	Params.MeshStretching = PropLine.MeshStretching;
	Params.PerSegmentConfig = PropLine.Segments;
	Params.RandomizeTweak = PropLine.RandomizeTweak;
	Params.MaximumTotalMeshes = PropLine.MaximumTotalMeshes;
	Params.bShowMeshesInDetailsView = PropLine.bShowMeshesInDetailsView;
	return Params;
}

};

struct FPropLineMeshGenerationContext
{
	FPropLineGenerationParams Params;
	AActor Actor;
	UHazeSplineComponent PropSpline;
	UTagContainerComponent TagContainer;

	bool bUpdateSplineMeshCollision = true;

	TMap<FName, UActorComponent> UnusedExistingComponents;
	TArray<UActorComponent> GeneratedComponents;

	private FRandomStream RandomStream;
	private int TotalMeshCount;
	private TArray<UPrimitiveComponent> PlacedComps;

	void Generate()
	{
		TotalMeshCount = 0;
		PlacedComps.Empty();
		RandomStream = FRandomStream(GetRandomSeed());

		CreateSegmentMeshes();

		// Create the divider at the very end of the spline
		if (Params.Settings.End.bEnabled)
		{
			// End divider
			FQuat DividerRotation = PropSpline.GetRelativeRotationAtSplineDistance(PropSpline.SplineLength);
			CreateDivider(DividerRotation, PropSpline.ComputedSpline.Segments.Num(), 0, PropSpline.SplineLength, Params.Settings.End);
		}
		else if (Params.Settings.Corner.bEnabled)
		{
			// Corner divider
			CreateCornerDivider(
				GetSegmentType(PropSpline.ComputedSpline.Segments.Num()-1),
				PropSpline.ComputedSpline.Segments.Num(),
				0, PropSpline.SplineLength);
		}
		else if (Params.Settings.Standard.bEnabled && Params.Settings.Standard.Mesh.StaticMesh != nullptr)
		{
			// Standard divider
			FQuat DividerRotation = PropSpline.GetRelativeRotationAtSplineDistance(PropSpline.SplineLength);
			CreateDivider(DividerRotation, PropSpline.ComputedSpline.Segments.Num(), 0, PropSpline.SplineLength, Params.Settings.Standard);
		}
	}

	UActorComponent GetOrGenerateComponent(UClass ComponentClass, FName ComponentName)
	{
		UActorComponent FoundComponent;
		if (UnusedExistingComponents.Find(ComponentName, FoundComponent))
		{
			if (FoundComponent.IsA(ComponentClass))
			{
				// Found an existing component with the same name and class we can reuse
				UnusedExistingComponents.Remove(ComponentName);
				GeneratedComponents.Add(FoundComponent);
				return FoundComponent;
			}
			else
			{
				// Delete the old component so we can create a new one with this name
				UnusedExistingComponents.Remove(ComponentName);
				Editor::DestroyAndRenameInstanceComponentInEditor(FoundComponent);
			}
		}

		// If the component already exists destroy it
		UActorComponent LeftoverComponent = Cast<UActorComponent>(FindObject(Actor, ComponentName.ToString()));
		if (LeftoverComponent != nullptr)
			Editor::DestroyAndRenameInstanceComponentInEditor(LeftoverComponent);

		// Create a new component to use
		UActorComponent NewComponent = Actor.CreateComponent(ComponentClass, ComponentName);
		GeneratedComponents.Add(NewComponent);

		return NewComponent;
	}

	int GetRandomSeed() const
	{
		FVector Location = Actor.GetActorLocation();
		FRotator Rotation = Actor.GetActorRotation();

		const uint HashConstant = 2654435761;
		uint Seed = 0;
		Seed ^= uint(Math::RoundToInt(Location.X)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Location.Y)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Location.Z)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Rotation.Yaw)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Rotation.Pitch)) * HashConstant;
		Seed ^= uint(Math::RoundToInt(Rotation.Roll)) * HashConstant;
		Seed ^= uint(Params.RandomizeTweak) * HashConstant;
		return int(Seed);
	}

	EPropLineSegmentType GetSegmentType(int SegmentIndex) const
	{
		if (Params.Type == EPropLineType::StaticMeshes)
			return EPropLineSegmentType::StaticMesh;
		else if (Params.Type == EPropLineType::StaticMeshesCurvedPlacement)
			return EPropLineSegmentType::StaticMeshCurvedPlacement;
		else if (Params.Type == EPropLineType::SplineMeshes)
			return EPropLineSegmentType::SplineMesh;
		
		if (Params.PerSegmentConfig.IsValidIndex(SegmentIndex))
			return Params.PerSegmentConfig[SegmentIndex].Type;
		return EPropLineSegmentType::StaticMesh;
	}

	bool IsSegmentStraight(int SegmentIndex) const
	{
		if (Params.Type == EPropLineType::StaticMeshes)
			return true;
		else if (Params.Type == EPropLineType::StaticMeshesCurvedPlacement)
			return false;
		else if (Params.Type == EPropLineType::SplineMeshes)
			return false;
		
		if (Params.PerSegmentConfig.IsValidIndex(SegmentIndex))
			return Params.PerSegmentConfig[SegmentIndex].Type == EPropLineSegmentType::StaticMesh;
		return true;
	}

	bool AreSegmentSettingsIdentical(int SegmentIndex, int OtherSegmentIndex) const
	{
		if (Params.Type != EPropLineType::PerSegment)
			return true;

		if (GetSegmentType(SegmentIndex) != GetSegmentType(OtherSegmentIndex))
			return false;

		if (!Params.PerSegmentConfig.IsValidIndex(SegmentIndex))
			return false;
		if (!Params.PerSegmentConfig.IsValidIndex(OtherSegmentIndex))
			return false;

		if (Params.PerSegmentConfig[SegmentIndex].bUseSpecificMesh != Params.PerSegmentConfig[OtherSegmentIndex].bUseSpecificMesh)
			return false;

		if (Params.PerSegmentConfig[SegmentIndex].bUseSpecificMesh)
		{
			if (Params.PerSegmentConfig[SegmentIndex].SpecificMeshIndex != Params.PerSegmentConfig[OtherSegmentIndex].SpecificMeshIndex)
				return false;
		}

		return true;
	}

	void CreateSegmentMeshes()
	{
		if (PropSpline.ComputedSpline.Segments.Num() == 0)
			return;

		if (Params.MeshDistribution == EPropLineDistributionType::DistributePerSegment
			|| Params.MeshDistribution == EPropLineDistributionType::OneMeshPerSegment)
		{
			int MaxMeshesPerSegment = MAX_int32;
			if (Params.MeshDistribution == EPropLineDistributionType::OneMeshPerSegment)
				MaxMeshesPerSegment = 1;

			int SegmentCount = PropSpline.ComputedSpline.Segments.Num();
			for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
			{
				const FHazeComputedSplineSegment& SplineSegment = PropSpline.ComputedSpline.Segments[SegmentIndex];
				float SegmentLength = SplineSegment.EndSplineDistance - SplineSegment.StartSplineDistance;
				CreateMeshesForSegment(SegmentIndex, GetSegmentType(SegmentIndex), SplineSegment.StartSplineDistance, SegmentLength, MaxMeshesPerSegment);
			}
		}
		else if (Params.Type == EPropLineType::PerSegment)
		{
			// Generate for each list of segments of the same type
			int SegmentCount = PropSpline.ComputedSpline.Segments.Num();
			float LastGeneratedDistance = 0.0;
			int GeneratedIndex = 0;
			for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
			{
				if (SegmentIndex == SegmentCount-1 || !AreSegmentSettingsIdentical(SegmentIndex, SegmentIndex+1))
				{
					const FHazeComputedSplineSegment& SplineSegment = PropSpline.ComputedSpline.Segments[SegmentIndex];
					CreateMeshesForSegment(GeneratedIndex, GetSegmentType(SegmentIndex),
						LastGeneratedDistance, SplineSegment.EndSplineDistance - LastGeneratedDistance, MAX_int32);
					LastGeneratedDistance = SplineSegment.EndSplineDistance;
					GeneratedIndex += 1;
				}
			}
		}
		else
		{
			CreateMeshesForSegment(0, GetSegmentType(0),
				0.0, PropSpline.SplineLength,
				MAX_int32,
				PropSpline.SplineSettings.bClosedLoop);
		}
	}

	void CreateMeshesForSegment(int SegmentIndex, EPropLineSegmentType SegmentType, float StartSplineDistance, float SegmentLength, int MaxMeshes, bool bAllowWrappedSpacing = false)
	{
		if (SegmentType == EPropLineSegmentType::NoMeshes)
			return;

		FAngelscriptExcludeScopeFromLoopTimeout ExcludeTimeout;

		float Position = 0.0;

		const bool bGenerateSplineMesh = (SegmentType == EPropLineSegmentType::SplineMesh);
		const bool bPlaceMeshesOnPivot = Params.Settings.bPlaceMeshesOnPivot && !bGenerateSplineMesh;
		TArray<int> SegmentMeshes;
		while (Position < SegmentLength)
		{
			float RemainingLength = SegmentLength - Position;

			int SegmentMeshIndex = SegmentMeshes.Num();
			int TotalMeshIndex = TotalMeshCount + SegmentMeshIndex;
			int BestMeshIndex = SelectMesh(TotalMeshIndex, SegmentMeshIndex, SegmentIndex, RemainingLength);
			if (BestMeshIndex == -1)
				break;

			const FPropLineMesh& Mesh = Params.Settings.Meshes[BestMeshIndex];

			SegmentMeshes.Add(BestMeshIndex);

			float MeshSize = Mesh.CalculateMeshSizeInSegment(bPlaceMeshesOnPivot);
			Position += MeshSize;

			if (MeshSize <= 0.001)
				break;

			if (SegmentMeshes.Num() >= MaxMeshes)
				break;
		}

		if (SegmentMeshes.Num() == 0)
			return;
		if (Math::IsNearlyZero(Position))
			return;

		// Create the new component
		float LastSplinePosition = 0.0;
		int PlacedMeshes = 0;

		float BaseMeshScale = 1.0;
		float LastMeshScale = 1.0;

		if (Params.MeshStretching == EPropLineStretchType::StretchAllMeshes)
		{
			BaseMeshScale = SegmentLength / Position;
			LastMeshScale = BaseMeshScale;
		}
		else if (Params.MeshStretching == EPropLineStretchType::StretchLastMeshInSegment)
		{
			BaseMeshScale = 1.0;

			float LastMeshSize = Params.Settings.Meshes[SegmentMeshes.Last()].CalculateMeshSizeInSegment(bPlaceMeshesOnPivot);
			float LastMeshWantedSize = SegmentLength - (Position - LastMeshSize);
			LastMeshScale = LastMeshWantedSize / LastMeshSize;
		}

		float MaxSplinePosition = SegmentLength;
		if (Params.MeshStretching == EPropLineStretchType::NeverStretch && bGenerateSplineMesh)
			MaxSplinePosition = PropSpline.SplineLength - StartSplineDistance;

		for (int i = 0, Count = SegmentMeshes.Num(); i < Count; ++i)
		{
			const FPropLineMesh& Mesh = Params.Settings.Meshes[SegmentMeshes[i]];

			float ScaleAlongSpline = BaseMeshScale;
			if (i == Count-1)
				ScaleAlongSpline = LastMeshScale;

			if (ScaleAlongSpline < 0.01)
				continue;

			float MeshSize = Mesh.CalculateMeshSizeInSegment(bPlaceMeshesOnPivot);
			float SplinePosition = LastSplinePosition + (MeshSize * ScaleAlongSpline);

			if (SplinePosition > MaxSplinePosition)
			{
				SplinePosition = MaxSplinePosition;
				if (Params.MeshStretching == EPropLineStretchType::NeverStretch && bGenerateSplineMesh)
					continue;
			}

			// Figure out the transform for the component
			FVector Scale = FVector(
				Mesh.Scale.X,
				Mesh.Scale.Y,
				Mesh.Scale.Z,
			);

			FName PropName = Mesh.Mesh.StaticMesh.Name;
			if (Params.MeshDistribution == EPropLineDistributionType::DistributeOverEntireSpline)
				PropName.SetNumber(TotalMeshCount + 1);
			else if (PlacedMeshes >= 100)
				PropName = NAME_None;
			else
				PropName.SetNumber((SegmentIndex+1) * 100 + PlacedMeshes + 1);

			bool bPlaceAsStaticMesh = !bGenerateSplineMesh;
			FQuat DividerRotation;

			if (bGenerateSplineMesh)
			{
				float PlaceStartDistance = StartSplineDistance + LastSplinePosition;
				float PlaceEndDistance = StartSplineDistance + LastSplinePosition + (MeshSize * ScaleAlongSpline);

				float PlaceMiddle = (PlaceStartDistance + PlaceEndDistance) * 0.5;
				float PlaceDistance = (PlaceEndDistance - PlaceStartDistance) * 0.5 * Mesh.Scale.X / Mesh.SpacingMultiplier;


				float TangentScale;
				if (bAllowWrappedSpacing)
				{
					PlaceStartDistance = Math::Wrap(PlaceMiddle - PlaceDistance, StartSplineDistance, StartSplineDistance + SegmentLength);
					PlaceEndDistance = Math::Wrap(PlaceMiddle + PlaceDistance, StartSplineDistance, StartSplineDistance + SegmentLength);

					if (PlaceEndDistance < PlaceStartDistance)
						TangentScale = SegmentLength - (PlaceStartDistance - PlaceEndDistance);
					else
						TangentScale = (PlaceEndDistance - PlaceStartDistance);
				}
				else
				{
					PlaceStartDistance = Math::Max(PlaceMiddle - PlaceDistance, StartSplineDistance);
					PlaceEndDistance = Math::Min(PlaceMiddle + PlaceDistance, StartSplineDistance + SegmentLength);
					TangentScale = (PlaceEndDistance - PlaceStartDistance);
				}

				FTransform StartTransform = PropSpline.GetRelativeTransformAtSplineDistance(PlaceStartDistance);
				FTransform EndTransform = PropSpline.GetRelativeTransformAtSplineDistance(PlaceEndDistance);

				FVector StartTangent = PropSpline.GetRelativeTangentAtSplineDistance(PlaceStartDistance).GetSafeNormal();
				FVector EndTangent = PropSpline.GetRelativeTangentAtSplineDistance(PlaceEndDistance).GetSafeNormal();
				
				FVector StartUpVector = StartTransform.GetRotation().GetUpVector();
				FVector EndUpVector = EndTransform.GetRotation().GetUpVector();

				FVector StartScale = StartTransform.Scale3D;
				FVector EndScale = EndTransform.Scale3D;

				// In cases where the tangent is straight and the scale doesn't change, we
				// actually place a static mesh instead of a spline mesh. They will look the same
				// and static meshes perform better!
				bPlaceAsStaticMesh = 
					StartTangent.Equals(EndTangent)
					&& StartUpVector.Equals(EndUpVector)
					&& StartScale.Equals(EndScale)
					&& Mesh.ForwardAxis == ESplineMeshAxis::X
				;

				if (!bPlaceAsStaticMesh)
				{
					auto PropComp = 
						Cast<UHazePropSplineMeshComponent>(
							GetOrGenerateComponent(UHazePropSplineMeshComponent, PropName)
						);

					PropComp.Mobility = Actor.RootComponent.Mobility;
					PropComp.AttachToComponent(Actor.RootComponent);
					PropComp.SetTranslucentSortPriority(Mesh.BaseTranslucentSortPriority);

#if EDITOR
					PropComp.bDisableGenerateCollision = true;
#endif
					PropComp.IsVisualizationComponent = !Params.bShowMeshesInDetailsView;
					PropComp.bIsEditorOnly = false;
					PlacedComps.Add(PropComp);
					PropComp.ConfigureFromConstructionScript(Mesh.Mesh);
					PropComp.SetLightmapType(ELightmapType::ForceSurface);

					if (TagContainer != nullptr)
						Editor::CopyAllComponentTags(TagContainer, PropComp);

					PropComp.SetStartScale(FVector2D(Scale.Y * StartScale.Y, Scale.Z * StartScale.Z), bUpdateMesh = false);
					PropComp.SetEndScale(FVector2D(Scale.Y * EndScale.Y, Scale.Z * EndScale.Z), bUpdateMesh = false);

					FVector StartLocation = StartTransform.Location;
					FVector EndLocation = EndTransform.Location;
					FVector CenterLocation = (EndLocation + StartLocation) * 0.5;

					PropComp.RelativeLocation = CenterLocation;
					
					PropComp.SetStartAndEnd(
						StartLocation - CenterLocation,
						StartTangent * TangentScale,
						EndLocation - CenterLocation,
						EndTangent * TangentScale, bUpdateMesh = false);
					
					// Twist-correct.
					FVector C1 = EndTangent.CrossProduct(StartUpVector).GetSafeNormal();
					FVector C2 = EndTangent.CrossProduct(EndUpVector).GetSafeNormal();
					FVector C3 = C1.CrossProduct(C2).GetSafeNormal();
					
					float A = C1.DotProduct(C2);
					float B = C3.DotProduct(EndTangent);
					float EndRoll = Math::Acos(A) * -Math::Sign(B);
					float AddedRoll = Math::DegreesToRadians(-Mesh.Roll);

					PropComp.SetStartRoll(AddedRoll, bUpdateMesh = false);
					PropComp.SetEndRoll(EndRoll + AddedRoll, bUpdateMesh = false);
					
					PropComp.SetSplineUpDir(StartUpVector, bUpdateMesh = false);
					PropComp.SetForwardAxis(Mesh.ForwardAxis, bUpdateMesh = false);
#if EDITOR
					if (bUpdateSplineMeshCollision)
						PropComp.bDisableGenerateCollision = false;
#endif
					PropComp.UpdateMesh(bUpdateCollision = bUpdateSplineMeshCollision);

					if (Params.Settings.bForceSurfaceLightmaps)
						PropComp.SetLightmapType(ELightmapType::ForceSurface);
					else
						PropComp.SetLightmapType(ELightmapType::Default);

					DividerRotation = StartTransform.Rotation;
				}
			}
			
			if (bPlaceAsStaticMesh)
			{
				auto PropComp = 
					Cast<UHazePropComponent>(
						GetOrGenerateComponent(UHazePropComponent, PropName)
					);
				PropComp.Mobility = Actor.RootComponent.Mobility;
				PropComp.AttachToComponent(Actor.RootComponent);
				PropComp.IsVisualizationComponent = !Params.bShowMeshesInDetailsView;
				PropComp.bIsEditorOnly = false;
				PropComp.ConfigureFromConstructionScript(Mesh.Mesh);
				PlacedComps.Add(PropComp);
				PropComp.SetLightmapType(ELightmapType::ForceSurface);

				if (TagContainer != nullptr)
					Editor::CopyAllComponentTags(TagContainer, PropComp);

				FVector StartPoint = PropSpline.GetRelativeLocationAtSplineDistance(
					StartSplineDistance + LastSplinePosition
				);

				FVector EndPoint = PropSpline.GetRelativeLocationAtSplineDistance(
					StartSplineDistance + SplinePosition
				);

				FVector PlacePoint;
				if (bPlaceMeshesOnPivot)
					PlacePoint = StartPoint;
				else 
					PlacePoint = StartPoint + (EndPoint - StartPoint).GetSafeNormal() * (MeshSize * ScaleAlongSpline * 0.5);

				float MiddleSplineDistance = StartSplineDistance + (SplinePosition + LastSplinePosition) * 0.5;
				FVector ScaleOnSpline = PropSpline.GetRelativeScale3DAtSplineDistance(MiddleSplineDistance);

				FQuat RotationInSpline;
				if (SegmentType == EPropLineSegmentType::StaticMeshCurvedPlacement)
					RotationInSpline = PropSpline.GetRelativeRotationAtSplineDistance(MiddleSplineDistance);
				else
					RotationInSpline = PropSpline.GetRelativeRotationAtSplineDistance(StartSplineDistance + 0.001);

				if (Mesh.Roll != 0)
					RotationInSpline = RotationInSpline * FQuat(FVector::ForwardVector, Math::DegreesToRadians(Mesh.Roll));

				FTransform RelativeTransform;
				RelativeTransform.Rotation = FQuat::MakeFromXZ(
					(EndPoint - StartPoint).GetSafeNormal(),
					RotationInSpline.UpVector);
				RelativeTransform.Location = PlacePoint;

				switch (Mesh.ForwardAxis)
				{
					case ESplineMeshAxis::X:
						Scale.X = Mesh.Scale.X * ScaleAlongSpline;
						Scale.Y = Mesh.Scale.Y * ScaleOnSpline.Y;
						Scale.Z = Mesh.Scale.Z * ScaleOnSpline.Z;
					break;
					case ESplineMeshAxis::Y:
						Scale.Y *= Mesh.Scale.X * ScaleAlongSpline;
						Scale.X = Mesh.Scale.Z * ScaleOnSpline.Z;
						Scale.Z = Mesh.Scale.Y * ScaleOnSpline.Y;

						RelativeTransform.Rotation = RelativeTransform.Rotation
							* FQuat(FVector::RightVector, 0.5 * PI)
							* FQuat(FVector::ForwardVector, -0.5 * PI);
					break;
					case ESplineMeshAxis::Z:
						Scale.Z = Mesh.Scale.X * ScaleAlongSpline;
						Scale.X = Mesh.Scale.Z * ScaleOnSpline.Z;
						Scale.Y = Mesh.Scale.Y * ScaleOnSpline.Y;

						RelativeTransform.Rotation = RelativeTransform.Rotation * FQuat(FVector::RightVector, 0.5 * PI);
					break;
				}
				
				RelativeTransform.Scale3D = Scale;

				// If this was supposed to look like a spline mesh but is being generated as a static mesh,
				// remove any offset from the pivot placement we might have.
				if (bGenerateSplineMesh)
				{
					switch (Mesh.ForwardAxis)
					{
					case ESplineMeshAxis::X:
						RelativeTransform.AddToTranslation(
							RelativeTransform.TransformVector(
								FVector(
									-Mesh.Mesh.StaticMesh.Bounds.Origin.X, 0, 0
								)
							)
						);
					break;
					case ESplineMeshAxis::Y:
						RelativeTransform.AddToTranslation(
							RelativeTransform.TransformVector(
								FVector(
									0, -Mesh.Mesh.StaticMesh.Bounds.Origin.Y, 0
								)
							)
						);
					break;
					case ESplineMeshAxis::Z:
						RelativeTransform.AddToTranslation(
							RelativeTransform.TransformVector(
								FVector(
									0, 0, -Mesh.Mesh.StaticMesh.Bounds.Origin.Z
								)
							)
						);
					break;
					}
				}

				if (Params.Settings.bForceSurfaceLightmaps)
					PropComp.SetLightmapType(ELightmapType::ForceSurface);
				else
					PropComp.SetLightmapType(ELightmapType::Default);

				PropComp.RelativeTransform = RelativeTransform;
				DividerRotation = RelativeTransform.Rotation;
			}

			if (SegmentIndex == 0 && i == 0 && Params.Settings.Start.bEnabled)
			{
				// Start divider
				CreateDivider(DividerRotation, SegmentIndex, i, StartSplineDistance + LastSplinePosition, Params.Settings.Start);
			}
			else if (i == 0 && Params.Settings.Corner.bEnabled)
			{
				// Corner divider
				CreateCornerDivider(SegmentType, SegmentIndex, i, StartSplineDistance + LastSplinePosition);
			}
			else if (Params.Settings.Standard.bEnabled && Params.Settings.Standard.Mesh.StaticMesh != nullptr)
			{
				// Standard divider
				CreateDivider(DividerRotation, SegmentIndex, i, StartSplineDistance + LastSplinePosition, Params.Settings.Standard);
			}

			PlacedMeshes += 1;
			TotalMeshCount += 1;
			LastSplinePosition = SplinePosition;

			if (TotalMeshCount >= Params.MaximumTotalMeshes && Params.MaximumTotalMeshes > 0)
			{
				devError(f"Prop Line {Actor} generated more than its configured maximum allowed amount of meshes ({Params.MaximumTotalMeshes})");
				break;
			}
		}

		for (int i = 0; i < PlacedComps.Num(); i++)
		{
			PlacedComps[i].SetDefaultCustomPrimitiveDataFloat(2, i);
			PlacedComps[i].SetDefaultCustomPrimitiveDataFloat(3, PlacedComps.Num()-1);
		}
		
	}

	void CreateCornerDivider(EPropLineSegmentType SegmentType, int SegmentIndex, int DividerIndex, float SplineDistance)
	{
		FQuat DividerRotation;
		FPropLineDivider Divider = Params.Settings.Corner;

		// Find the spline point that is closest to the location we want the corner at
		int PointCount = PropSpline.ComputedSpline.Points.Num();
		int SplinePointIndex = -1;
		float BestSplinePointDist = MAX_flt;

		for (int PointIndex = 0; PointIndex < PointCount; ++PointIndex)
		{
			float PointSplineDistance = PropSpline.ComputedSpline.Points[PointIndex].SplineDistance;
			float Dist = Math::Abs(SplineDistance - PointSplineDistance);
			if (Dist < BestSplinePointDist)
			{
				BestSplinePointDist = Dist;
				SplinePointIndex = PointIndex;
			}
		}

		if (SplinePointIndex != -1 && PointCount >= 2)
		{
			const FHazeSplinePoint& Point = PropSpline.SplinePoints[SplinePointIndex];

			// Compute the directions to the next and previous spline point
			FVector PreviousPointLocation;
			FVector NextPointLocation;

			if (SplinePointIndex == 0 && !PropSpline.SplineSettings.bClosedLoop)
			{
				NextPointLocation = PropSpline.SplinePoints[SplinePointIndex+1].RelativeLocation;
				PreviousPointLocation = Point.RelativeLocation - (NextPointLocation - Point.RelativeLocation);
			}
			else if (SplinePointIndex == PropSpline.SplinePoints.Num()-1 && !PropSpline.SplineSettings.bClosedLoop)
			{
				PreviousPointLocation = PropSpline.SplinePoints[SplinePointIndex-1].RelativeLocation;
				NextPointLocation = Point.RelativeLocation - (PreviousPointLocation - Point.RelativeLocation);
			}
			else
			{
				int NextIndex = Math::WrapIndex(SplinePointIndex+1, 0, PointCount);
				int PrevIndex = Math::WrapIndex(SplinePointIndex-1, 0, PointCount);

				PreviousPointLocation = PropSpline.SplinePoints[PrevIndex].RelativeLocation;
				NextPointLocation = PropSpline.SplinePoints[NextIndex].RelativeLocation;
			}

			FVector ToNext = (NextPointLocation - Point.RelativeLocation);
			FVector ToPrev = (PreviousPointLocation - Point.RelativeLocation);
			float CornerAngle = Math::RadiansToDegrees(ToNext.AngularDistance(ToPrev));

			FVector PointUpVector = Point.RelativeRotation.UpVector;
			FVector PointRightVector = ToNext.CrossProduct(PointUpVector);

			// If the corner is convex, we need to take the other angle distance
			bool bIsConvex = ToPrev.DotProduct(PointRightVector) > 0.0;
			if (bIsConvex)
				CornerAngle = 360.0 - CornerAngle;

			if (Params.Settings.bRotateCornersAlongPrecedingSegment)
			{
				const FHazeComputedSplinePoint& PreviousPoint = PropSpline.ComputedSpline.Points[Math::Max(0, SplinePointIndex-1)];
				DividerRotation = PropSpline.GetRelativeRotationAtSplineDistance(PreviousPoint.SplineDistance + 0.001);
			}
			else if (SegmentType == EPropLineSegmentType::StaticMesh)
			{
				DividerRotation = FQuat::MakeFromXZ(
					NextPointLocation - PreviousPointLocation,
					PointUpVector,
				);
			}
			else
			{
				DividerRotation = PropSpline.GetRelativeRotationAtSplineDistance(SplineDistance);
			}

			// Determine which corner mesh to use based on the angle
			if (Params.Settings.bUseAngledCorners)
			{
				for (const FPropLineAngledCorner& AngledCorner : Params.Settings.AngledCorners)
				{
					if (AngledCorner.AngleMinimum > CornerAngle)
						continue;
					if (AngledCorner.AngleMaximum <= CornerAngle)
						continue;

					Divider.Mesh = AngledCorner.Mesh;
					Divider.Scale = AngledCorner.Scale;
					Divider.Rotation = AngledCorner.Rotation;
					break;
				}
			}
		}
		else
		{
			// Use the tangent on the spline to place the divider
			DividerRotation = PropSpline.GetRelativeRotationAtSplineDistance(SplineDistance);
		}

		CreateDivider(DividerRotation, SegmentIndex, DividerIndex, SplineDistance, Divider);
	}

	void CreateDivider(FQuat DividerRotation, int SegmentIndex, int DividerIndex, float SplineDistance, const FPropLineDivider& Divider)
	{
		if (Divider.Mesh.StaticMesh == nullptr)
			return;

		FVector Position = PropSpline.GetRelativeLocationAtSplineDistance(SplineDistance);

		FName DividerName = FName(f"Divider_{Divider.Mesh.StaticMesh.Name}");
		if (Params.MeshDistribution == EPropLineDistributionType::DistributeOverEntireSpline)
			DividerName.SetNumber(TotalMeshCount + 1);
		else if (DividerIndex >= 100)
			DividerName = NAME_None;
		else
			DividerName.SetNumber((SegmentIndex+1) * 100 + DividerIndex + 1);

		auto PropComp = 
			Cast<UHazePropComponent>(
				GetOrGenerateComponent(UHazePropComponent, DividerName)
			);
		PropComp.IsVisualizationComponent = !Params.bShowMeshesInDetailsView;
		PropComp.bIsEditorOnly = false;
		PropComp.ConfigureFromConstructionScript(Divider.Mesh);
		if (TagContainer != nullptr)
			Editor::CopyAllComponentTags(TagContainer, PropComp);

		FTransform RelativeTransform;
		RelativeTransform.Location = Position;
		RelativeTransform.Rotation = DividerRotation * Divider.Rotation.Quaternion();
		RelativeTransform.Scale3D = Divider.Scale;
		PropComp.RelativeTransform = RelativeTransform;

		if (Params.Settings.bForceSurfaceLightmaps)
			PropComp.SetLightmapType(ELightmapType::ForceSurface);
		else
			PropComp.SetLightmapType(ELightmapType::Default);
	}

	int SelectMesh(int MeshIndexOnSpline, int MeshIndexOnSegment, int SegmentIndex, float SegmentLength)
	{
		if (Params.Settings.Meshes.Num() == 1)
		{
			if (Params.Settings.Meshes[0].Mesh.StaticMesh != nullptr)
				return 0;
			else
				return -1;
		}

		int BestMeshIndex = -1; 
		float BestMeshSize = 0.0;

		// We might have set to always use a specific mesh
		if (Params.Type == EPropLineType::PerSegment)
		{
			if (Params.PerSegmentConfig.IsValidIndex(SegmentIndex) && Params.PerSegmentConfig[SegmentIndex].bUseSpecificMesh)
			{
				if (Params.Settings.Meshes.IsValidIndex(Params.PerSegmentConfig[SegmentIndex].SpecificMeshIndex))
				{
					return Params.PerSegmentConfig[SegmentIndex].SpecificMeshIndex;
				}
			}
		}

		// Select a mesh based on the index on the spline
		if (Params.Settings.MeshSelection == EPropLineMeshSelectionType::CycleInOrder)
		{
			return MeshIndexOnSpline % Params.Settings.Meshes.Num();
		}

		// Select a mesh based on the index on this specific segment
		if (Params.Settings.MeshSelection == EPropLineMeshSelectionType::CycleInOrderPerSegment)
		{
			return MeshIndexOnSegment % Params.Settings.Meshes.Num();
		}

		// Select a random mesh from those that fit
		if (Params.Settings.MeshSelection == EPropLineMeshSelectionType::Random)
		{
			// Find a random mesh out of the ones that are small enough
			TArray<int> AvailableMeshes;
			AvailableMeshes.Reserve(Params.Settings.Meshes.Num());

			for (int i = 0, Count = Params.Settings.Meshes.Num(); i < Count; ++i)
			{
				const FPropLineMesh& Mesh = Params.Settings.Meshes[i];
				if (Mesh.Mesh.StaticMesh == nullptr)
					continue;

				float MeshSize = Mesh.CalculateMeshSizeInSegment(Params.Settings.bPlaceMeshesOnPivot);
				if (MeshSize > SegmentLength)
					continue;

				AvailableMeshes.Add(i);
			}

			if (AvailableMeshes.Num() != 0)
			{
				int RandomIndex = RandomStream.RandRange(0, AvailableMeshes.Num() - 1);
				return AvailableMeshes[RandomIndex];
			}
		}

		// Pick the largest fitting mesh
		if (Params.Settings.MeshSelection == EPropLineMeshSelectionType::LargestFitting)
		{
			// Try to find the largest mesh that is smaller than the segment length
			for (int i = 0, Count = Params.Settings.Meshes.Num(); i < Count; ++i)
			{
				const FPropLineMesh& Mesh = Params.Settings.Meshes[i];
				if (Mesh.Mesh.StaticMesh == nullptr)
					continue;

				float MeshSize = Mesh.CalculateMeshSizeInSegment(Params.Settings.bPlaceMeshesOnPivot);
				if (MeshSize > SegmentLength)
					continue;

				if (MeshSize > BestMeshSize)
				{
					BestMeshIndex = i;
					BestMeshSize = MeshSize;
				}
			}

			if (BestMeshIndex != -1)
				return BestMeshIndex;
		}

		// Fallback: We couldn't find a fitting mesh, so use the smallest available mesh instead
		BestMeshSize = MAX_flt;
		for (int i = 0, Count = Params.Settings.Meshes.Num(); i < Count; ++i)
		{
			const FPropLineMesh& Mesh = Params.Settings.Meshes[i];
			if (Mesh.Mesh.StaticMesh == nullptr)
				continue;

			float MeshSize = Mesh.CalculateMeshSizeInSegment(Params.Settings.bPlaceMeshesOnPivot);
			if (MeshSize < BestMeshSize)
			{
				BestMeshSize = MeshSize;
				BestMeshIndex = i;
			}
		}

		return BestMeshIndex;
	}
};
#endif