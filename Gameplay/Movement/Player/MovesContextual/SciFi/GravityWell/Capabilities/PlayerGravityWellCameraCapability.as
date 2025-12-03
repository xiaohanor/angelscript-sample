
class UPlayerGravityWellCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::GravityWell);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunCamera);
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 180;

	default DebugCategory = n"Movement";

	UPlayerGravityWellComponent GravityWellComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent User;

	FAcceleratedInputInterruptedDesiredRotation AcceleratedDesiredRotation;
	default AcceleratedDesiredRotation.AcceleratedDuration = 1.5;
	default AcceleratedDesiredRotation.PostInputCooldown = 0.0;
	default AcceleratedDesiredRotation.PostCooldownInputScaleInterp = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		GravityWellComp = UPlayerGravityWellComponent::Get(Player);
		User = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GravityWellComp.ActiveGravityWell == nullptr)
			return false;

		if (!GravityWellComp.Settings.bEnableFollowCamera)
			return false;

		if (GravityWellComp.CurrentState != EPlayerGravityWellState::Movement)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GravityWellComp.ActiveGravityWell == nullptr)
			return true;

		if (!GravityWellComp.Settings.bEnableFollowCamera)
			return true;

		if (GravityWellComp.CurrentState != EPlayerGravityWellState::Movement)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AcceleratedDesiredRotation.Activate(Player.GetCameraDesiredRotation());

		if (GravityWellComp.Settings.CameraSettings != nullptr)
			Player.ApplyCameraSettings(GravityWellComp.Settings.CameraSettings, 1.0, this, SubPriority = 100);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateDesiredRotation(DeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		/*
			- if 0 will look in the direction of the tangent
			- if greater than 0, will look a point ahead of the player.
				Any overshoot to the target will instead be in the launch direction
		*/
		float ToTarget = GravityWellComp.ActiveGravityWell.ExitTargetDistanceAlongSpline - GravityWellComp.DistanceAlongSpline;
		if (GravityWellComp.ActiveGravityWell.Spline.IsClosedLoop() && Math::Abs(ToTarget) > GravityWellComp.ActiveGravityWell.Spline.SplineLength / 2.0)
			ToTarget -= GravityWellComp.ActiveGravityWell.Spline.SplineLength * Math::Sign(ToTarget);

		FRotator DesiredRotation;
		if (GravityWellComp.Settings.CameraLookAtDistance <= 0.0)
		{
			FRotator SplineRotation = GravityWellComp.ActiveGravityWell.Spline.GetWorldRotationAtSplineDistance(GravityWellComp.DistanceAlongSpline).Rotator();
			SplineRotation.Roll = 0.0;
			DesiredRotation = FRotator::MakeFromAxes(SplineRotation.ForwardVector * Math::Sign(ToTarget), SplineRotation.RightVector, SplineRotation.UpVector);
		}
		else
		{
			FVector LookAtLocation;
			if (GravityWellComp.Settings.CameraLookAtDistance >= Math::Abs(ToTarget))
			{
				float Overshoot =  Math::Abs(Math::Abs(ToTarget) - GravityWellComp.Settings.CameraLookAtDistance);
				Overshoot *= 2.0;
				LookAtLocation = GravityWellComp.ActiveGravityWell.ExitDirection.WorldLocation + GravityWellComp.ActiveGravityWell.ExitDirection.ForwardVector * Overshoot;			
			}
			else
			{
				float LookAtDistanceAlongSpline;
				if (GravityWellComp.ActiveGravityWell.Spline.IsClosedLoop())
				{		
					LookAtDistanceAlongSpline = GravityWellComp.DistanceAlongSpline + GravityWellComp.Settings.CameraLookAtDistance * Math::Sign(ToTarget);

					if (LookAtDistanceAlongSpline < 0.0)
						LookAtDistanceAlongSpline += GravityWellComp.ActiveGravityWell.Spline.SplineLength;
					else if (LookAtDistanceAlongSpline > GravityWellComp.ActiveGravityWell.Spline.SplineLength)
						LookAtDistanceAlongSpline -= GravityWellComp.ActiveGravityWell.Spline.SplineLength;
				}
				else
					LookAtDistanceAlongSpline = GravityWellComp.DistanceAlongSpline + GravityWellComp.Settings.CameraLookAtDistance * Math::Sign(ToTarget);

				LookAtLocation = GravityWellComp.ActiveGravityWell.Spline.GetWorldLocationAtSplineDistance(LookAtDistanceAlongSpline);
			}

			FVector ToLookAtLocation = LookAtLocation - Player.ViewLocation;
			ToLookAtLocation.Normalize();
			DesiredRotation = FRotator::MakeFromXZ(ToLookAtLocation, MoveComp.WorldUp);
			DesiredRotation.Pitch += 5.0;

			if (IsDebugActive())
			{
				Debug::DrawDebugSphere(LookAtLocation, 20.0, 12, FLinearColor::Red, 2.0, 0.0);
				Debug::DrawDebugSphere(GravityWellComp.ActiveGravityWell.ExitDirection.WorldLocation, 20.0, 12, FLinearColor::Green, 2.0, 0.0);
			}
		}
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::CameraDirection);		
		FRotator NewDesired = AcceleratedDesiredRotation.Update(User.DesiredRotation, DesiredRotation, Input, DeltaTime);
		User.SetDesiredRotation(NewDesired, this);
	}
}