struct FGravityWhipSlingObjectMovementState
{
	UGravityWhipResponseComponent ResponseComp;
	FHazeAcceleratedVector GrabLocation;
	FHazeAcceleratedQuat GrabRotation;
}

class UGravityWhipSlingObjectMovementCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::PostWork;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UGravityWhipUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerMovementComponent MoveComp;

	FVector2D AimValues;
	TMap<UGravityWhipResponseComponent, FGravityWhipSlingObjectMovementState> ObjectStates;

	FTransform LastReferenceTransform;
	USceneComponent LastReferenceComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.GetPrimaryGrabMode() != EGravityWhipGrabMode::Sling)
			return false;
		if (!UserComp.HasActiveGrab())
			return false;
		if (!AimComp.IsAiming(UserComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.GetPrimaryGrabMode() != EGravityWhipGrabMode::Sling)
			return true;
		if (!UserComp.HasActiveGrab())
			return true;
		if (!AimComp.IsAiming(UserComp))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto& Elem : ObjectStates)
		{
			if (IsValid(Elem.Value.ResponseComp))
			{
				auto Character = Cast<AHazeCharacter>(Elem.Value.ResponseComp.Owner);
				if (Character != nullptr)
					Character.CapsuleComponent.ClearCollisionProfile(this);
				else
					Elem.Value.ResponseComp.Owner.RemoveActorCollisionBlock(this);
			}
		}

		ObjectStates.Reset();

		LastReferenceTransform = FTransform::Identity;
		LastReferenceComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!AimComp.IsAiming(UserComp))
			return;

		auto AimResult = AimComp.GetAimingTarget(UserComp);
		
		FVector AimLocation;
		UserComp.QueryWithRay(AimResult.AimOrigin, AimResult.AimDirection, GravityWhip::Grab::AimTraceRange, AimLocation);

		auto Follow = MoveComp.GetCurrentMovementFollowAttachment();
		FTransform ReferenceTransform;
		if (Follow.Component != nullptr)
			ReferenceTransform = Follow.Component.GetWorldTransform();

		// Move to very nice point :tm:
		const FTransform SlingOrigin = UserComp.GetSlingOrigin();

		// Debug::DrawDebugSphere(Player.Mesh.GetSocketLocation(n"Align"));

		int GrabCount = 0;
		for (const FGravityWhipUserGrab& Grab : UserComp.Grabs)
		{
			if (!Grab.bHasTriggeredResponse)
				continue;

			FGravityWhipSlingObjectMovementState& State = ObjectStates.FindOrAdd(Grab.ResponseComponent);
			if (State.ResponseComp == nullptr)
			{
				State.ResponseComp = Grab.ResponseComponent;
				State.GrabLocation.SnapTo(Grab.ResponseComponent.Owner.ActorLocation);
				State.GrabRotation.SnapTo(Grab.ResponseComponent.Owner.ActorQuat);

				auto Character = Cast<AHazeCharacter>(State.ResponseComp.Owner);
				if (Character != nullptr)
					Character.CapsuleComponent.ApplyCollisionProfile(n"OverlapAllDynamic", this, Priority = EInstigatePriority::Override);
				else
					Grab.ResponseComponent.Owner.AddActorCollisionBlock(this);
			}

			if (!IsValid(State.ResponseComp))
				continue;

			float OffsetRadius = State.ResponseComp.OffsetRadius;

			float OffsetAngle = Math::RadiansToDegrees((PI * 2.0) / ObjectStates.Num()) * GrabCount;
			FRotator AimRotation = FRotator::MakeFromXZ(AimResult.AimDirection, Player.MovementWorldUp);
			FQuat SpinRotation = (State.ResponseComp.SpinSpeedWhileSlinging * ActiveDuration).Quaternion();
			FQuat ObjectRotation = AimRotation.Quaternion() * SpinRotation * FQuat::FindBetweenNormals(FVector::ForwardVector, State.ResponseComp.ForwardAxis);

			FVector OffsetDirection = AimRotation.UpVector.RotateAngleAxis(OffsetAngle + 90.0, AimResult.AimDirection);
			FVector DesiredLocation = SlingOrigin.Location + (OffsetDirection * OffsetRadius) + (AimRotation.RightVector * OffsetRadius);

			// Debug::DrawDebugPoint(SlingOrigin.Location, 10, FLinearColor::Red);

			if (Follow.Component == LastReferenceComponent)
			{
				State.GrabLocation.SnapTo(
					ReferenceTransform.TransformPositionNoScale(
						LastReferenceTransform.InverseTransformPositionNoScale(State.GrabLocation.Value)
					),
					ReferenceTransform.TransformVectorNoScale(
						LastReferenceTransform.InverseTransformVectorNoScale(State.GrabLocation.Velocity)
					),
				);
			}

			State.ResponseComp.DesiredLocation = DesiredLocation;
			State.ResponseComp.DesiredRotation = ObjectRotation.Rotator();
			State.ResponseComp.AimLocation = AimLocation;

			float AccDuration = Math::Lerp(
					GravityWhip::Grab::SlingPickupAccelerationDuration,
					GravityWhip::Grab::SlingHoldAccelerationDuration,
					Math::Saturate(ActiveDuration / GravityWhip::Grab::SlingPickupAccelerationDuration - 1.0)
				);
			if (UserComp.bIsSlingThrowing)
				AccDuration = GravityWhip::Grab::SlingThrowAccelerationDuration;

			State.GrabRotation.AccelerateTo(ObjectRotation, AccDuration, DeltaTime);
			State.GrabLocation.AccelerateTo(DesiredLocation, AccDuration, DeltaTime);

			FVector GrabLocation = State.GrabLocation.Value;
			State.ResponseComp.Owner.SetActorLocationAndRotation(
				GrabLocation, State.GrabRotation.Value
			);

			GrabCount += 1;
		}

		LastReferenceTransform = ReferenceTransform;
		LastReferenceComponent = Follow.Component;

		// Animation data
		FVector CenterPointDirection = (UserComp.GrabCenterLocation - AimResult.AimOrigin).GetSafeNormal();
		float X = UserComp.GetConstrainedAngle(AimResult.AimDirection, CenterPointDirection, Player.ActorUpVector);
		float Y = UserComp.GetConstrainedAngle(AimResult.AimDirection, CenterPointDirection, Player.ActorRightVector);
		UserComp.AnimationData.PullDirection.X = 0.0;
		UserComp.AnimationData.PullDirection.Y = 0.0;

		AimValues = Player.CalculatePlayerAimAnglesBuffered(AimValues);
		UserComp.AnimationData.HorizontalAimSpace = (AimValues.X / 90.0);
		UserComp.AnimationData.VerticalAimSpace = (AimValues.Y / 90.0);
		UserComp.AnimationData.NumGrabs = UserComp.Grabs.Num();
	}
};