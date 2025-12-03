class USkylineFauxPhysicsMagnetSnapComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineFauxPhysicsMagnetSnapComponent;

	float Radius = 260.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto MagnetSnapComponent = Cast<USkylineFauxPhysicsMagnetSnapComponent>(Component);

		auto FauxPhysicsAxisRotateComponent = UFauxPhysicsAxisRotateComponent::Get(MagnetSnapComponent.Owner);

		FVector WorldAxis = FauxPhysicsAxisRotateComponent.WorldRotationAxis;

		// Perpendicular is sort of like the "forward" of the rotation, IE the direction when 0 rotation is applied
		// It is sort of arbitrary
		FVector WorldPerpendicular = FauxPhysicsAxisRotateComponent.WorldOriginRotation * FVector::ForwardVector;

		// Oops, seems like our perpendicular is the same as the axis, not allowed. Pick another one
		if (WorldAxis.Equals(WorldPerpendicular))
			WorldPerpendicular = FauxPhysicsAxisRotateComponent.WorldOriginRotation * FVector::UpVector;

		// Then, when an arbitrary vector is chosen, flatten it out to the rotation axis
		WorldPerpendicular = WorldPerpendicular.ConstrainToPlane(WorldAxis).SafeNormal;

		FVector CurrentPerpendicular = FauxPhysicsAxisRotateComponent.CurrentRotationAsQuat * WorldPerpendicular;


		FTransform Transform = FauxPhysicsAxisRotateComponent.WorldTransform;
		FVector Axis = FauxPhysicsAxisRotateComponent.WorldRotationAxis;
		FLinearColor Color = FLinearColor::Green;

		for (auto  SnapPercentage : MagnetSnapComponent.SnapPercentages)
		{
			float SnapAngle = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(FauxPhysicsAxisRotateComponent.ConstrainAngleMin, FauxPhysicsAxisRotateComponent.ConstrainAngleMax), SnapPercentage);

			DrawClampedRotationAxis(FauxPhysicsAxisRotateComponent.WorldLocation, WorldAxis, WorldPerpendicular, SnapAngle - MagnetSnapComponent.SnapAngle, SnapAngle + MagnetSnapComponent.SnapAngle, FLinearColor::Yellow);
		}
	}

	void DrawClampedRotationAxis(FVector Location, FVector Axis, FVector Perpendicular, float MinAngle, float MaxAngle, FLinearColor Color)
	{
		DrawHalfClampedRotationAxis(Location, Axis, Perpendicular, Radius, MaxAngle, Color);
		DrawHalfClampedRotationAxis(Location, Axis, Perpendicular, Radius, MinAngle, Color * 0.4);
	}

	void DrawHalfClampedRotationAxis(FVector Location, FVector Axis, FVector Perpendicular, float RotationRadius, float Angle, FLinearColor Color)
	{
		bool bIsCapped = Angle < 350.0;
		float CappedAngle = Math::Min(Angle, 350.0);

		// Since we're drawing a centered arc, we need to start the arc at the middle
		FVector MiddlePoint = FQuat(Axis, Math::DegreesToRadians(Angle / 2.0)) * Perpendicular;
//		DrawArc(Location, CappedAngle, RotationRadius, MiddlePoint, Color, 5.0, Normal = Axis, Segments = 32, bDrawSides = false);

		// Arrows to show uncapped rotation
		FQuat CapQuat = FQuat(Axis, Math::DegreesToRadians(CappedAngle));

		if (bIsCapped)
		{
			FVector CapDirection = CapQuat * Perpendicular;
			DrawLine(Location + CapDirection * (RotationRadius - 50.0), Location + CapDirection * (RotationRadius + 50.0), Color, 5.0);
		}
		else
		{
			FQuat CapEndQuat = FQuat(Axis, Math::DegreesToRadians(CappedAngle + 5.0 * Math::Sign(CappedAngle)));
			FVector CapStartLocation = Location + (CapQuat * Perpendicular) * RotationRadius;
			FVector CapEndLocation = Location + (CapEndQuat * Perpendicular) * RotationRadius;

			DrawArrow(CapStartLocation, CapEndLocation, Color, 25.0, 5.0);
		}
	}
}

class USkylineFauxPhysicsMagnetSnapComponent : UActorComponent
{
	UFauxPhysicsAxisRotateComponent FauxPhysicsAxisRotateComponent;

	UPROPERTY(EditAnywhere)
	TArray<float> SnapPercentages;

	UPROPERTY(EditAnywhere)
	float SnapForceScale = 20.0;

	UPROPERTY(EditAnywhere)
	float SnapAngle = 15.0;

	float SnapAngleRadians;

	UPROPERTY(EditAnywhere)
	bool bSnapWhenGrabbed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SnapAngleRadians = Math::DegreesToRadians(SnapAngle);

		FauxPhysicsAxisRotateComponent = UFauxPhysicsAxisRotateComponent::Get(Owner);

		auto GravityWhipResponseComponent = UGravityWhipResponseComponent::Get(Owner);
		if (GravityWhipResponseComponent != nullptr)
		{
			GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
			GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		}

		FauxPhysicsAxisRotateComponent.AddTickPrerequisiteComponent(this);
	}

	UFUNCTION()
	private void HandleGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if (!bSnapWhenGrabbed)
			SetComponentTickEnabled(false);
	}

	UFUNCTION()
	private void HandleReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		if (!bSnapWhenGrabbed)
			SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float RotationRadians = Math::DegreesToRadians(FauxPhysicsAxisRotateComponent.ConstrainAngleMax - FauxPhysicsAxisRotateComponent.ConstrainAngleMin);
		float CurrentRotation = FauxPhysicsAxisRotateComponent.CurrentRotation;

		float Value = Math::NormalizeToRange(Math::RadiansToDegrees(FauxPhysicsAxisRotateComponent.CurrentRotation), FauxPhysicsAxisRotateComponent.ConstrainAngleMin, FauxPhysicsAxisRotateComponent.ConstrainAngleMax);

	//	PrintToScreen("Value: " + Value, 0.0, FLinearColor::Green);
	//	PrintToScreen("RotationRadians: " + RotationRadians, 0.0, FLinearColor::Green);
	//	PrintToScreen("CurrentRotation: " + CurrentRotation, 0.0, FLinearColor::Green);

		for (auto SnapPercentage : SnapPercentages)
		{
			float SnapRadian = Math::DegreesToRadians(Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(FauxPhysicsAxisRotateComponent.ConstrainAngleMin, FauxPhysicsAxisRotateComponent.ConstrainAngleMax), SnapPercentage));

		//	PrintToScreen("SnapRadian: " + SnapRadian, 0.0, FLinearColor::Green);

			if (CurrentRotation > SnapRadian - SnapAngleRadians && CurrentRotation < SnapRadian + SnapAngleRadians)
			{
				float SnapForce = (SnapRadian - CurrentRotation) * SnapForceScale;
			//	PrintToScreen("SnapForce: " + SnapForce, 0.0, FLinearColor::Green);
				FauxPhysicsAxisRotateComponent.ApplyAngularForce(SnapForce);
			}
		}
	}
}