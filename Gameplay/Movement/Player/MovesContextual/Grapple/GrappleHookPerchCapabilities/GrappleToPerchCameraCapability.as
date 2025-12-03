asset PlayerGrappleToPerchSplineCameraBlendIn of UCameraDefaultBlend
{
	AlphaType = ECameraBlendAlphaType::Accelerated;
	bIncludeLocationVelocity = true;
	LocationVelocityCustomBlendType = ECameraDefaultBlendVelocityAlphaType::Accelerated;
}

asset PlayerGrappleToPerchSplineCameraBlendOut of UCameraDefaultBlend
{
	AlphaType = ECameraBlendAlphaType::Accelerated;
}

struct FGrapplePerchSplineCameraActivationParams
{
	UPerchPointComponent PerchPoint;
}

class UGrappleToPerchCameraCapability : UHazePlayerCapability
{	
	/*
	*Rename to perch spline camera behavior?
	* if pitch is aiming upwards then maybe we should orient that slightly above floor aligned angle aswell?
	*/

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrapplePerch);
	default CapabilityTags.Add(PlayerGrappleTags::GrapplePerchSplineCamera);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	UCameraUserComponent User;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerPerchComponent PerchComp;

	FHazeAcceleratedRotator AcceleratedDesiredRotation;

	float Duration = 2;
	FRotator TargetDesired;
	FVector InitialForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		User = UCameraUserComponent::Get(Owner);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGrapplePerchSplineCameraActivationParams& Params) const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())	
			return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrapplePerch)
			return false;
		
		UPerchPointComponent PerchPoint = Cast<UPerchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		if (PerchPoint == nullptr || !PerchPoint.bHasConnectedSpline)
			return false;
		
		Params.PerchPoint = PerchPoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		if (Player.IsPlayerDead())
			return true;
		
		FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if((GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrapplePerch && (CameraInput.Size() >= KINDA_SMALL_NUMBER || ActiveDuration >= Duration)))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGrapplePerchSplineCameraActivationParams Params)
	{
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
		AcceleratedDesiredRotation.SnapTo(Player.GetCameraDesiredRotation());
		Player.ApplyBlendToCurrentView(1, PlayerGrappleToPerchSplineCameraBlendIn);

		UHazeSplineComponent Spline = Params.PerchPoint.ConnectedSpline.Spline;
		FVector TargetLocation = Params.PerchPoint.WorldLocation;
		
		FVector ToTargetPointFlattened = (TargetLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
		InitialForward = User.GetActiveCameraRotation().ForwardVector;
		
		//We probably need to sign forward here to align with our forward aswell so we know which forward to align with if we dont hit perpendicular
		FVector SplineForward = Spline.GetWorldForwardVectorAtSplineDistance(Spline.GetClosestSplineDistanceToWorldLocation(TargetLocation));
		FVector SplinePerpendicularDirection = SplineForward.CrossProduct(MoveComp.WorldUp);

		if (SplinePerpendicularDirection.DotProduct(ToTargetPointFlattened.GetSafeNormal()) < 0)
			SplinePerpendicularDirection *= -1;

		//Check angular distance
		float AngularDistance = SplinePerpendicularDirection.GetAngleDegreesTo(ToTargetPointFlattened.GetSafeNormal());

		const float PerpendicularMaxAngle = 40;
		if(Math::Abs(AngularDistance) <= PerpendicularMaxAngle)
		{
			TargetDesired = FRotator::MakeFromXZ(SplinePerpendicularDirection, MoveComp.WorldUp);
			TargetDesired.Pitch = User.GetActiveCameraRotation().Pitch;
		}
		else
		{
			//Identify spline direction and modify our target desired to that
			if(SplineForward.DotProduct(ToTargetPointFlattened) >= 0)
			{
				TargetDesired = FRotator::MakeFromXZ(SplineForward, MoveComp.WorldUp);
				TargetDesired.Pitch = User.GetActiveCameraRotation().Pitch;
			}
			else
			{
				TargetDesired = FRotator::MakeFromXZ(SplineForward * -1, MoveComp.WorldUp);
				TargetDesired.Pitch = User.GetActiveCameraRotation().Pitch;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CameraDeltaTime = Time::GetCameraDeltaSeconds();
		UpdateDesiredRotation(CameraDeltaTime);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{
		FRotator NewDesiredRotation = AcceleratedDesiredRotation.AccelerateTo(TargetDesired, Duration, DeltaTime);
		
		User.SetDesiredRotation(NewDesiredRotation, this);
	}
};