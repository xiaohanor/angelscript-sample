enum ETundraPlayerSnowMonkeyTraversalPointType
{
	Ceiling,
	MAX
}

event void FTundraPlayerSnowMonkeyTraversalAttachEvent();

struct FTundraPlayerSnowMonkeyCeilingClimbVersionData
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	float Margins = 0.0;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	float SplineMeshBaseWidthOffset = 0.0;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	int SplineVersion = 0;

	bool SetAndCheckIsChanged(float In_Margins, float In_SplineMeshBaseWidthOffset, int In_SplineVersion)
	{
		bool bIsChanged = Margins != In_Margins || SplineMeshBaseWidthOffset != In_SplineMeshBaseWidthOffset || SplineVersion != In_SplineVersion;

		Margins = In_Margins;
		SplineMeshBaseWidthOffset = In_SplineMeshBaseWidthOffset;
		SplineVersion = In_SplineVersion;
		return bIsChanged;
	}
}

class ATundraPlayerSnowMonkeyCeilingClimbEventActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY()
	FTundraPlayerSnowMonkeyTraversalAttachEvent OnAttach;

	UPROPERTY()
	FTundraPlayerSnowMonkeyTraversalAttachEvent OnDetach;

	UPROPERTY(EditInstanceOnly)
	AHazeActor ClimbingActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(ClimbingActor).OnAttach.AddUFunction(this, n"HandleOnAttach");
		UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(ClimbingActor).OnDeatch.AddUFunction(this, n"HandleOnDetach");
	}

	UFUNCTION()
	private void HandleOnAttach()
	{
		OnAttach.Broadcast();
	}

	UFUNCTION()
	private void HandleOnDetach()
	{
		OnDetach.Broadcast();
	}
}

class UTundraPlayerSnowMonkeyCeilingClimbComponent : UActorComponent
{
	UPROPERTY()
	FTundraPlayerSnowMonkeyTraversalAttachEvent OnAttach;

	UPROPERTY()
	FTundraPlayerSnowMonkeyTraversalAttachEvent OnDeatch;

	/* Increase this value to shrink the allowed area the monkey is able to climb in */
	UPROPERTY(EditAnywhere)
	float Margins = 1.0;

	/* Increase this value to add margins but only on the width, not the ends (only if this is a spline) */
	UPROPERTY(EditAnywhere)
	float SplineMeshBaseWidthOffset = 0.0;

	/* Use this to vertically offset the ceiling (this is to get the correct distance to the ceiling, mostly useful for spline ceilings) */
	UPROPERTY(EditAnywhere)
	float CeilingVerticalOffset = 0.0;

	UPROPERTY(EditAnywhere)
	bool bAllowCoyoteSuckUp = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bAllowCoyoteSuckUp", EditConditionHides))
	bool bAllowCoyoteSuckupEvenWithDownwardsVelocity = false;

	UPROPERTY(EditAnywhere)
	bool bFollowCeilingMovement = true;

	UPROPERTY(EditAnywhere)
	bool bLetGoWhenOutsideClimbZone = false;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	UHazeSplineComponent SplineCeilingEdgeSpline;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	FTundraPlayerSnowMonkeyCeilingClimbVersionData SplineCeilingEdgeVersionData;

	private TArray<FInstigator> Disablers;
	private TArray<UPrimitiveComponent> ClimbableComponents;
	TArray<UTundraPlayerSnowMonkeyCeilingClimbBlockingComponent> CeilingBlockingComps;
	TArray<UTundraPlayerSnowMonkeyCeilingClimbExclusiveComponent> CeilingExclusiveComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto CeilingClimbDataComp = UTundraPlayerSnowMonkeyCeilingClimbDataComponent::GetOrCreate(Game::Mio);
		CeilingClimbDataComp.AllCeilings.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto CeilingClimbDataComp = UTundraPlayerSnowMonkeyCeilingClimbDataComponent::GetOrCreate(Game::Mio);
		CeilingClimbDataComp.AllCeilings.RemoveSingleSwap(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		if(SplineCeilingEdgeSpline != nullptr)
			GetOrCreateSplineCeilingEdgeSpline(true);
	}
#endif

	UFUNCTION(BlueprintCallable)
	void Enable(FInstigator Instigator)
	{
		Disablers.RemoveSingleSwap(Instigator);
		if(!IsDisabled())
			Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintCallable)
	void Disable(FInstigator Instigator)
	{
		if(Disablers.AddUnique(Instigator))
			Owner.AddActorCollisionBlock(this);
	}

	bool IsDisabled() const
	{
		return Disablers.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsMonkeyClimbingOn() const
	{
		auto SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Game::Mio);
		devCheck(SnowMonkeyComp != nullptr, "Tried to check IsMonkeyClimbingOn on a ceiling climb component before snow monkey component exists");
		return SnowMonkeyComp.CurrentCeilingComponent == this;
	}

	bool ComponentIsClimbable(UPrimitiveComponent Component)
	{
		devCheck(Component.Owner == Owner, "Cannot call component is climbable with primitive component not attached to the climbable actor");

		if(ClimbableComponents.Num() == 0)
			return true;

		return ClimbableComponents.Contains(Component);
	}

	void AddClimbableComponent(UPrimitiveComponent Component)
	{
		devCheck(Component.Owner == Owner, "Cannot call add climable component with a component that is not attached to the climbable actor");
		ClimbableComponents.AddUnique(Component);
	}

	UFUNCTION()
	void ForceEnterCeilingClimb()
	{
		AHazePlayerCharacter Mio = Game::Mio;
		Mio.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, false);

		FTundraPlayerSnowMonkeyCeilingData Data = GetCeilingData();
		FVector Location = Mio.ActorLocation;
		FVector ClosestConstrainedPosition;
		if(Data.ConstrainToCeiling(Location, ClosestConstrainedPosition))
		{
			Location = ClosestConstrainedPosition;
		}

		FHazeTraceSettings Trace = Trace::InitFromPlayer(Mio);
		Trace.UseCapsuleShape(TundraShapeshiftingStatics::SnowMonkeyCollisionSize.X, TundraShapeshiftingStatics::OtterCollisionSize.Y);
		FHitResult Hit = Trace.QueryTraceSingle(Location, Location + FVector::UpVector * 1000.0);
		Mio.ActorLocation = Hit.Location + FVector::DownVector * 0.125;
		Mio.SetActorHorizontalAndVerticalVelocity(FVector::ZeroVector, FVector::UpVector * 1000.0);
		auto SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Game::Mio);

		if(SnowMonkeyComp != nullptr)
			SnowMonkeyComp.bForceEnteredCurrentCeilingComp = true;
	}

	FTundraPlayerSnowMonkeyCeilingData GetCeilingData(bool bCalledFromEditor = false, bool bGetBlockingData = true, bool bGetExclusiveData = true)
	{
		TArray<UPrimitiveComponent> CurrentClimbableComponents = ClimbableComponents;

#if EDITOR
		if(bCalledFromEditor)
		{
			CurrentClimbableComponents = Internal_EditorOnlyGetClimbableComponents(this);
		}
#endif

		FTundraPlayerSnowMonkeyCeilingData Data;
		Data.ClimbComp = this;

		if(bGetBlockingData)
		{
			for(auto BlockingComp : CeilingBlockingComps)
			{
				Data.RelevantBlockingData.Add(BlockingComp.GetBlockingDataForCeiling(this, bCalledFromEditor));
			}
		}

		if(bGetExclusiveData)
		{
			for(auto ExclusiveComp : CeilingExclusiveComps)
			{
				Data.RelevantExclusiveData.Add(ExclusiveComp.GetExclusiveDataForCeiling(this, bCalledFromEditor));
			}
		}

		if(CurrentClimbableComponents.Num() == 0)
			Data.Spline = GetSpline(bCalledFromEditor);

		if(Data.Spline != nullptr)
		{
			auto MeshComp = UStaticMeshComponent::Get(Owner);

			if(!bCalledFromEditor)
				devCheck(MeshComp != nullptr, "Actor with ceiling component does not have a static mesh component, this is not supported");

			if(MeshComp != nullptr)
				Data.SplineMeshWidth = MeshComp.StaticMesh.BoundingBox.Extent.Y + SplineMeshBaseWidthOffset;
		}

		Data.Pushback = Margins;

		if(CurrentClimbableComponents.Num() == 0)
		{
			Data.CeilingLocalBounds = Owner.GetActorLocalBoundingBox(true);
			Data.CeilingTransform = Owner.ActorTransform;
		}
		else
		{
			for(UPrimitiveComponent Comp : CurrentClimbableComponents)
			{
				Data.CeilingLocalBounds += Comp.GetComponentLocalBoundingBox();
				Data.CeilingTransform = Comp.WorldTransform;
			}
		}

		Data.VerticalOffset = CeilingVerticalOffset;
		return Data;
	}

	void GetClimbableComponents(TArray<UPrimitiveComponent>&out Components) const
	{
		if(ClimbableComponents.Num() > 0)
		{
			if(Components.Num() > 0)
				Components.Append(ClimbableComponents);

			Components = ClimbableComponents;
			return;
		}

		Owner.GetComponentsByClass(UPrimitiveComponent, Components);
		for(int i = Components.Num() - 1; i >= 0; i--)
		{
			if(!Components[i].IsCollisionEnabled())
				Components.RemoveAt(i);
		}
	}

	private UHazeSplineComponent GetSpline(bool bCalledFromEditor)
	{
		auto TempSpline = UHazeSplineComponent::Get(Owner);

		if(TempSpline == nullptr)
			return TempSpline;

#if EDITOR
		if (!bCalledFromEditor && TempSpline.bIsEditorOnly)
		{
			auto PropLine = Cast<APropLine>(Owner);
			if (PropLine != nullptr)
			{
				if (!PropLine.bGameplaySpline)
					devError(f"UTundraPlayerSnowMonkeyCeilingMovementData is using spline from {PropLine.ActorLabel} for gameplay, but the propline does not have `Gameplay Spline` checked!\nThis will break cooked.");
			}
			else
			{
				devError(f"UTundraPlayerSnowMonkeyCeilingMovementData is using an editor-only spline component for gameplay, this will break cooked. Spline: {TempSpline.GetPathName()}");
			}
		}
#endif

		return TempSpline;
	}

#if EDITOR
	private TArray<UPrimitiveComponent> Internal_EditorOnlyGetClimbableComponents(UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp)
	{
		TArray<UPrimitiveComponent> OutArray;

		TArray<UTundraPlayerSnowMonkeyCeilingClimbSelectorComponent> SelectorComponents;
		ClimbComp.Owner.GetComponentsByClass(SelectorComponents);
		for(UTundraPlayerSnowMonkeyCeilingClimbSelectorComponent SelectorComp : SelectorComponents)
		{
			auto Comp = Cast<UPrimitiveComponent>(SelectorComp.AttachParent);
			if(Comp == nullptr)
				continue;

			OutArray.AddUnique(Comp);
		}

		return OutArray;
	}
#endif

	UHazeSplineComponent GetOrCreateSplineCeilingEdgeSpline(bool bCalledFromEditor)
	{
		bool bSplineChanged = false;
		if(SplineCeilingEdgeSpline == nullptr)
		{
			SplineCeilingEdgeSpline = UHazeSplineComponent::Create(Owner, n"SplineCeilingEdgeSpline");
			bSplineChanged = true;
		}

		bSplineChanged = bSplineChanged || SplineCeilingEdgeVersionData.SetAndCheckIsChanged(Margins, SplineMeshBaseWidthOffset, SplineCeilingEdgeSpline.Version);
		if(!bSplineChanged)
			return SplineCeilingEdgeSpline;

		UHazeSplineComponent CeilingSpline = GetSpline(bCalledFromEditor);

		SplineCeilingEdgeSpline.RelativeTransform = CeilingSpline.RelativeTransform;
		SplineCeilingEdgeSpline.SplinePoints.Reset();

		TArray<FHazeSplinePoint> RightSplinePoints;
		TArray<FHazeSplinePoint> LeftSplinePoints;

		FTundraPlayerSnowMonkeyCeilingData CeilingData = GetCeilingData(bCalledFromEditor, false);
		
		for(int i = 0; i < CeilingSpline.SplinePoints.Num(); i++)
		{
			FHazeSplinePoint SplinePoint = CeilingSpline.SplinePoints[i];
			float DistanceAtPoint = CeilingSpline.GetSplineDistanceAtSplinePointIndex(i);
			FTransform PointTransform = CeilingSpline.GetWorldTransformAtSplineDistance(DistanceAtPoint);

			if(i == 0 || i == CeilingSpline.SplinePoints.Num() - 1)
				PointTransform.Location = PointTransform.Location + PointTransform.Rotation.ForwardVector * Margins * (i == 0 ? 1.0 : -1.0);

			float ScaledClimbWidth = CeilingData.SplineMeshWidth * PointTransform.Scale3D.Y - CeilingData.Pushback;

			FVector RightPointLocation = PointTransform.Location + PointTransform.Rotation.RightVector * ScaledClimbWidth;
			FVector LeftPointLocation = PointTransform.Location - PointTransform.Rotation.RightVector * ScaledClimbWidth;

			FHazeSplinePoint RightSplinePoint;
			RightSplinePoint.RelativeLocation = SplineCeilingEdgeSpline.WorldTransform.InverseTransformPosition(RightPointLocation);
			RightSplinePoint.RelativeRotation = SplinePoint.RelativeRotation;
			RightSplinePoint.RelativeScale3D = SplinePoint.RelativeScale3D;
			RightSplinePoint.bOverrideTangent = SplinePoint.bOverrideTangent;
			RightSplinePoint.bDiscontinuousTangent = SplinePoint.bDiscontinuousTangent;
			RightSplinePoint.ArriveTangent = SplinePoint.ArriveTangent;
			RightSplinePoint.LeaveTangent = SplinePoint.LeaveTangent;

			FHazeSplinePoint LeftSplinePoint;
			LeftSplinePoint.RelativeLocation = SplineCeilingEdgeSpline.WorldTransform.InverseTransformPosition(LeftPointLocation);
			LeftSplinePoint.RelativeRotation = SplinePoint.RelativeRotation;
			LeftSplinePoint.RelativeScale3D = SplinePoint.RelativeScale3D;
			LeftSplinePoint.bOverrideTangent = SplinePoint.bOverrideTangent;
			LeftSplinePoint.bDiscontinuousTangent = SplinePoint.bDiscontinuousTangent;
			LeftSplinePoint.ArriveTangent = -SplinePoint.ArriveTangent;
			LeftSplinePoint.LeaveTangent = -SplinePoint.LeaveTangent;

			if(i == 0)
			{
				FVector OtherTangent = CeilingSpline.GetRelativeTangentAtSplineDistance(0.0);
				RightSplinePoint.bOverrideTangent = true;
				RightSplinePoint.bDiscontinuousTangent = true;
				RightSplinePoint.ArriveTangent = FVector::ZeroVector;
				RightSplinePoint.LeaveTangent = OtherTangent;

				LeftSplinePoint.bOverrideTangent = true;
				LeftSplinePoint.bDiscontinuousTangent = true;
				LeftSplinePoint.LeaveTangent = FVector::ZeroVector;
				LeftSplinePoint.ArriveTangent = -OtherTangent;
			}
			else if(i == CeilingSpline.SplinePoints.Num() - 1)
			{
				FVector OtherTangent = CeilingSpline.GetRelativeTangentAtSplineDistance(CeilingSpline.SplineLength);
				RightSplinePoint.bOverrideTangent = true;
				RightSplinePoint.bDiscontinuousTangent = true;
				RightSplinePoint.LeaveTangent = FVector::ZeroVector;
				RightSplinePoint.ArriveTangent = OtherTangent;

				LeftSplinePoint.bOverrideTangent = true;
				LeftSplinePoint.bDiscontinuousTangent = true;
				LeftSplinePoint.ArriveTangent = FVector::ZeroVector;
				LeftSplinePoint.LeaveTangent = -OtherTangent;
			}

			RightSplinePoints.Add(RightSplinePoint);
			LeftSplinePoints.Add(LeftSplinePoint);
		}

		for(int i = 0; i < RightSplinePoints.Num(); i++)
		{
			SplineCeilingEdgeSpline.SplinePoints.Add(RightSplinePoints[i]);
		}

		for(int i = LeftSplinePoints.Num() - 1; i >= 0; i--)
		{
			SplineCeilingEdgeSpline.SplinePoints.Add(LeftSplinePoints[i]);
		}

		SplineCeilingEdgeSpline.SplineSettings.bClosedLoop = true;
		SplineCeilingEdgeSpline.UpdateSpline();
		SplineCeilingEdgeSpline.MarkRenderStateDirty();

		return SplineCeilingEdgeSpline;
	}
}

#if EDITOR
class UTundraPlayerSnowMonkeyTraversalPointComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UTundraPlayerSnowMonkeyCeilingClimbComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UTundraPlayerSnowMonkeyCeilingClimbComponent ClimbComp = Cast<UTundraPlayerSnowMonkeyCeilingClimbComponent>(Component);
		if(ClimbComp == nullptr)
			return;

		FTundraPlayerSnowMonkeyCeilingData CeilingData = ClimbComp.GetCeilingData(true);
		FVector ArrowOrigin = ClimbComp.Owner.ActorLocation;
		if(CeilingData.Spline == nullptr)
		{
			ArrowOrigin = CeilingData.CeilingTransform.TransformPosition(CeilingData.CeilingLocalBounds.Center - FVector::UpVector * CeilingData.CeilingLocalBounds.Extent.Z);
		}

		FVector DrawPosition = EditorViewLocation;
		FVector DirToClosest = (ArrowOrigin - DrawPosition).GetSafeNormal();
		DrawPosition += DirToClosest * 1000;

		DrawArrow(DrawPosition - (Component.Owner.ActorUpVector * 150), DrawPosition, FLinearColor::Red, 25, 6);
		DrawWorldString("    Ceiling", DrawPosition, FLinearColor::Red, 2);

		const float HeightOffset = -10.0;

		if(CeilingData.Spline != nullptr)
		{
			const float LineLength = 100.0;

			FTransform StartTransform = CeilingData.Spline.GetWorldTransformAtSplineDistance(0.0);

			float ScaledClimbWidth = CeilingData.SplineMeshWidth * StartTransform.Scale3D.Y - CeilingData.Pushback;
			FVector HeightOffsetVector = StartTransform.Rotation.UpVector * HeightOffset;

			FVector LeftCorner = StartTransform.Location - StartTransform.Rotation.RightVector * ScaledClimbWidth + StartTransform.Rotation.ForwardVector * CeilingData.Pushback;
			FVector LeftToCenterLineEnd = LeftCorner + StartTransform.Rotation.RightVector * LineLength;
			FVector LeftToForwardLineEnd = LeftCorner + StartTransform.Rotation.ForwardVector * LineLength;

			FVector RightCorner = StartTransform.Location + StartTransform.Rotation.RightVector * ScaledClimbWidth + StartTransform.Rotation.ForwardVector * CeilingData.Pushback;
			FVector RightToCenterLineEnd = RightCorner - StartTransform.Rotation.RightVector * LineLength;
			FVector RightToForwardLineEnd = RightCorner + StartTransform.Rotation.ForwardVector * LineLength;

			DrawLine(LeftCorner + HeightOffsetVector, LeftToCenterLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);
			DrawLine(LeftCorner + HeightOffsetVector, LeftToForwardLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);
			DrawLine(RightCorner + HeightOffsetVector, RightToCenterLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);
			DrawLine(RightCorner + HeightOffsetVector, RightToForwardLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);

			FTransform EndTransform = CeilingData.Spline.GetWorldTransformAtSplineDistance(CeilingData.Spline.SplineLength);

			ScaledClimbWidth = CeilingData.SplineMeshWidth * EndTransform.Scale3D.Y - CeilingData.Pushback;
			HeightOffsetVector = EndTransform.Rotation.UpVector * HeightOffset;

			LeftCorner = EndTransform.Location - EndTransform.Rotation.RightVector * ScaledClimbWidth - EndTransform.Rotation.ForwardVector * CeilingData.Pushback;
			LeftToCenterLineEnd = LeftCorner + EndTransform.Rotation.RightVector * LineLength;
			LeftToForwardLineEnd = LeftCorner - EndTransform.Rotation.ForwardVector * LineLength;

			RightCorner = EndTransform.Location + EndTransform.Rotation.RightVector * ScaledClimbWidth - EndTransform.Rotation.ForwardVector * CeilingData.Pushback;
			RightToCenterLineEnd = RightCorner - EndTransform.Rotation.RightVector * LineLength;
			RightToForwardLineEnd = RightCorner - EndTransform.Rotation.ForwardVector * LineLength;

			DrawLine(LeftCorner + HeightOffsetVector, LeftToCenterLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);
			DrawLine(LeftCorner + HeightOffsetVector, LeftToForwardLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);
			DrawLine(RightCorner + HeightOffsetVector, RightToCenterLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);
			DrawLine(RightCorner + HeightOffsetVector, RightToForwardLineEnd + HeightOffsetVector, FLinearColor::Red, 2.0);
		}
		else
		{
			FVector BoundsLocation;
			FVector BoundsExtents;
			CeilingData.CeilingLocalBounds.GetCenterAndExtents(BoundsLocation, BoundsExtents);

			BoundsExtents *= CeilingData.CeilingTransform.Scale3D;
			BoundsLocation = CeilingData.CeilingTransform.TransformPosition(BoundsLocation);

			BoundsLocation += CeilingData.CeilingTransform.Rotation.UpVector * (-BoundsExtents.Z + HeightOffset);
			BoundsExtents.X -= CeilingData.Pushback;
			BoundsExtents.Y -= CeilingData.Pushback;
			BoundsExtents.Z = 0.0;

			DrawWireBox(BoundsLocation, BoundsExtents, CeilingData.CeilingTransform.Rotation, FLinearColor::Red, 2.0);
		}
	}
}
#endif