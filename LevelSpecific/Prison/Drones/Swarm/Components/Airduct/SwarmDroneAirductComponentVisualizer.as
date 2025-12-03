class USwarmDroneAirductComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USwarmDroneAirductComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USwarmDroneAirductComponent AirductComponent = Cast<USwarmDroneAirductComponent>(Component);
		if (AirductComponent == nullptr)
			return;

		// Visualize movement zone (since we are overriding visualizer)
		VisualizeMovementZone(AirductComponent.Shape.CollisionShape, AirductComponent.WorldTransform, FLinearColor::Green, 3.0);

		// Join both ends
		// DrawDashedLine(AirductComponent.GetWorldIntakeLocation(), AirductComponent.GetWorldExhaustLocation(), FLinearColor::LucBlue, 10.0, 2.0, true);

		// Draw exhaust stuff
		FTransform WorldExhaust = AirductComponent.GetWorldExhaustTransform();
		FVector Gravity = -FVector::UpVector * Drone::Gravity;
		FVector Velocity = WorldExhaust.Rotation.ForwardVector * AirductComponent.ExhaustForce;
		Trajectory::FTrajectoryPoints Points = Trajectory::CalculateTrajectory(WorldExhaust.Location, AirductComponent.ExhaustForce, Velocity, Gravity.Size(), 4.0, -1.0, -Gravity.GetSafeNormal());

		for(int i=0; i<Points.Positions.Num() - 1; ++i)
		{
			FVector Start = Points.Positions[i];
			FVector End = Points.Positions[i + 1];

			DrawDashedLine(Start, End, FLinearColor::DPink, 20.0, 2.0, true);
		}
	}

	void VisualizeMovementZone(FCollisionShape Shape, FTransform Transform, FLinearColor Color, float Thickness)
	{
		FVector CenterPos = Transform.GetLocation();

		if(Shape.IsBox())
		{
			FBox BoxShape = FBox(-Shape.GetBox(), Shape.GetBox());
			DrawWireBox(Transform.Location, Shape.Box, Transform.Rotation, Color, Thickness, false);
		}
		else if(Shape.IsSphere())
		{
			DrawWireSphere(Transform.Location, Shape.SphereRadius, Color, Thickness, 16, false);
		}
		else if(Shape.IsCapsule())
		{
			DrawWireCapsule(CenterPos, Transform.Rotator(), Color, Shape.CapsuleRadius, Shape.CapsuleHalfHeight, 16, Thickness, false);
		}
	}
}