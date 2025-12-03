
#if EDITOR
class UAutoAimTargetVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UAutoAimTargetComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UAutoAimTargetComponent AimComp = Cast<UAutoAimTargetComponent>(Component);
		
		// happens on teardown on the dummy component
		if(AimComp == nullptr)
			return;

        if (AimComp.GetOwner() == nullptr)
            return;

		DrawPoint(AimComp.WorldLocation, FLinearColor::Green, 20.0);

        FVector EditorCamera = EditorViewLocation;
        float Distance = EditorCamera.Distance(AimComp.WorldLocation);

        float Radius = Math::Tan(Math::DegreesToRadians(AimComp.CalculateAutoAimMaxAngle(Distance))) * Distance;
		if (!AimComp.TargetShape.IsZeroSize())
		{
			Radius += AimComp.TargetShape.GetEncapsulatingSphereRadius();
			switch (AimComp.TargetShape.Type)
			{
				case EHazeShapeType::Box:
					DrawWireBox(
						AimComp.WorldLocation,
						AimComp.TargetShape.BoxExtents,
						AimComp.ComponentQuat,
						FLinearColor::Green,
						2.0
					);
				break;
				case EHazeShapeType::Sphere:
					DrawWireSphere(
						AimComp.WorldLocation,
						AimComp.TargetShape.SphereRadius,
						FLinearColor::Green,
					);
				break;
				case EHazeShapeType::Capsule:
					DrawWireCapsule(
						AimComp.WorldLocation,
						AimComp.WorldRotation,
						FLinearColor::Green,
						AimComp.TargetShape.CapsuleRadius,
						AimComp.TargetShape.CapsuleHalfHeight,
						16, 2.0
					);
				break;
				case EHazeShapeType::None:
				break;
			}
		}

        DrawWireSphere(AimComp.WorldLocation, Radius, Color = FLinearColor::Blue);

		if(AimComp.bOnlyValidIfAimOriginIsWithinAngle)
		{
			DrawArrow(AimComp.WorldLocation, AimComp.WorldLocation + AimComp.ForwardVector * 100.0, FLinearColor::Red);
			DrawCone(AimComp.WorldLocation, AimComp.ForwardVector, AimComp.MaxAimAngle, Color = FLinearColor::Yellow);
		}

		if(AimComp.bDrawMinimumAndMaximumDistance)
		{
			if(AimComp.MinimumDistance > KINDA_SMALL_NUMBER)
				DrawWireSphere(AimComp.WorldLocation, AimComp.MinimumDistance, FLinearColor::Yellow, 2.0, 24);
			
			DrawWireSphere(AimComp.WorldLocation, AimComp.MaximumDistance, FLinearColor::Red, 5.0, 24);
		}
    }   

	void DrawCone(FVector Origin, FVector Direction, float ConeAngle, float Radius = 250, FLinearColor Color = FLinearColor::White)
	{
		float ConeRadians = Math::DegreesToRadians(ConeAngle);

		// Construct perpendicular vector
		FVector P1 = Direction.CrossProduct(Direction.GetAbs().Equals(FVector::UpVector) ? FVector::RightVector : FVector::UpVector);
		P1.Normalize();

		FVector P2 = P1.CrossProduct(Direction);

		// Draw cone sides
		FVector Tip = Direction * Radius;
		FVector TiltedTip = FQuat(P1, ConeRadians) * Tip;
		FVector ConeBase = Direction * Math::Cos(ConeRadians) * Radius;

		float StepRadians = TWO_PI / 10;

		for(int i = 0; i < 10; ++i)
		{
			float Angle = i * StepRadians;
			FVector StepTip = FQuat(Direction, Angle) * TiltedTip;

			DrawDashedLine(Origin, Origin + StepTip, Color);
		}

		// Draw tip circle
		DrawCircle(Origin + ConeBase, Math::Sin(ConeRadians) * Radius, Color, 2.0, Direction);

		// Draw rotational arcs
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, Color, 2.0, P1, bDrawSides = false);
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, Color, 2.0, P2, bDrawSides = false);
	}
} 
#endif