#if EDITOR
class ULaunchKiteScriptVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = ULaunchKitePointComponent;

	UStaticMesh Mesh_DirectionHandle;
	UMaterialInterface Mat_MatSelectedPoint;
	UMaterialInterface Mat_MatHoveredPoint;

	bool bIsHandleSelected = false;

	void PrepareAssets()
	{
		Mesh_DirectionHandle = Cast<UStaticMesh>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point.SplineEditor_Point"));
		Mat_MatSelectedPoint = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Selected_Material.SplineEditor_Point_Selected_Material"));
		Mat_MatHoveredPoint = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/SplineEditor/SplineEditor_Point_Hovered_Material.SplineEditor_Point_Hovered_Material"));
	}

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        ULaunchKitePointComponent Comp = Cast<ULaunchKitePointComponent>(Component);
        if (Comp == nullptr)
            return;

		SetRenderForeground(false);
		PrepareAssets();

		VisualizeLaunchTrajectory(Comp);
    }
	
	void VisualizeLaunchTrajectory(ULaunchKitePointComponent Comp)
	{
		FVector LaunchLocation = Comp.WorldLocation + (Comp.ForwardVector * 1800.0);

		FVector LaunchDirection = Comp.ForwardVector;

		FVector Location = LaunchLocation;
		FVector Velocity = LaunchDirection * Comp.FlightVelocity;
		float Time = 0.0;

		FVector PrevLineLocation = Location;
		FVector WorldUp = Comp.UpVector;

		FVector Gravity = -WorldUp * 2385.0;
		const float DragMaxSpeed = 600.0;
		const float DragAmount = 0.0;

		while (Time < 5.0)
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
}
#endif