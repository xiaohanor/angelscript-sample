class AMeltdownBossCubeGrid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UInstancedStaticMeshComponent InstancedMesh;
	default InstancedMesh.NumCustomDataFloats = 1;
	default InstancedMesh.RemoveTag(ComponentTags::LedgeClimbable);
	default InstancedMesh.RemoveTag(ComponentTags::LedgeGrabbable);
	default InstancedMesh.RemoveTag(ComponentTags::LedgeRunnable);

	UPROPERTY(DefaultComponent, Attach = InstancedMesh)
	UBoxComponent StaticCollision;
	default StaticCollision.bGenerateOverlapEvents = false;
	default StaticCollision.CollisionProfileName = n"BlockAllDynamic";
	default StaticCollision.RelativeLocation = FVector(200, 200, 0);
	default StaticCollision.BoxExtent = FVector(200, 200, 400);
	default StaticCollision.RemoveTag(ComponentTags::LedgeClimbable);
	default StaticCollision.RemoveTag(ComponentTags::LedgeGrabbable);
	default StaticCollision.RemoveTag(ComponentTags::LedgeRunnable);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
	default ListedComponent.bDelistWhileActorDisabled = false;

	// UPROPERTY(DefaultComponent)
	// UDisableComponent Disable;
	// default Disable.bAutoDisable = true;
	// default Disable.AutoDisableRange = 25000;
	// default Disable.bActorIsVisualOnly = true;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;
	UPROPERTY(EditAnywhere)
	FVector2D Spacing = FVector2D(100, 100);
	UPROPERTY(EditAnywhere)
	FVector2D GridSize = FVector2D(10, 10);

	UPROPERTY(EditAnywhere, Category = "Pop Up")
	bool bPopUpWhenPlayerNearby = false;
	UPROPERTY(EditAnywhere, Category = "Pop Up")
	float PopUpPlayerDistance = 6000.0;
	UPROPERTY(EditAnywhere, Category = "Pop Up")
	float PopUpFromHeight = 5000.0;
	UPROPERTY(EditAnywhere, Category = "Pop Up")
	float PopUpDuration = 1.0;

	bool bDisableDisplacement = false;
	private bool bHadChanges = false;
	private bool bEverythingPoppedUp;

	access PrivateWithCubeGridSoundDef = private, UCharacter_Boss_Meltdown_MeltdownBoss_MeltdownBossCubeGrid_SoundDef;
	access:PrivateWithCubeGridSoundDef 	bool bCubeStartedMoving = false;
	access:PrivateWithCubeGridSoundDef 	bool bCubeStoppedMoving = false;

	private TArray<FTransform> BaseTransforms;
	private TArray<FTransform> ActiveTransforms;
	private TArray<float32> CustomInstanceData;
	private TArray<float> PopUpTime;
	private bool bWereAnyCubesDisplacedLastFrame = false;

	TArray<UMeltdownBossCubeGridDisplacementComponent> DisplacementComponents;
	TArray<UMeltdownBossCubeGridDisplacementComponent> NearbyDisplacementComponents;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		InstancedMesh.StaticMesh = Mesh;
		GenerateBaseTransforms();
		UpdateInstances(true);
	}

	void GenerateBaseTransforms()
	{
		BaseTransforms.Reset();
		for (int X = 0; X < GridSize.X; ++X)
		{
			for (int Y = 0; Y < GridSize.Y; ++Y)
			{
				BaseTransforms.Add(FTransform(
					FRotator(),
					FVector(X * Spacing.X, Y * Spacing.Y, 0),
					FVector::OneVector,
				));
			}
		}

		CustomInstanceData.SetNumZeroed(BaseTransforms.Num());
		ActiveTransforms = BaseTransforms;
	}

	bool UpdateDisplacement()
	{
		TArray<UMeltdownBossCubeGridDisplacementComponent> PreviousDisplacementComponents = NearbyDisplacementComponents;

		int PreviousNearbyCount = NearbyDisplacementComponents.Num();
		NearbyDisplacementComponents.Reset();

		bool bDifferentDisplacementComponents = false;
		bool bUseModifiedCollision = false;
		bool bAnyNearbyNotAsleep = false;
		for (auto DisplaceComp : DisplacementComponents)
		{
			if (IsValid(DisplaceComp) && DisplaceComp.CanAffect(this))
			{
				NearbyDisplacementComponents.Add(DisplaceComp);
				if (DisplaceComp.bModifyCubeGridCollision)
					bUseModifiedCollision = true;
				if (!DisplaceComp.bDisplacementAsleep)
					bAnyNearbyNotAsleep = true;
			}
		}

		if (NearbyDisplacementComponents != PreviousDisplacementComponents)
			bDifferentDisplacementComponents = true;

		// Don't use modified collision unless we have displacement
		if (!bWereAnyCubesDisplacedLastFrame)
			bUseModifiedCollision = false;

		if (bUseModifiedCollision)
		{
			if (InstancedMesh.GetCollisionEnabled() == ECollisionEnabled::NoCollision)
			{
				InstancedMesh.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
				StaticCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
		}
		else
		{
			if (InstancedMesh.GetCollisionEnabled() != ECollisionEnabled::NoCollision)
			{
				InstancedMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				StaticCollision.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
			}
		}

		// Debug::DrawDebugBox(
		// 	ActorLocation, GetActorLocalBoundingBox(false).Extent, ActorRotation,
		// 	bUseModifiedCollision ? FLinearColor::Red : FLinearColor::Green,
		// 	10
		// );

		FVector MioLocation;
		FVector ZoeLocation;
		float PopUpDistSq = Math::Square(PopUpPlayerDistance);
		bool bAllTransformsPoppedUp = true;
		float MinDistToPlayer = 0;
		 
		if (bPopUpWhenPlayerNearby)
		{
			if (Game::Mio != nullptr)
				MioLocation = Game::Mio.ActorLocation;
			if (Game::Zoe != nullptr)
				ZoeLocation = Game::Zoe.ActorLocation;

			if (PopUpTime.Num() != BaseTransforms.Num())
				PopUpTime.SetNumZeroed(BaseTransforms.Num());

			MinDistToPlayer = Math::Min(MioLocation.Dist2D(ActorLocation), ZoeLocation.Dist2D(ActorLocation)) - InstancedMesh.BoundsRadius;
		}

		if (!bAnyNearbyNotAsleep && !bDifferentDisplacementComponents && (!bPopUpWhenPlayerNearby || bEverythingPoppedUp))
			return false;

		if (CustomInstanceData.Num() != BaseTransforms.Num())
			CustomInstanceData.SetNumZeroed(BaseTransforms.Num());

		FTransform Transform = InstancedMesh.WorldTransform;
		bool bHasChanges = false;
		bool bAnyCubesDisplaced = false;

		for (int i = 0, Count = BaseTransforms.Num(); i < Count; ++i)
		{
			FVector Displacement;
			FVector DisplacedScale = FVector::OneVector;
			float DisplacementSizeSq = 0.0;
			float32 DisplacementAlpha = 0.f;

			FVector BaseLocation = BaseTransforms[i].Location;

			for (auto DisplaceComp : NearbyDisplacementComponents)
			{
				FVector WorldLocation = Transform.TransformPosition(BaseLocation);
				float Distance = Math::Max(DisplaceComp.GetDistanceToPoint(WorldLocation) - DisplaceComp.ThresholdDistance, 0);
				if (Distance > DisplaceComp.LerpDistance)
					continue;

				FVector CompDisplacement;
				FVector CompScale;
				float CompAlpha = 0.0;
				if (DisplaceComp.LerpDistance == 0.0)
				{
					CompDisplacement = DisplaceComp.GetCurrentDisplacement(i);
					CompScale = DisplaceComp.Scaling;
					CompAlpha = 1.0;
				}
				else
				{
					CompAlpha = (1.0 - (Distance / DisplaceComp.LerpDistance));
					CompDisplacement = Math::Lerp(FVector(0, 0, 0), DisplaceComp.GetCurrentDisplacement(i), CompAlpha);
					CompScale = Math::Lerp(FVector::OneVector, DisplaceComp.Scaling, CompAlpha);
				}

				float DisplSq = CompDisplacement.SizeSquared();
				if (DisplSq > DisplacementSizeSq)
				{
					Displacement = CompDisplacement;
					DisplacedScale = CompScale;
					DisplacementSizeSq = DisplSq;
					DisplacementAlpha = float32(CompAlpha * DisplaceComp.Redness);
				}
			}

			if (bPopUpWhenPlayerNearby && !bEverythingPoppedUp && Game::Mio != nullptr)
			{
				if (PopUpTime[i] == 0.0)
				{
					FVector BaseWorldLocation = Transform.TransformPosition(BaseLocation);
					float MinDist = Math::Min(MioLocation.DistSquared2D(BaseWorldLocation), ZoeLocation.DistSquared2D(BaseWorldLocation));
					if (MinDist < PopUpDistSq)
						PopUpTime[i] = Time::GameTimeSeconds;
					Displacement.Z -= PopUpFromHeight;
					bAllTransformsPoppedUp = false;
				}
				else
				{
					float Time = Time::GetGameTimeSince(PopUpTime[i]);
					if (Time < PopUpDuration)
					{
						float Distance = PopUpFromHeight * (1.0 - MeltdownCubeGridPopUpCurve.GetFloatValue(Time / PopUpDuration));
						
						const uint HashConstant = 2654435761;
						uint Seed = 0;
						Seed ^= uint(i) * HashConstant;
						Seed ^= uint(Name.Hash) * HashConstant;

						float Wobble = Math::Sin(Time::GameTimeSeconds * PI / 1.0 + ((Seed%200) * 0.2221));
						Distance += Wobble * 300.0 * (1.0 - Time/PopUpDuration);

						Displacement.Z -= Distance;
						bAllTransformsPoppedUp = false;
					}
				}
			}

			FVector NewLocation = BaseLocation + Transform.InverseTransformVector(Displacement);
			const FTransform& PrevTransform = ActiveTransforms[i];
			if (!NewLocation.Equals(PrevTransform.Location) || !DisplacedScale.Equals(PrevTransform.Scale3D) || !Math::IsNearlyEqual(DisplacementAlpha, CustomInstanceData[i]))
			{
				ActiveTransforms[i] = FTransform(
					BaseTransforms[i].Rotation,
					NewLocation,
					DisplacedScale,
				);
				CustomInstanceData[i] = DisplacementAlpha;

				bHasChanges = true;		
				if(!bHadChanges)
				{
					bCubeStartedMoving = true;
				}
			}

			if (Displacement.SizeSquared() > 1.0)
				bAnyCubesDisplaced = true;
		}		
	
		if(!bHasChanges && bHadChanges)
		{
			bCubeStoppedMoving = true;
		}	

		bEverythingPoppedUp = bAllTransformsPoppedUp;
		bWereAnyCubesDisplacedLastFrame = bAnyCubesDisplaced;
		
		return bHasChanges;
	}

	void UpdateInstances(bool bRecreate = false)
	{
		if (bRecreate)
		{
			InstancedMesh.ClearInstances();
			InstancedMesh.AddInstances(ActiveTransforms, false, false);
		}
		else
		{
			InstancedMesh.BatchUpdateInstancesTransforms(
				0, ActiveTransforms, false, true, true
			);
		}

		for (int i = 0, Count = ActiveTransforms.Num(); i < Count; ++i)
			InstancedMesh.SetCustomDataValue(i, 0, CustomInstanceData[i], false);
	}

	bool IsLocationWithinGrid2D(FVector Location, float Margin = 0.0) const
	{
		FBox Box = GetActorLocalBoundingBox(true);
		FVector ClosestPoint = Box.GetClosestPointTo(ActorTransform.InverseTransformPosition(Location));
		return ActorTransform.TransformPosition(ClosestPoint).Distance(Location) <= Margin;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StaticCollision.SetRelativeLocation(FVector(50 * GridSize.X, 50 * GridSize.Y, 0));
		StaticCollision.SetBoxExtent(FVector(50 * GridSize.X, 50 * GridSize.Y, 400));
		GenerateBaseTransforms();
		UpdateInstances(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bDisableDisplacement)
		{			
			if (UpdateDisplacement())
			{
				UpdateInstances();
				bHadChanges = true;
			}
			else
				bHadChanges = false;
		}
	}

#if EDITOR
	private uint32 LastEditorUpdateFrame = 0;
	void UpdateEditorDisplacement(UMeltdownBossCubeGridDisplacementComponent DisplaceComp)
	{
		if (DisplaceComp.bPreviewInEditor)
			DisplacementComponents.AddUnique(DisplaceComp);

		if (LastEditorUpdateFrame != Time::FrameNumber)
		{
			if (UpdateDisplacement())
				UpdateInstances();

			DisplacementComponents.Reset();
			LastEditorUpdateFrame = Time::FrameNumber;
		}
	}
#endif
};

asset MeltdownCubeGridPopUpCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.07|                                                .··''''''··...  |
	    |                                             .·'              ''|
	    |                                          .·'                   |
	    |                                       .·'                      |
	    |                                     .·                         |
	    |                                  .·'                           |
	    |                                .·                              |
	    |                              ·'                                |
	    |                           .·'                                  |
	    |                         .'                                     |
	    |                      .·'                                       |
	    |                    .'                                          |
	    |                 .·'                                            |
	    |             ..·'                                               |
	    |         ..·'                                                   |
	0.0 |......··'                                                       |
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 0.0);
	AddAutoCurveKey(0.8, 1.05);
	AddAutoCurveKey(1.0, 1.0);
}

enum EMeltdownBossCubeGridDisplacementType
{
	None,
	Shape,
	Circle,
	RotatedCircle,
	Line,
};

class UMeltdownBossCubeGridDisplacementComponent : UHazeEditorRenderedComponent
{
	default bTickInEditor = true;

	UPROPERTY(EditAnywhere)
	EMeltdownBossCubeGridDisplacementType Type = EMeltdownBossCubeGridDisplacementType::Shape;
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "Type == EMeltdownBossCubeGridDisplacementType::Shape", EditConditionHides))
	FHazeShapeSettings Shape = FHazeShapeSettings::MakeBox(FVector(100, 100, 100));
	UPROPERTY(EditAnywhere, Interp, Meta = (EditCondition = "Type == EMeltdownBossCubeGridDisplacementType::Circle", EditConditionHides))
	float CircleRadius = 300.0;
	UPROPERTY(EditAnywhere, Interp, Meta = (EditCondition = "Type == EMeltdownBossCubeGridDisplacementType::Line", EditConditionHides, MakeEditWidget))
	FVector LineEnd = FVector(500.0, 0.0, 0.0);
	UPROPERTY(EditAnywhere, Interp)
	float ThresholdDistance = 0.0;
	UPROPERTY(EditAnywhere, Interp)
	float LerpDistance = 100.0;
	UPROPERTY(EditAnywhere, Interp)
	FVector Displacement = FVector(0, 0, 200);
	UPROPERTY(EditAnywhere, Interp)
	FVector Scaling = FVector(1, 1, 1);
	UPROPERTY(EditAnywhere, Interp)
	float Redness = 1.0;
	UPROPERTY(EditAnywhere)
	bool bInfiniteHeight = false;
	UPROPERTY(EditAnywhere)
	bool bPreviewInEditor = true;

	UPROPERTY(EditAnywhere)
	float WobblePeriod = 0.0;
	UPROPERTY(EditAnywhere)
	FVector WobbleDisplacement;


	// If set, the displacement modifies the collision of the cube grid, otherwise it will not
	UPROPERTY(EditAnywhere)
	bool bModifyCubeGridCollision = false;

	/** Whether the displacement should be in this component's relative space or in world space. */
	UPROPERTY(EditAnywhere)
	bool bDisplacementInRelativeSpace = false;

	bool bDisplacementAsleep = false;
	AMeltdownBossCubeGrid AffectOnlyGrid;

	private bool bIsPreviewing = false;
	private bool bIsActive = false;
	private bool bIsDisabled = false;
	private bool bWasActiveBeforeDisable = false;

	bool CanAffect(AMeltdownBossCubeGrid Grid) const
	{
		if (AffectOnlyGrid != nullptr)
			return Grid == AffectOnlyGrid;

		float Size;
		switch (Type)
		{
			case EMeltdownBossCubeGridDisplacementType::None:
				return false;
			case EMeltdownBossCubeGridDisplacementType::Shape:
				Size = Shape.GetEncapsulatingSphereRadius();
			break;
			case EMeltdownBossCubeGridDisplacementType::Circle:
			case EMeltdownBossCubeGridDisplacementType::RotatedCircle:
				Size = CircleRadius;
			break;
			case EMeltdownBossCubeGridDisplacementType::Line:
				Size = WorldLocation.Distance(WorldTransform.TransformPosition(LineEnd));
			break;
		}

		float Range = Size * WorldTransform.Scale3D.AbsMax + 500.0;

		FVector Origin;
		FVector Extent;
		Grid.GetActorBounds(false, Origin, Extent);

		return Origin.Distance(WorldLocation) < (Range + Extent.Size() + Displacement.Size());
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (bIsActive)
		{
			TListedActors<AMeltdownBossCubeGrid> Grids;
			for (AMeltdownBossCubeGrid Grid : Grids)
				Grid.DisplacementComponents.Remove(this);
		}
	}

	UFUNCTION()
	void ActivateDisplacement()
	{
		if (bIsDisabled)
		{
			bWasActiveBeforeDisable = true;
			return;
		}

		if (bIsActive)
			return;

		bIsActive = true;
		TListedActors<AMeltdownBossCubeGrid> Grids;
		for (AMeltdownBossCubeGrid Grid : Grids)
			Grid.DisplacementComponents.AddUnique(this);
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateDisplacement()
	{
		if (bIsDisabled)
		{
			bWasActiveBeforeDisable = false;
			return;
		}

		if (!bIsActive)
			return;

		bIsActive = false;
		TListedActors<AMeltdownBossCubeGrid> Grids;
		for (AMeltdownBossCubeGrid Grid : Grids)
			Grid.DisplacementComponents.Remove(this);
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		bWasActiveBeforeDisable = bIsActive;
		DeactivateDisplacement();
		bIsDisabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		bIsDisabled = false;
		if (bWasActiveBeforeDisable)
			ActivateDisplacement();
	}

	float GetDistanceToPoint(FVector Location) const
	{
		switch (Type)
		{
			case EMeltdownBossCubeGridDisplacementType::None:
				return BIG_NUMBER;
			case EMeltdownBossCubeGridDisplacementType::Shape:
			{
				if (bInfiniteHeight)
					return Shape.GetWorldDistanceToShape(WorldTransform, FVector(Location.X, Location.Y, WorldLocation.Z));
				else
					return Shape.GetWorldDistanceToShape(WorldTransform, Location);
			}
			case EMeltdownBossCubeGridDisplacementType::Circle:
			{
				float FlatDistance = Location.Dist2D(WorldLocation);
				return Math::Abs(FlatDistance - (CircleRadius * WorldScale.AbsMax));
			}
			case EMeltdownBossCubeGridDisplacementType::RotatedCircle:
			{
				float FlatDistance = Location.Dist2D(WorldLocation, UpVector);
				return Math::Abs(FlatDistance - (CircleRadius * WorldScale.AbsMax));
			}
			case EMeltdownBossCubeGridDisplacementType::Line:
			{
				FVector WorldLineStart = WorldLocation;
				FVector WorldLineEnd = WorldTransform.TransformPosition(LineEnd);

				FVector ClosestPoint = Math::ClosestPointOnLine(WorldLineStart, WorldLineEnd, Location);
				if (bInfiniteHeight)
					return ClosestPoint.Dist2D(Location);
				else
					return ClosestPoint.Distance(Location);
			}
		}
	}

	FVector GetCurrentDisplacement(int CubeIndex) const
	{
		FVector FinalDisplacement;
		if (bDisplacementInRelativeSpace)
			FinalDisplacement = WorldTransform.TransformVectorNoScale(Displacement);
		else
			FinalDisplacement = Displacement;

		if (WobblePeriod != 0)
		{
			const uint HashConstant = 2654435761;
			uint Seed = 0;
			Seed ^= uint(CubeIndex) * HashConstant;
			Seed ^= uint(Owner.Name.Hash) * HashConstant;

			float Wobble = Math::Sin(Time::GameTimeSeconds * PI / 1.0 + ((Seed%200) * 0.2221));
			FinalDisplacement += WorldTransform.TransformVectorNoScale(WobbleDisplacement) * Wobble;
		}

		return FinalDisplacement;
	}

	bool IsDisplacementActive() const
	{
		return bIsActive;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (!World.IsGameWorld() && (bPreviewInEditor || bIsPreviewing) && !Editor::IsPlaying())
		{
			TListedActors<AMeltdownBossCubeGrid> Grids;
			for (AMeltdownBossCubeGrid Grid : Grids)
			{
				Grid.UpdateEditorDisplacement(this);
			}
			bIsPreviewing = bPreviewInEditor;
		}
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		OutOrigin = WorldLocation;
		OutBoxExtent = FVector();

		switch (Type)
		{
			case EMeltdownBossCubeGridDisplacementType::Shape:
			{
				OutBoxExtent = FVector(Shape.GetEncapsulatingSphereRadius()) * WorldScale.AbsMax;
				break;
			}
			case EMeltdownBossCubeGridDisplacementType::Circle:
			case EMeltdownBossCubeGridDisplacementType::RotatedCircle:
			{
				OutBoxExtent = FVector(CircleRadius) * WorldScale.AbsMax;
				break;
			}
			case EMeltdownBossCubeGridDisplacementType::Line:
			{
				OutBoxExtent = FVector(LineEnd.Size()) * WorldScale.AbsMax;
				break;
			}
			case EMeltdownBossCubeGridDisplacementType::None:
			break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		SetActorHitProxy();

		if (!bPreviewInEditor)
			return;

		if (Type == EMeltdownBossCubeGridDisplacementType::Shape)
		{
			if (!Shape.IsZeroSize())
			{
				switch (Shape.Type)
				{
					case EHazeShapeType::Box:
						DrawWireBox(
							WorldLocation,
							Shape.BoxExtents,
							ComponentQuat,
							FLinearColor::Red,
							2.0
						);
					break;
					case EHazeShapeType::Sphere:
						DrawWireSphere(
							WorldLocation,
							Shape.SphereRadius,
							FLinearColor::Red,
							2.0
						);
					break;
					case EHazeShapeType::Capsule:
						DrawWireCapsule(
							WorldLocation,
							WorldRotation,
							FLinearColor::Red,
							Shape.CapsuleRadius,
							Shape.CapsuleHalfHeight,
							16, 2.0
						);
					break;
					case EHazeShapeType::None:
					break;
				}
			}
		}
		else if (Type == EMeltdownBossCubeGridDisplacementType::Circle)
		{
			DrawWireCylinder(
				WorldLocation,
				WorldRotation,
				FLinearColor::Red,
				CircleRadius,
				200.0,
				24, 2.0
			);
		}
		else if (Type == EMeltdownBossCubeGridDisplacementType::Line)
		{
			DrawLine(
				WorldLocation,
				WorldTransform.TransformPosition(LineEnd),
				FLinearColor::Red,
				50.0,
			);
		}
	}
#endif
};
