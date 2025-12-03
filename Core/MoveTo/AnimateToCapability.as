struct FAnimateToParams
{
	FActiveMoveTo MoveTo;
	bool bIsInstant = false;
	float Duration;
}

struct FAnimateToDeactivationParams
{
	bool bNaturalDeactivation = false;
}

class UAnimateToCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"MoveTo");

	default DebugCategory = n"MoveTo";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default BlockExclusionTags.Add(n"UsableDuringMoveTo");
	
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 100;

	UMoveToComponent MoveToComp;
	UHazeMovementComponent MoveComp;
	UHazeCharacterSkeletalMeshComponent SkeletalMesh;
	FAnimateToParams Params;

	FVector RelativeStartLocation;

	FQuat StartRotation;

	const float AnimateToSpeed = 500.0;
	const float AnimateToMinDuration = 0.4;
	//const float DurationOfFinalRotation = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveToComp = UMoveToComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		SkeletalMesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAnimateToParams& ActivationParams) const
	{
		FActiveMoveTo MoveParams;
		if (MoveToComp.CanActivateMoveTo(EMoveToType::AnimateTo, MoveParams))
		{
			ActivationParams.MoveTo = MoveParams;

			FTransform Destination = MoveParams.Destination.CalculateDestination(Owner.ActorTransform, MoveParams.Params);
			float Distance = Owner.ActorLocation.Distance(Destination.Location);
			if (Distance <= MoveTo::ANIMATE_TO_INSTANT_RANGE)
			{
				// If the player is within the threshold distance, fall back to doing a smooth teleport instead
				ActivationParams.bIsInstant = true;
			}
			else
			{
				// Otherwise animate
				ActivationParams.Duration = Math::Max(Distance / AnimateToSpeed, AnimateToMinDuration);
			}

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FAnimateToDeactivationParams& DeactivationParams) const
	{
		if (!MoveToComp.IsMoveToActive(Params.MoveTo))
		{
			DeactivationParams.bNaturalDeactivation = true;
			return true;
		}

		if (ActiveDuration >= Params.Duration*0.5)
		{
			DeactivationParams.bNaturalDeactivation = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAnimateToParams ActivationParams)
	{
		Params = ActivationParams;
		MoveToComp.ActivateMoveTo(Params.MoveTo);

		FTransform DestinationTransform = Params.MoveTo.Destination.CalculateDestination(Owner.ActorTransform, Params.MoveTo.Params);
		float Distance = Owner.ActorLocation.Distance(DestinationTransform.Location);
		MoveToComp.AnimDistanceToInteract = Distance;
		MoveToComp.AnimDuration = Params.Duration;
		MoveToComp.bAnimStartedAirborne = MoveComp.IsInAir();

		FVector DeltaToPoint = DestinationTransform.Location - Owner.ActorLocation;
		FVector LocalDeltaToPoint = Owner.ActorTransform.InverseTransformVector(DeltaToPoint);
		FRotator LocalRotation = Owner.ActorTransform.InverseTransformRotation(DestinationTransform.Rotator());

		MoveToComp.AnimAngleToInteractPosition = FRotator::MakeFromX(LocalDeltaToPoint).Yaw;
		MoveToComp.AnimAngleToInteractFwd = LocalRotation.Yaw;

		if (Params.bIsInstant)
		{
			ApplySmoothTeleport(Owner, Params.MoveTo.Params, Params.MoveTo.Destination);
			MoveToComp.FinishMoveTo(Params.MoveTo);
		}
		else
		{
			RelativeStartLocation = DestinationTransform.InverseTransformPosition(Owner.ActorLocation);

			Owner.BlockCapabilitiesExcluding(n"GameplayAction", n"UsableDuringMoveTo", this);
			Owner.BlockCapabilitiesExcluding(n"Movement", n"UsableDuringMoveTo", this);
		}

		StartRotation = Owner.ActorQuat;

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FAnimateToDeactivationParams DeactivationParams)
	{
		if (!Params.bIsInstant)
		{
			FTransform DestinationTransform = Params.MoveTo.Destination.CalculateDestination(Owner.ActorTransform, Params.MoveTo.Params);
			Owner.ActorTransform = DestinationTransform;
			Owner.ActorVelocity = FVector::ZeroVector;

			Owner.UnblockCapabilities(n"GameplayAction", this);
			Owner.UnblockCapabilities(n"Movement", this);

			MoveToComp.FinishMoveTo(Params.MoveTo);

			// Request the animation on the character
			if (DeactivationParams.bNaturalDeactivation)
			{
				if (SkeletalMesh != nullptr)
					SkeletalMesh.RequestLocomotion(n"MoveTo", this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Params.bIsInstant)
		{
			float LerpPct = Math::Clamp(ActiveDuration / (Params.Duration/2), 0.0, 1.0);

			FTransform DestinationTransform = Params.MoveTo.Destination.CalculateDestination(Owner.ActorTransform, Params.MoveTo.Params);
			FVector CurrentRelativeLocation = Math::Lerp(RelativeStartLocation, FVector::ZeroVector, LerpPct);

			// Snap to the rotation towards the point, then blend to the target rotation
			FQuat MovementRotation = Owner.ActorQuat;
	
			//MovementRotation = FQuat::MakeFromZX(Owner.MovementWorldUp, DestinationTransform.Location - DestinationTransform.TransformPosition(RelativeStartLocation));
			float DurationOfFinalRotation = (Params.Duration);
			if (ActiveDuration > Params.Duration - DurationOfFinalRotation)
			{
				float RotatePct = ((ActiveDuration *2) - (Params.Duration - DurationOfFinalRotation)) / DurationOfFinalRotation;
				MovementRotation = FQuat::Slerp(StartRotation, DestinationTransform.Rotation, RotatePct);
			}
	
			Owner.ActorTransform = FTransform(MovementRotation, DestinationTransform.TransformPosition(CurrentRelativeLocation));

			// Request the animation on the character
			if (SkeletalMesh != nullptr)
				SkeletalMesh.RequestLocomotion(n"MoveTo", this);
		}
	}
};