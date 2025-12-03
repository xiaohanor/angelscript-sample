class UCameraLookTowardsSplineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraChaseAssistance);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UCameraUserComponent CameraUserComp;
	UCameraLookTowardsSplineComponent CameraFollowSplineComp;
	UPlayerMovementComponent MoveComp;

	float LastInputTime = -1;
	FQuat InitialCameraOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraFollowSplineComp = UCameraLookTowardsSplineComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.IsUsingCameraAssist())
			return false;

		if(!CameraFollowSplineComp.HasSplineToFollow())
			return false;

		if(IsInputting())
			return false;

		if(CameraFollowSplineComp.GetSettings().bOnlyTriggerIfCameraFacingInDirection)
		{
			if(!IsCameraFacingSplineDirection())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.IsUsingCameraAssist())
			return true;

		if(!CameraFollowSplineComp.HasSplineToFollow())
			return true;

		if(IsInputting())
			return true;

		if(CameraFollowSplineComp.GetSettings().bOnlyTriggerIfCameraFacingInDirection)
		{
			if(!IsCameraFacingSplineDirection())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		const FQuat CurrentCameraRotation = CameraUserComp.GetDesiredRotation().Quaternion();
		const FQuat SplineCameraRotation = GetSplineCameraRotation();
		InitialCameraOffset = CurrentCameraRotation * SplineCameraRotation.Inverse();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActivelyInputting())
			LastInputTime = -1;
		else if(LastInputTime < 0)
			LastInputTime = Time::RealTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / CameraFollowSplineComp.GetSettings().LerpDuration);
		Alpha = Math::EaseInOut(0, 1, Alpha, CameraFollowSplineComp.GetSettings().EaseInOutExponent);

		const FQuat SplineCameraRotation = GetSplineCameraRotation();
		const FQuat CameraOffset = FQuat::Slerp(InitialCameraOffset, FQuat::Identity, Alpha);

		const FQuat NewCameraRotation =  CameraOffset * SplineCameraRotation;
		CameraUserComp.SetDesiredRotation(NewCameraRotation.Rotator(), this);
	}

	FVector GetSplineDirection() const
	{
		float SplineDistance = CameraFollowSplineComp.GetSpline().GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		FVector Direction = CameraFollowSplineComp.GetSpline().GetWorldForwardVectorAtSplineDistance(SplineDistance + CameraFollowSplineComp.GetSettings().LookAheadDistance);

		switch(CameraFollowSplineComp.GetSettings().Direction)
		{
			case ECameraLookTowardsSplineDirection::Forward:
				return Direction;

			case ECameraLookTowardsSplineDirection::Back:
				return -Direction;

			case ECameraLookTowardsSplineDirection::Closest:
			{
				if(CameraUserComp.ViewRotation.ForwardVector.DotProduct(Direction) > 0)
					return Direction;
				else
					return -Direction;
			}
		}
	}

	FQuat GetSplineCameraRotation() const
	{
		return FQuat::MakeFromXZ(GetSplineDirection(), CameraUserComp.GetActiveCameraYawAxis());
	}

	bool IsActivelyInputting() const
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		return !AxisInput.IsNearlyZero(KINDA_SMALL_NUMBER);
	}

	bool IsInputting() const
	{
		if(IsActivelyInputting())
			return true;

		if(Time::GetRealTimeSince(LastInputTime) < CameraFollowSplineComp.GetSettings().ReturnDelay)
			return true;

		return false;
	}

	bool IsCameraFacingSplineDirection() const
	{
		const FVector CameraForward = CameraUserComp.ViewRotation.ForwardVector;
		const FVector SplineDirection = GetSplineDirection();
		return CameraForward.DotProduct(SplineDirection) > 0;
	}
};