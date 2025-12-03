/**
 * This camera is meant to be used when we are locked on a spline,
 * it faces the spline direction while allowing some relative input from the player
 */
class UJetskiSplineCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(Jetski::Tags::JetskiSplineCamera);

	default DebugCategory = CameraTags::Camera;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AJetski Jetski;
	FHazeAcceleratedRotator AccCameraRotation;
	UCameraUserComponent CameraUser;

	float NoInputDuration = 0.0;
	FHazeAcceleratedRotator AccRelativeCameraRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Jetski = Cast<AJetski>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Jetski.Settings.CameraMode != EJetskiCameraMode::Spline)
			return false;

		if(Jetski.GetActiveSplineComponent() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Jetski.Settings.CameraMode != EJetskiCameraMode::Spline)
			return true;

		if(Jetski.GetActiveSplineComponent() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CameraUser = UCameraUserComponent::Get(Jetski.Driver);
		FRotator CameraRotation = GetSplineCameraRotation();
		AccCameraRotation.SnapTo(CameraRotation);
		CameraUser.SetInputRotation(CameraRotation, this);

		Jetski.Driver.BlockCapabilities(CameraTags::CameraControl, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Jetski.Driver.UnblockCapabilities(CameraTags::CameraControl, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		UpdateInputDuration(DeltaTime);

		FRotator CameraRotation = GetSplineCameraRotation();
		AccCameraRotation.AccelerateTo(CameraRotation, 1.0, DeltaTime);

		if(Jetski.Settings.bSplineCameraAllowInput)
		{
			if(IsInputting())
			{
				const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
				AccRelativeCameraRotation.AccelerateTo(FRotator(AxisInput.Y * Jetski.Settings.SplineCameraInputPitch, AxisInput.X * Jetski.Settings.SplineCameraInputYaw, 0), 1, DeltaTime);
			}
			else
			{
				AccRelativeCameraRotation.AccelerateTo(FRotator::ZeroRotator, 1, DeltaTime);
			}

			CameraRotation = AccCameraRotation.Value + AccRelativeCameraRotation.Value;
		}
		else
		{
			CameraRotation = AccCameraRotation.Value;
		}

		CameraUser.SetInputRotation(CameraRotation, this);
	}
	
	void UpdateInputDuration(float DeltaTime)
	{
		if (IsActivelyInputting())
			NoInputDuration = 0.0;
		else
			NoInputDuration += DeltaTime;
	}

	bool IsActivelyInputting() const
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		return !AxisInput.IsNearlyZero(0.001);
	}

	bool IsInputting() const
	{
		return NoInputDuration < Jetski.Settings.SplineCameraInputDelay;
	}

	FRotator GetSplineCameraRotation() const
	{
		const UHazeSplineComponent SplineComp = Jetski.GetActiveSplineComponent();

		const float CurrentDistanceAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(Jetski.ActorLocation);
		
		if(Jetski.Settings.bSplineCameraUseSplineDirection)
		{
			float CameraDistanceAlongSpline = CurrentDistanceAlongSpline + Jetski.Settings.SplineCameraDirectionLead;
			FRotator CameraRotation = SplineComp.GetWorldRotationAtSplineDistance(CameraDistanceAlongSpline).Rotator();
			if(Jetski.MoveComp.IsInAir())
			{
				FRotator VelocityDirection = FRotator::MakeFromXZ(Jetski.MoveComp.Velocity, Jetski.GetUpVector(EJetskiUp::Accelerated));
				FRotator RelativeToBikeRotation = CameraRotation - VelocityDirection;
				RelativeToBikeRotation.Pitch *= 0.5;
				return RelativeToBikeRotation + VelocityDirection;
			}
			else
			{
				FRotator RelativeToBikeRotation = CameraRotation - Jetski.ActorRotation;
				RelativeToBikeRotation.Pitch = 0;
				return RelativeToBikeRotation + Jetski.ActorRotation;
			}
		}
		else
		{
			float CameraDistanceAlongSpline = CurrentDistanceAlongSpline + Jetski.Settings.SplineCameraLookLeadAmount;
			FTransform TargetTransform = SplineComp.GetWorldTransformAtSplineDistance(CameraDistanceAlongSpline);
			FVector TargetLocation = TargetTransform.Location;
			TargetLocation += TargetTransform.Rotation.RightVector * Jetski.GetSideDistance(false);

			FRotator CameraRotation = FRotator::MakeFromX(TargetLocation - Jetski.Driver.ViewLocation);
			return CameraRotation;
		}
	}
}