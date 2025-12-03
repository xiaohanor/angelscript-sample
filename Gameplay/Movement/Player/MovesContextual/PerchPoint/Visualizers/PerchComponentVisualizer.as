#if EDITOR
class UPerchComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPerchPointComponent;

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

	void VisualizeGrappleInfo(UPerchPointComponent Comp)
	{
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
	}

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UPerchPointComponent Comp = Cast<UPerchPointComponent>(Component);
        if (Comp == nullptr)
            return;
		
		TArray<AActor> Actors;
		if (!Editor::IsPlaying())
			Actors = Editor::GetAllEditorWorldActorsOfClass(AHazeActor);
		TArray<UPerchPointComponent> PerchPoints;

		PrepareAssets();
		VisualizeGrappleInfo(Comp);

		for (auto Actor : Actors)
		{
			TArray<UActorComponent> ActorComps;
			Actor.GetAllComponents(UPerchPointComponent, ActorComps);

			if(ActorComps.Num() == 0)
				continue;

			for (auto PerchComp : ActorComps)
			{
				UPerchPointComponent PerchPoint = Cast<UPerchPointComponent>(PerchComp);

				if(PerchPoint != nullptr && PerchPoint != EditingComponent)
					PerchPoints.AddUnique(PerchPoint);
			}
		}

		//Draw Lines between all nearby perch point in activation range
		for (auto Point : PerchPoints)
		{
			if(!Point.bHasConnectedSpline)
			{
				if(Comp.bHasConnectedSpline && Comp.ConnectedSpline != nullptr)
				{
					FVector OwnerClosestSplineLocation = Comp.ConnectedSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Point.WorldLocation);
					
					ValidateAndDrawPerchConnection(OwnerClosestSplineLocation, Point.WorldLocation, Comp.ActivationRange);
				}
				else
					ValidateAndDrawPerchConnection(Comp.WorldLocation, Point.WorldLocation, Comp.ActivationRange);
			}
			else
			{
				if(Point.ConnectedSpline != nullptr)
				{
					FVector TargetClosestLocation = Point.ConnectedSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Comp.WorldLocation);

					if(Comp.bHasConnectedSpline && Comp.ConnectedSpline != nullptr)
					{
						FVector OwnerClosestLocation = Comp.ConnectedSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(TargetClosestLocation);

						ValidateAndDrawPerchConnection(OwnerClosestLocation, TargetClosestLocation, Comp.ActivationRange);
					}
					else
						ValidateAndDrawPerchConnection(Comp.WorldLocation, TargetClosestLocation, Comp.ActivationRange);
				}
			}
		}

		// Show Activation range and JumpToAngle Arc if its the currently selected component
		if (Comp == EditingComponent && Comp.bAllowAutoJumpTo && Comp.ActivationRange > 0.0)
		{
			if(!Comp.bAlwaysVisualizeRanges)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor(0.0, 0.4, 0.0), 2.0);

			FVector ArcForward = (EditorViewLocation - Comp.WorldLocation).ConstrainToPlane(Comp.WorldRotation.UpVector).GetSafeNormal();
			DrawArc(
				Comp.WorldLocation + ArcForward * Comp.ActivationRange,
				Comp.MaximumHorizontalJumpToAngle * 2.0, Comp.ActivationRange,
				-ArcForward, FLinearColor(0.0, 1.0, 0.5), 5.0);
		}

		//Only visualize ranges if we are set to always show or its the currently selected component
		if(!Comp.bAlwaysVisualizeRanges && Comp == EditingComponent)
		{
			if (Comp.bAllowGrappleToPoint && Comp.AdditionalGrappleRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalGrappleRange, FLinearColor::Blue, 2.0);

			if (Comp.bAllowGrappleToPoint && Comp.ActivationRange > 0.0 && Comp.AdditionalVisibleRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalGrappleRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0);

			if (Comp.MinimumRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, Thickness = 2.0);
		}

		//Visualize additional perch points on the actor if they arent the selected one
		if(Comp != EditingComponent)
			DrawWireDiamond(Comp.WorldLocation, Comp.WorldRotation, Color =  FLinearColor::Purple, Thickness = 5);
		
		//Show our restriction angle
		if (Comp.bRestrictToForwardVector)
		{
			DrawArc(
				Comp.WorldLocation, Comp.ForwardVectorCutOffAngle * 2.0, Comp.ActivationRange,
				-Comp.ForwardVector, FLinearColor::Green, 4.0, Comp.UpVector
			);
		}
    }

	void ValidateAndDrawPerchConnection(FVector StartLocation, FVector EndLocation, float ActivationRange)
	{
		if((StartLocation - EndLocation).Size() <= ActivationRange)
		{
			DrawLine(StartLocation, EndLocation, FLinearColor::Yellow, 4);
		}
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
		auto Comp = Cast<UPerchPointComponent>(EditingComponent);

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
		auto Comp = Cast<UPerchPointComponent>(EditingComponent);

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
		auto Comp = Cast<UPerchPointComponent>(EditingComponent);

		if(bIsRopeOffsetSelected || bIsWidgetOffsetSelected)
		{
			OutTransform = FTransform(Comp.WorldRotation);
		}
		
		return true;
	}
}
#endif