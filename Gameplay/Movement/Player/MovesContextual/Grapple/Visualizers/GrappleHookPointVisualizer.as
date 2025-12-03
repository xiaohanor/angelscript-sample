#if EDITOR
class UGrapplePointScriptVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGrapplePointComponent;

	UStaticMesh Mesh_DirectionHandle;
	UStaticMesh Mesh_GrappleHook;
	UMaterialInterface Mat_MatSelectedPoint;
	UMaterialInterface Mat_MatHoveredPoint;

	bool bIsRopeOffsetSelected = false;
	bool bIsWidgetOffsetSelected  = false;

	void PrepareAssets()
	{
		Mesh_DirectionHandle = Cast<UStaticMesh>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point.SplineEditor_Point"));
		Mat_MatSelectedPoint = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Selected_Material.SplineEditor_Point_Selected_Material"));
		Mat_MatHoveredPoint = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Hovered_Material.SplineEditor_Point_Hovered_Material"));
		Mesh_GrappleHook = Cast<UStaticMesh>(Editor::LoadAsset(n"/Game/Items/Common/GrappleHook_01.GrappleHook_01"));
	}

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UGrapplePointComponent Comp = Cast<UGrapplePointComponent>(Component);
        if (Comp == nullptr)
            return;

		PrepareAssets();

		auto VisSubsys = UEditorVisualizationSubsystem::Get();
		FTransform Transform = Comp.Owner.ActorTransform;
		Transform.Location = Transform.Location + Transform.TransformVector(Comp.RopeAttachOffset) + (Comp.GrappleRotation.ForwardVector * -10);
		Transform.Rotation = Comp.GrappleRotation;
		Transform.Scale3D = FVector(1.5, 1, 1);
		VisSubsys.DrawMesh(this, Transform, Mesh_GrappleHook);

		UMaterialInterface RopeOffsetMat = nullptr;
		UMaterialInterface WidgetMat = nullptr;
		
		if(bIsRopeOffsetSelected)
		{
			RopeOffsetMat = Mat_MatSelectedPoint;
		}
		else
		{
			if (GetHoveredHitProxy() == n"GrappleHandle")
			{
				RopeOffsetMat = Mat_MatHoveredPoint;
			}
			else
				RopeOffsetMat = nullptr;
		}

		if(bIsWidgetOffsetSelected)
		{
			WidgetMat = Mat_MatSelectedPoint;
		}
		else
		{
			if (GetHoveredHitProxy() == n"WidgetHandle")
			{
				WidgetMat = Mat_MatHoveredPoint;
			}
			else
				WidgetMat = nullptr;
		}

		FVector RopeOffsetPosition = Comp.WorldLocation + Comp.Owner.ActorTransform.TransformVector(Comp.RopeAttachOffset);
		FVector WidgetOffsetPosition = Comp.WorldLocation + Comp.Owner.ActorTransform.TransformVector(Comp.WidgetVisualOffset);

		float GrappleHandleScale = 0.2 * (EditorViewLocation.Distance(RopeOffsetPosition) / (bIsRopeOffsetSelected ? 600 : 450));
		float WidgetHandleScale = 0.2 * (EditorViewLocation.Distance(WidgetOffsetPosition) / (bIsWidgetOffsetSelected ? 600 : 450));

		SetHitProxy(n"GrappleHandle", EVisualizerCursor::CardinalCross);
			DrawMeshWithMaterial(Mesh_DirectionHandle, RopeOffsetMat, RopeOffsetPosition, Comp.Owner.ActorRotation.Quaternion(), FVector(GrappleHandleScale, GrappleHandleScale, GrappleHandleScale));
			DrawWorldString("GrappleAttach", RopeOffsetPosition + (Comp.Owner.ActorRotation.UpVector * 15), bIsRopeOffsetSelected ? FLinearColor::Green : FLinearColor::Yellow, 1.5, bCenterText = true);
		ClearHitProxy();

		SetHitProxy(n"WidgetHandle", EVisualizerCursor::CardinalCross);
			DrawMeshWithMaterial(Mesh_DirectionHandle, WidgetMat, WidgetOffsetPosition, Comp.Owner.ActorRotation.Quaternion(), FVector(WidgetHandleScale, WidgetHandleScale, WidgetHandleScale));
			DrawWorldString("WidgetLocation", WidgetOffsetPosition - (Comp.Owner.ActorRotation.UpVector * 15), bIsWidgetOffsetSelected ? FLinearColor::Green : FLinearColor::Yellow, 1.5, bCenterText = true);
		ClearHitProxy();

		//Draw our ledge/Height visualizer and traced landing location
		float HeightDelta = 0;
		bool ValidInitialWallHit = false;
		bool ValidLedge = TraceForLedgeTop(Comp, HeightDelta, ValidInitialWallHit);
		
		if(ValidInitialWallHit)
		{
			if(HeightDelta > 10)
			{
				DrawArrow(Comp.WorldLocation - Comp.ForwardVector * 100,
							Comp.WorldLocation - (Comp.ForwardVector * 100) + (Comp.UpVector * (ValidLedge ? HeightDelta : Comp.MaxHeightOffsetToLedge)),
								ValidLedge ? FLinearColor::Green : FLinearColor::Red, 10, 5);
				
			}
		}

		if(!Comp.bAlwaysVisualizeRanges)
		{
			if (Comp.ActivationRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor::Blue, 2.0);

			if (Comp.ActivationRange > 0.0 && Comp.AdditionalVisibleRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0);

			if (Comp.MinimumRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, Thickness = 2.0);
		}

		//Show our restriction angle
		if (Comp.bRestrictToForwardVector)
		{
			DrawArc(
				Comp.WorldLocation, Comp.ForwardVectorCutOffAngle * 2.0, Comp.ActivationRange,
				-Comp.ForwardVector, FLinearColor::Green, 4.0, Comp.UpVector
			);

			if (Comp.bRestrictVerticalAngle)
			{
				DrawArc(
					Comp.WorldLocation, Comp.VerticalCutOffAngle * 2, Comp.ActivationRange,
					-Comp.ForwardVector, FLinearColor::LucBlue, 4.0, Comp.RightVector
				);
			}
		}
		else if (Comp.bRestrictVerticalAngle)
		{

			DrawArc(
				Comp.WorldLocation, Comp.VerticalCutOffAngle * 2, Comp.ActivationRange,
				-Comp.ForwardVector, FLinearColor::LucBlue, 4.0, Comp.RightVector
			);
			DrawArc(
				Comp.WorldLocation, Comp.VerticalCutOffAngle * 2, Comp.ActivationRange,
				Comp.ForwardVector, FLinearColor::LucBlue, 4.0, Comp.RightVector
			);
		}
    }

	bool TraceForLedgeTop(UGrapplePointComponent Comp, float& HeightDelta, bool& ValidInitialWallHit)
	{
		FHazeTraceSettings CollisionTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		CollisionTrace.UseLine();

		TArray<UPrimitiveComponent> MeshComps; 
		Comp.Owner.GetComponentsByClass(UStaticMeshComponent, MeshComps);
		CollisionTrace.IgnoreComponents(MeshComps);

		//Trace Inwards to make sure we have a wall close in our forward direction (With initial pullback)
		float PullbackDistance = 100;

		FVector TraceStartLocation = Comp.WorldLocation + (Comp.ForwardVector * -PullbackDistance);
		TraceStartLocation += -Comp.UpVector * 25;
		FVector TraceEndLocation = Comp.WorldLocation + (Comp.ForwardVector * (50 + PullbackDistance));
		TraceEndLocation += -Comp.UpVector * 25;

		FHitResult ForwardWallHit = CollisionTrace.QueryTraceSingle(TraceStartLocation, TraceEndLocation);

		if(!ForwardWallHit.bStartPenetrating)
		{
			DrawArrow(TraceStartLocation, ForwardWallHit.bBlockingHit ? ForwardWallHit.ImpactPoint : TraceEndLocation,
				 Color = ForwardWallHit.bBlockingHit ? FLinearColor::Green : FLinearColor::Red, Thickness = 3);

			DrawWorldString("Wall Trace", TraceStartLocation + Comp.UpVector * 15, ForwardWallHit.bBlockingHit ? FLinearColor::Green : FLinearColor::Red, Scale = 1.25, bCenterText = true);

			DrawPoint(TraceStartLocation, ForwardWallHit.bBlockingHit ? FLinearColor::Green :FLinearColor::Red, 25);
		}

		TraceStartLocation = Comp.WorldLocation + (Comp.UpVector * 82 * 2);
		TraceStartLocation += Comp.ForwardVector * (100);
		TraceEndLocation = TraceStartLocation - (Comp.UpVector * 82 * 3);

		FHitResult EndLocationTrace = CollisionTrace.QueryTraceSingle(TraceStartLocation, TraceEndLocation);
		
		if(EndLocationTrace.bBlockingHit && !EndLocationTrace.bStartPenetrating)
		{
			DrawWireSphere(EndLocationTrace.ImpactPoint, 10, FLinearColor::Green);
			DrawWorldString("Grounded Landing", EndLocationTrace.ImpactPoint + Comp.UpVector * 30, FLinearColor::MakeFromHex(0xfff0a607), Scale = 1.25, bCenterText = true);
		}

		if(ForwardWallHit.bBlockingHit && !ForwardWallHit.bStartPenetrating)
		{
			TraceStartLocation = Comp.WorldLocation + (Comp.ForwardVector * 300) + (Comp.UpVector * 82 * 2);
			TraceEndLocation = TraceStartLocation;
			TraceEndLocation += -Comp.UpVector * (82 * 3);

			FHitResult VaultExitTrace = CollisionTrace.QueryTraceSingle(TraceStartLocation, TraceEndLocation);

			if(!VaultExitTrace.bBlockingHit || VaultExitTrace.bStartPenetrating)
				return false;

			DrawWireSphere(VaultExitTrace.ImpactPoint, 10, FLinearColor::Green);
			DrawWorldString("Aerial Landing", VaultExitTrace.ImpactPoint + Comp.UpVector * 30, FLinearColor::Yellow, Scale = 1.25, bCenterText = true);
		}

		return true;
	}

	//Clear Selected bool when unclicking the widget / Actor
	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsRopeOffsetSelected = false;
		bIsWidgetOffsetSelected = false;
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if(HitProxy.IsEqual(n"GrappleHandle", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsRopeOffsetSelected = true;
			bIsWidgetOffsetSelected = false;
			return true;
		}

		if(HitProxy.IsEqual(n"WidgetHandle", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsWidgetOffsetSelected = true;
			bIsRopeOffsetSelected = false;
			return true;
		}

		bIsRopeOffsetSelected = false;
		bIsWidgetOffsetSelected = false;
		return false;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		auto Comp = Cast<UGrapplePointComponent>(EditingComponent);

		if(bIsRopeOffsetSelected)
		{
			//Add the DeltaTranslation from draggin the handle to our Prefered Direction (visualized arrow end location)
			if (!DeltaTranslate.IsNearlyZero())
			{
				Comp.RopeAttachOffset += Comp.Owner.ActorTransform.InverseTransformVector(DeltaTranslate);
			}

			if (!DeltaRotate.IsNearlyZero())
			{
				FQuat NewRot = Comp.GrappleRotation;
				NewRot = DeltaRotate.Quaternion() * NewRot;
				Comp.GrappleRotation = NewRot;
			}
			return true;
		}

		if(bIsWidgetOffsetSelected)
		{
			//Add the DeltaTranslation from draggin the handle to our Prefered Direction (visualized arrow end location)
			if (!DeltaTranslate.IsNearlyZero())
			{
				Comp.WidgetVisualOffset += Comp.Owner.ActorTransform.InverseTransformVector(DeltaTranslate);
			}
			return true;
		}

		return false;
	}

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Comp = Cast<UGrapplePointComponent>(EditingComponent);

		if(bIsRopeOffsetSelected)
		{
			OutLocation = Comp.WorldTransform.Location + Comp.Owner.ActorTransform.TransformVector(Comp.RopeAttachOffset);
			return true;
		}

		if(bIsWidgetOffsetSelected)
		{
			OutLocation = Comp.WorldTransform.Location + Comp.Owner.ActorTransform.TransformVector(Comp.WidgetVisualOffset);
			return true;
		}

		return false;
	}

	// Used by the editor to determine what the coordinate system for the transform gizmo should be
	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		auto Comp = Cast<UGrapplePointComponent>(EditingComponent);

		if(bIsRopeOffsetSelected || bIsWidgetOffsetSelected)
		{
			OutTransform = FTransform(Comp.WorldRotation);
		}
		
		return true;
	}
}
#endif