class USkylineBossTankTurretComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBossTankTurretComponent;

	int VisualizationResolution = 128; 
	float VisualizationRadius = 500.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		auto TurretComp = Cast<USkylineBossTankTurretComponent>(InComponent);
	
		float YawAngle = -180.0;
		float AngleStep = 360.0 / VisualizationResolution;

		for (int i = 0; i < VisualizationResolution; i++)
		{
			float PitchAngle = TurretComp.PitchClampCurve.GetFloatValue(Math::Abs(YawAngle + (i * AngleStep)));

			FVector Point = TurretComp.ForwardVector * VisualizationRadius;
			Point = Point.RotateAngleAxis(YawAngle + (i * AngleStep), TurretComp.UpVector);
			Point = Point.RotateAngleAxis(PitchAngle, Point.CrossProduct(TurretComp.UpVector).SafeNormal);

//			DrawPoint(TurretComp.WorldTransform.TransformPositionNoScale(Point), FLinearColor::Green, 10.0);
			DrawPoint(TurretComp.WorldLocation + Point, FLinearColor::Green, 10.0);
		}
	}
}

class USkylineBossTankTurretComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve PitchClampCurve;

	UPROPERTY(EditAnywhere)
	float MaxTurnSpeedDeg = 180.0;

	FTransform InitialRelativeTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRelativeTransform = RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	FQuat ClampAndSetRotation(FQuat Rotation)
	{
		FRotator NewRelativeRotation = AttachParent.WorldTransform.InverseTransformRotation(Rotation.Rotator());

		float Angle = NewRelativeRotation.Yaw;
		float Pitch = PitchClampCurve.GetFloatValue(Math::Abs(Angle));
//		PrintToScreen("TurretAngle: " + Angle, 0.0, FLinearColor::Green);
		PrintToScreen("TurretPitchClamp: " + Pitch, 0.0, FLinearColor::Green);

		NewRelativeRotation.Pitch = Math::Clamp(NewRelativeRotation.Pitch, Pitch, 90.0);

		return AttachParent.WorldTransform.TransformRotation(NewRelativeRotation).Quaternion();
	}
};