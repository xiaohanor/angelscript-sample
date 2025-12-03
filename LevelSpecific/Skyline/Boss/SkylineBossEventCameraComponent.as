class USkylineBossEventCameraComponent : UHazeCameraComponent
{
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedQuat AccRotation;

	USceneComponent TargetComponent;
	FVector Offset;

	UHazeSplineComponent Spline;
	FSplinePosition SplinePosition;
	FHazeAcceleratedFloat AccSplineSpeed;
	float SplineSpeed = 5000.0;

	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DetachFromParent();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActivated)
			return;

		AccSplineSpeed.AccelerateTo(SplineSpeed, 2.0, DeltaSeconds);

		SplinePosition.Move(AccSplineSpeed.Value * DeltaSeconds);

		FVector ToFocusTarget = TargetComponent.WorldLocation - SplinePosition.WorldLocation;

//		AccLocation.AccelerateTo(TargetComponent.WorldTransform.TransformPositionNoScale(Offset), 1.0, DeltaSeconds);
		AccLocation.AccelerateTo(SplinePosition.WorldLocation, 0.5, DeltaSeconds);
		AccRotation.AccelerateTo(ToFocusTarget.ToOrientationQuat(), 1.0, DeltaSeconds);

		SetWorldLocationAndRotation(
			AccLocation.Value,
			AccRotation.Value
		);
	}

	void SetFocusTarget(USceneComponent SceneComponent)
	{
		TargetComponent = SceneComponent;
		Offset = TargetComponent.WorldTransform.InverseTransformPositionNoScale(WorldLocation);
	}

	void SetFollowSpline(UHazeSplineComponent FollowSpline)
	{
		Spline = FollowSpline;
		SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
	}

	UFUNCTION()
	void ActivateEventCamera(FInstigator Instigator, float BlendTime = 0.0)
	{
		AccSplineSpeed.SnapTo(0.0, 0.0);
		SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);

		FVector ToFocusTarget = TargetComponent.WorldLocation - SplinePosition.WorldLocation;

		AccLocation.SnapTo(SplinePosition.WorldLocation);
		AccRotation.SnapTo(ToFocusTarget.ToOrientationQuat());

		for (auto Player : Game::Players)
		{
			Player.ActivateCamera(this, BlendTime, Instigator);
		}

		bIsActivated = true;
	}

	UFUNCTION()
	void DeactivateEventCamera(FInstigator Instigator, float BlendTime = -1.0)
	{
		for (auto Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(Instigator, BlendTime);
		}		

		bIsActivated = false;
	}
};