#if EDITOR
class UGrappleLaunchPointScriptVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGrappleLaunchPointComponent;

	UStaticMesh Mesh_DirectionHandle;
	UStaticMesh Mesh_GrappleHook;
	UMaterialInterface Mat_MatSelectedPoint;
	UMaterialInterface Mat_MatHoveredPoint;

	bool bIsLaunchDirectionSelected = false;
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
        UGrappleLaunchPointComponent Comp = Cast<UGrappleLaunchPointComponent>(Component);
        if (Comp == nullptr)
            return;

		SetRenderForeground(false);
		PrepareAssets();

		auto VisSubsys = UEditorVisualizationSubsystem::Get();
		FTransform Transform = Comp.Owner.ActorTransform;
		Transform.Location = Transform.Location + Transform.TransformVector(Comp.RopeAttachOffset) + (Comp.GrappleRotation.ForwardVector * -10);
		Transform.Rotation = Comp.GrappleRotation;
		Transform.Scale3D = FVector(1.5, 1, 1);
		VisSubsys.DrawMesh(this, Transform, Mesh_GrappleHook);

		UMaterialInterface LaunchDirectionMat = nullptr;
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

		//Do we have a launch target direction
		if (Comp.bUsePreferredDirection)
		{
			FVector LaunchDirection = Comp.Owner.ActorTransform.TransformVector(Comp.PreferredDirection.GetSafeNormal());

			if (LaunchDirection.Size() <= 0.0)
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

			DrawArc(Comp.WorldLocation + (Comp.UpVector * Comp.LaunchHeightOffset), Angle = 2 * Comp.AcceptanceDegrees, Radius = Comp.ActivationRange, Direction = -LaunchDirection.GetSafeNormal(), Normal = UpNormal.GetSafeNormal(), Color = FLinearColor::Yellow, Thickness = 4);
			DrawArc(Comp.WorldLocation + (Comp.UpVector * Comp.LaunchHeightOffset), Angle = 2 * Comp.AcceptanceDegrees, Radius = Comp.ActivationRange, Direction = -LaunchDirection.GetSafeNormal(), Normal = RightNormal.GetSafeNormal(), Color = FLinearColor::Yellow, Thickness = 4);

			//Calculate our handle world location (with Prefered Direction being modified by handle translation further down)
			FVector HandlePosition = Comp.WorldLocation + (Comp.UpVector * Comp.LaunchHeightOffset) + (Comp.Owner.ActorTransform.TransformVector(Comp.PreferredDirection));
			//Modify HandleScale based on distance to viewport
			float LaunchHandleScale = 0.2 * (EditorViewLocation.Distance(HandlePosition) / (bIsLaunchDirectionSelected ? 600 : 450));

			if (bIsLaunchDirectionSelected)
				LaunchDirectionMat = Mat_MatSelectedPoint;
			else if (GetHoveredHitProxy() != n"DirectionProxy")
				LaunchDirectionMat = nullptr;
			else if (GetHoveredHitProxy() == n"DirectionProxy")
				LaunchDirectionMat = Mat_MatHoveredPoint;

			SetHitProxy(n"DirectionProxy", EVisualizerCursor::CardinalCross);
				DrawMeshWithMaterial(Mesh_DirectionHandle, LaunchDirectionMat, HandlePosition, Comp.Owner.ActorRotation.Quaternion(), FVector(LaunchHandleScale, LaunchHandleScale, LaunchHandleScale));
				DrawArrow(Comp.WorldLocation + (Comp.UpVector * Comp.LaunchHeightOffset),
							Comp.WorldLocation + (Comp.UpVector * Comp.LaunchHeightOffset) + (Comp.Owner.ActorTransform.TransformVector(Comp.PreferredDirection)),
								FLinearColor::Red, 10.0, 4.0);
			DrawWorldString("LaunchDirection", HandlePosition + (Comp.Owner.ActorRotation.UpVector * 15), bIsLaunchDirectionSelected ? FLinearColor::Green : FLinearColor::Yellow, 1.5, bCenterText = true);
			ClearHitProxy();
		}

		if (Comp.bVisualizeLaunchTrajectory && Comp.bUsePreferredDirection)
			VisualizeLaunchTrajectory(Comp);

		//If we modified the launch height then show a representation of the player capsule size
		if (Comp.LaunchHeightOffset != 0)
		{
			DrawWireCapsule(Comp.WorldLocation + (Comp.UpVector * (Comp.LaunchHeightOffset)), Comp.Owner.ActorRotation, Color = FLinearColor::LucBlue, NumSides = 16 ,HalfHeight = 82, Thickness = 3);
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
	
	void VisualizeLaunchTrajectory(UGrappleLaunchPointComponent Comp)
	{
		FVector LaunchLocation = Comp.WorldLocation + Comp.UpVector * (Comp.LaunchHeightOffset - 82.0);

		FVector LaunchDirection = Comp.Owner.ActorTransform.TransformVector(Comp.PreferredDirection.GetSafeNormal());
		if (!Comp.bUsePreferredDirection)
			LaunchDirection = Comp.ForwardVector;

		FVector Location = LaunchLocation;
		FVector Velocity = LaunchDirection * Comp.LaunchVelocity;
		float Time = 0.0;

		FVector PrevLineLocation = Location;
		FVector WorldUp = Comp.UpVector;

		FVector Gravity = -WorldUp * 2385.0;
		const float DragMaxSpeed = 600.0;
		const float DragAmount = 250.0;

		while (Time < Comp.VisualizeLaunchTrajectoryDuration)
		{
			const float DeltaTime = 1.0 / 30.0;

			FVector HorizontalVelocity = Velocity.ConstrainToPlane(WorldUp);

			float VelocitySize = HorizontalVelocity.Size();
			if (VelocitySize > DragMaxSpeed)
			{
				VelocitySize = Math::Max(DragMaxSpeed, VelocitySize - (DragAmount * DeltaTime));
				HorizontalVelocity = HorizontalVelocity.GetSafeNormal() * VelocitySize;
			}

			FVector VerticalVelocity = Velocity.ConstrainToDirection(WorldUp);

			FVector NewLocation = Location;
			NewLocation += HorizontalVelocity * DeltaTime;
			NewLocation += VerticalVelocity * DeltaTime;
			NewLocation += Gravity * (DeltaTime * DeltaTime * 0.5);

			FVector NewVelocity = HorizontalVelocity + VerticalVelocity;
			NewVelocity += Gravity * DeltaTime;

			if (!PrevLineLocation.Equals(NewLocation, 5.0))
			{
				FVector Margin = (PrevLineLocation - NewLocation).GetSafeNormal() * 16.0;
				DrawLine(PrevLineLocation, NewLocation + Margin, ColorDebug::Fuchsia, 4.0);
				PrevLineLocation = NewLocation;
			}

			Time += DeltaTime;
			Velocity = NewVelocity;
			Location = NewLocation;
		}
	}

	//Clear Selected bool when unclicking the widget / Actor
	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsLaunchDirectionSelected = false;
		bIsRopeOffsetSelected = false;
		bIsWidgetOffsetSelected = false;
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if(HitProxy.IsEqual(n"DirectionProxy", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsLaunchDirectionSelected = true;
			bIsWidgetOffsetSelected = false;
			bIsRopeOffsetSelected = false;
			return true;
		}
		else if(HitProxy.IsEqual(n"GrappleHandle", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsRopeOffsetSelected = true;
			bIsWidgetOffsetSelected = false;
			bIsLaunchDirectionSelected = false;
			return true;
		}
		else if(HitProxy.IsEqual(n"WidgetHandle", bCompareNumber = false))
		{
			//assign internal selection bool if any of the Assigned drawn proxy visualizers were clicked with the corresponding FName
			bIsWidgetOffsetSelected = true;
			bIsRopeOffsetSelected = false;
			bIsLaunchDirectionSelected = false;
			return true;
		}

		bIsRopeOffsetSelected = false;
		bIsWidgetOffsetSelected = false;
		bIsLaunchDirectionSelected = false;
		return false;
	}

	// Used by the editor when the transform gizmo is moved while we are overriding it
	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		auto Comp = Cast<UGrappleLaunchPointComponent>(EditingComponent);

		if(bIsLaunchDirectionSelected)
		{
			//Add the DeltaTranslation from draggin the handle to our Prefered Direction (visualized arrow end location)
			Comp.PreferredDirection += Comp.Owner.ActorTransform.InverseTransformVector(DeltaTranslate);
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

	// Used by the editor to determine where the transform gizmo ends up
	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto Comp = Cast<UGrappleLaunchPointComponent>(EditingComponent);
		//Calculate our widget location with addition of prefered direction (which now includes any delta translation from moving the widget)
		if(bIsLaunchDirectionSelected)
		{
			OutLocation = Comp.Owner.ActorLocation + (Comp.UpVector * Comp.LaunchHeightOffset) + (Comp.Owner.ActorTransform.TransformVector(Comp.PreferredDirection));
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
		auto Comp = Cast<UGrappleLaunchPointComponent>(EditingComponent);

		if(bIsLaunchDirectionSelected)
		{
			OutTransform = FTransform(Comp.WorldRotation);
		}
		
		return true;
	}
}
#endif