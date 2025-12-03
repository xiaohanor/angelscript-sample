#if EDITOR
class UGrappleSlidePointScriptVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGrappleSlidePointComponent;

	UStaticMesh Mesh_GrappleHook;
	UStaticMesh Mesh_DirectionHandle;
	UMaterialInterface Mat_MatSelectedPoint;
	UMaterialInterface Mat_MatHoveredPoint;

	bool bIsAssistDirectionSelected = false;
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
		UGrappleSlidePointComponent Comp = Cast<UGrappleSlidePointComponent>(Component);
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

		//Should ranges be shown even when actor is not selected (Useful to align with other actor ranges)
		if(!Comp.bAlwaysVisualizeRanges)
		{
			if (Comp.ActivationRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor::Blue, 2.0);

			if (Comp.ActivationRange > 0.0 && Comp.AdditionalVisibleRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0);

			if (Comp.MinimumRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, Thickness = 2.0);
		}

		if(Comp.OverrideEdgeClearanceValue > 0)
		{
			DrawPoint(Comp.Owner.ActorLocation + (Comp.WorldRotation.ForwardVector * -Comp.OverrideEdgeClearanceValue), FLinearColor::Yellow, 25);
			DrawDashedLine(Comp.Owner.ActorLocation + (Comp.WorldRotation.ForwardVector * -Comp.OverrideEdgeClearanceValue), Comp.Owner.ActorLocation, FLinearColor::Yellow, 10, 2);
			DrawWorldString("EdgeClearance", Comp.Owner.ActorLocation + (Comp.WorldRotation.ForwardVector * -Comp.OverrideEdgeClearanceValue) + (Comp.Owner.ActorUpVector * 25), FLinearColor::Yellow, bCenterText = true);
		}

		//Do we have a launchDirection
		if (Comp.bUsePreferedDirection)
		{
			FVector LaunchDirection = Comp.Owner.ActorTransform.TransformVector(FVector(Comp.PreferedDirection.X, Comp.PreferedDirection.Y, 0.0));

			if(LaunchDirection.Size() <= 0.0)
				return;

			//Calculate and show the Angles and ArcNormals for Launch assistance
			FVector RightNormal;
			FVector UpNormal;
			if(LaunchDirection.DotProduct(Comp.UpVector) == 1 || LaunchDirection.DotProduct(Comp.UpVector) == -1)
			{
				UpNormal = LaunchDirection.CrossProduct(Comp.RightVector);
				RightNormal = UpNormal.CrossProduct(LaunchDirection);
			}
			else
			{
				RightNormal = LaunchDirection.CrossProduct(Comp.UpVector);
				UpNormal = RightNormal.CrossProduct(LaunchDirection);
			}

			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.AcceptanceDegrees, Radius = Comp.ActivationRange, Direction = -LaunchDirection.GetSafeNormal(), Normal = UpNormal.GetSafeNormal(), Color = FLinearColor::Yellow, Thickness = 4);
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.AcceptanceDegrees, Radius = Comp.ActivationRange, Direction = -LaunchDirection.GetSafeNormal(), Normal = RightNormal.GetSafeNormal(), Color = FLinearColor::Yellow, Thickness = 4);

			//Calculate our handle world location (with Prefered Direction being modified by handle translation further down)
			FVector HandlePosition = Comp.WorldLocation + (Comp.Owner.ActorTransform.TransformVector(FVector(Comp.PreferedDirection.X, Comp.PreferedDirection.Y, Comp.PreferedDirection.Z)));
			//Modify HandleScale based on distance to viewport
			float AssistHandleScale = 0.2 * (EditorViewLocation.Distance(HandlePosition) / (bIsAssistDirectionSelected ? 600 : 450));
	
			UMaterialInterface MeshMat = nullptr;
			if (bIsAssistDirectionSelected)
				MeshMat = Mat_MatSelectedPoint;
			else if (GetHoveredHitProxy() != n"DirectionProxy")
				MeshMat = nullptr;
			else if (GetHoveredHitProxy() == n"DirectionProxy")
				MeshMat = Mat_MatHoveredPoint;

			SetHitProxy(n"DirectionProxy", EVisualizerCursor::CardinalCross);

			DrawMeshWithMaterial(Mesh_DirectionHandle, MeshMat, HandlePosition, Comp.Owner.ActorRotation.Quaternion(), FVector(AssistHandleScale, AssistHandleScale, AssistHandleScale));

			DrawArrow(Comp.WorldLocation,
						Comp.WorldLocation + (Comp.Owner.ActorTransform.TransformVector(Comp.PreferedDirection)),
							FLinearColor::Red, 10.0, 4.0);
			ClearHitProxy();
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

	//Clear Selected bool when unclicking the Widget/Actor
	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsAssistDirectionSelected = false;
		bIsRopeOffsetSelected = false;
		bIsWidgetOffsetSelected = false;
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if(HitProxy.IsEqual(n"DirectionProxy", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsAssistDirectionSelected = true;
			bIsWidgetOffsetSelected = false;
			bIsRopeOffsetSelected = false;
			return true;
		}

		if(HitProxy.IsEqual(n"GrappleHandle", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsRopeOffsetSelected = true;
			bIsWidgetOffsetSelected = false;
			bIsAssistDirectionSelected = false;
			return true;
		}

		if(HitProxy.IsEqual(n"WidgetHandle", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsWidgetOffsetSelected = true;
			bIsRopeOffsetSelected = false;
			bIsAssistDirectionSelected = false;
			return true;
		}

		bIsRopeOffsetSelected = false;
		bIsWidgetOffsetSelected = false;
		bIsAssistDirectionSelected = false;
		return false;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		auto Comp = Cast<UGrappleSlidePointComponent>(EditingComponent);

		if(bIsAssistDirectionSelected)
		{
			//Add the DeltaTranslation from dragging the handle to our prefered Direction (Visualized Arrow End Location)
			Comp.PreferedDirection.X += Comp.Owner.ActorTransform.InverseTransformVector(DeltaTranslate).X;
			Comp.PreferedDirection.Y += Comp.Owner.ActorTransform.InverseTransformVector(DeltaTranslate).Y;
			return true;
		}

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

	//Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Comp = Cast<UGrappleSlidePointComponent>(EditingComponent);

		if(bIsAssistDirectionSelected)
		{
			//Calculate our widget location with addition of prefered direction (which now includes any delta translation from moving the handle)
			OutLocation = Comp.Owner.ActorLocation + (Comp.Owner.ActorTransform.TransformVector(Comp.PreferedDirection));
			return true;
		}

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
		auto Comp = Cast<UGrappleSlidePointComponent>(EditingComponent);

		if(bIsAssistDirectionSelected)
		{
			OutTransform = FTransform(Comp.WorldRotation);
		}
		
		return true;
	}
}
#endif