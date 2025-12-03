struct FPickupActivationParams
{
	UPickupComponent PickupComponent;
}

class UPickupCapability : UHazeCapability
{
	default CapabilityTags.Add(PickupTags::Pickups);
	default CapabilityTags.Add(PickupTags::PickupCapability);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AHazePlayerCharacter PlayerOwner;
	UPlayerPickupComponent PlayerPickupComponent;

	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	FTransform PickupAlignRelativeTransform;

	FTransform InitialTransform;

	const float AlignDuration = 0.27;
	float PickupTimer;

	bool bWaitingForAlign;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerPickupComponent = UPlayerPickupComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPickupActivationParams& ActivationParams) const
	{
		if (PlayerPickupComponent.GetCurrentPickup() == nullptr)
			return false;

		if (PlayerPickupComponent.bCarryingPickup)
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		ActivationParams.PickupComponent = PlayerPickupComponent.GetCurrentPickup();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		// Eman TODO: Deactivate once we are done lerping and playing pickup animation
		if (ActiveDuration >= 0.87)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPickupActivationParams ActivationParams)
	{
		bWaitingForAlign = true;
		PlayerPickupComponent.bCarryingPickup = false;
		PickupTimer = 0.0;
		PlayerPickupComponent.CurrentPickup = ActivationParams.PickupComponent;

		// Eman TODO: Start lerping player towards pickup
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);

		PickupAlignRelativeTransform = GetPickupAnimationAlignTransform();

		InitialTransform = PlayerOwner.ActorTransform;

		// Fire start event
		FPickUpStartedParams PickUpStartedParams;
		PickUpStartedParams.PickupComponent = ActivationParams.PickupComponent;
		PlayerPickupComponent.OnPickupStartedEvent.Broadcast(PickUpStartedParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Get pickup animation align world transform
		FTransform AlignTransform = PickupAlignRelativeTransform * PlayerOwner.ActorTransform;

		float TargetDistanceFromPickup = PlayerOwner.ActorLocation.Distance(AlignTransform.Location);
		FVector PlayerToPickup = (PlayerPickupComponent.CurrentPickup.Owner.ActorLocation - PlayerOwner.ActorLocation).GetSafeNormal();

		FVector TargetLocation = PlayerPickupComponent.CurrentPickup.Owner.ActorLocation - PlayerToPickup * TargetDistanceFromPickup;

		// Move towards align location
		// if (bWaitingForAlign)
		// {
		// 	float AngularDistance = PlayerOwner.ActorForwardVector.DotProduct(PlayerToPickup.ConstrainToPlane(PlayerOwner.MovementWorldUp));
		// 	Print("AD: "+ AngularDistance, 0.1);
		// 	Print("Distance " + PlayerOwner.ActorLocation.Distance(TargetLocation), 0.1);

		// 	if (PlayerOwner.ActorLocation.Distance(TargetLocation) > 6.0 || AngularDistance < 0.98)
		// 	{
		// 		FVector MoveDirection = TargetLocation - PlayerOwner.ActorLocation;
		// 		// PlayerOwner.SetMovementInput(MoveDirection.GetSafeNormal(), this);
		// 		// PlayerOwner.SetMovementFacingDirection(PlayerToPickup.GetSafeNormal());

		// 		Debug::DrawDebugDirectionArrow(PlayerOwner.ActorCenterLocation, PlayerToPickup, 200.0, 5.0, FLinearColor::Green);
		// 		// PlayerOwner.SmoothTeleportActor(TargetLocation, FRotator::MakeFromX(PlayerToPickup), this, DeltaTime);

		// 		PlayerOwner.SetMovementFacingDirection(PlayerToPickup.GetSafeNormal());

		// 		if (MoveComp.PrepareMove(MoveData))
		// 		{
		// 			MoveData.AddHorizontalVelocity(MoveDirection * DeltaTime * (1000.0 / Math::Sqrt(TargetDistanceFromPickup)));
		// 			MoveData.InterpRotationToTargetFacingRotation(12);

		// 			MovementComponent.ApplyMoveAndRequestLocomotion(MoveData, n"Movement");
		// 		}
		// 	}
		// 	else
		// 	{
		// 		bWaitingForAlign = false;
		// 		// PlayerOwner.ClearMovementInput(this);
		// 		// PlayerOwner.SetMovementFacingDirection(PlayerToPickup.GetSafeNormal());
		// 	}
		// }
		// else
		// {
		// 	PickupTimer += DeltaTime;
		// 	if (PickupTimer >= 0.27 && !PlayerPickupComponent.bCarryingPickup)
		// 	{
		// 		PickUp();
		// 		PlayerPickupComponent.bCarryingPickup = true;
		// 	}
		// }

		if (!PlayerPickupComponent.bCarryingPickup)
			PlayerOwner.SetMovementFacingDirection(PlayerToPickup);

		// Align towards
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (ActiveDuration < AlignDuration)
			{
				// Lerp to target
				float AlignCompletion = Math::Saturate(ActiveDuration / AlignDuration);
				FVector TargetPlayerLocation = Math::Lerp(InitialTransform.Location, TargetLocation, AlignCompletion);
				FVector MoveDelta = TargetPlayerLocation - InitialTransform.Location;
				MoveData.AddDelta(MoveDelta * DeltaTime * 5.0);

				// Rotation
				float AngularDistance = (PlayerOwner.ActorForwardVector.AngularDistance(PlayerToPickup)) * 3.1416;
				MoveData.InterpRotationToTargetFacingRotation((AngularDistance / AlignDuration));

				// MovementComponent.ApplyMove(MoveData);
			}
			else if (!PlayerPickupComponent.bCarryingPickup)
			{
				PickUp();

				// Consume momentum from align
				// MovementComponent.ApplyMove(MoveData);
			}

			MovementComponent.ApplyMove(MoveData);
		}
	}

	void PickUp()
	{
		// Attach to player bone!
		PlayerPickupComponent.GetCurrentPickup().Owner.AttachToComponent(PlayerOwner.Mesh, PlayerPickupComponent.GetCurrentPickup().GetAttachBone());
		PlayerPickupComponent.GetCurrentPickup().Owner.SetActorRelativeTransform(PlayerPickupComponent.GetCurrentPickup().PlayerCarryOffset);

		PlayerPickupComponent.bCarryingPickup = true;

		// Fire picked up event
		FPickedUpParams PickedUpParams;
		PickedUpParams.PickupComponent = PlayerPickupComponent.CurrentPickup;
		PlayerPickupComponent.OnPickedUpEvent.Broadcast(PickedUpParams);
	}

	FTransform GetPickupAnimationAlignTransform() const
	{
		UAnimSequence PickupAnimation = PlayerPickupComponent.CurrentPickup.PickupSettings.PickupType == EPickupType::Light ?
			PlayerPickupComponent.LocomotionFeature.AnimData.PickUpGroundLight.Sequence :
			PlayerPickupComponent.LocomotionFeature.AnimData.PickUpGroundHeavy.Sequence;

		FTransform Transform;
		PickupAnimation.GetAnimBoneTransform(Transform, n"Align");

		return Transform;
	}
}