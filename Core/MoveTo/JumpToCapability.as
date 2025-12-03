struct FJumpToParams
{
	FActiveMoveTo MoveTo;
	bool bIsInstant = false;
	float Duration;
	float VerticalVelocity;
}

struct FJumpToDeactivationParams
{
	bool bNaturalDeactivation = false;
}

class UJumpToCapability : UHazeCapability
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
	FJumpToParams Params;

	FVector RelativeStartLocation;
	FQuat StartRotation;

	const float AnimateToSpeed = 1000.0;
	const float AnimateToMinDuration = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveToComp = UMoveToComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		SkeletalMesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FJumpToParams& ActivationParams) const
	{
		FActiveMoveTo MoveParams;
		if (MoveToComp.CanActivateMoveTo(EMoveToType::JumpTo, MoveParams))
		{
			ActivationParams.MoveTo = MoveParams;

			FTransform DestinationTransform = MoveParams.Destination.CalculateDestination(Owner.ActorTransform, MoveParams.Params);
			FVector WorldUp = MoveComp.WorldUp;

			// Setup velocity
			FVector TargetLoc = DestinationTransform.Location;
			FVector Loc = Owner.GetActorLocation();

			if (TargetLoc.Distance(Loc) < MoveTo::JUMP_TO_INSTANT_RANGE)
			{
				ActivationParams.bIsInstant = true;
			}
			else
			{
				float Gravity = MoveComp.GravityForce;
				float VerticalDistance = (TargetLoc - Loc).DotProduct(WorldUp);

				/*
				Calculate how long it will take to reach the target height, with given impulse

				Parabola:
				-G/2 * (X - V/G)^2 + V^2/2G = A

				(-2A / G) + (V / G)^2
				*/
				float TargetHeight = VerticalDistance + MoveParams.Params.JumpAdditionalHeight;

				// Make sure we jump high enough to at _least_ reach additional height
				if (TargetHeight < MoveParams.Params.JumpAdditionalHeight)
					TargetHeight = MoveParams.Params.JumpAdditionalHeight;

				TargetHeight = Math::Max(TargetHeight, 0.0);

				float Impulse = Math::Sqrt(2.0 * TargetHeight * Gravity);

				float ValueToSqrt = (-2.0 * VerticalDistance) / Gravity +
					((Impulse / Gravity) * (Impulse / Gravity));

				// X = V / G + sqrt((-2A / G) + (V / G)^2)
				float FlyTime = Impulse / Gravity +
					Math::Sqrt(Math::Max(ValueToSqrt, 0.001));

				ActivationParams.bIsInstant = false;
				ActivationParams.Duration = FlyTime;
				ActivationParams.VerticalVelocity = Impulse;
			}

			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FJumpToDeactivationParams& DeactivationParams) const
	{
		if (!MoveToComp.IsMoveToActive(Params.MoveTo))
		{
			DeactivationParams.bNaturalDeactivation = true;
			return true;
		}

		if (ActiveDuration >= Params.Duration)
		{
			DeactivationParams.bNaturalDeactivation = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FJumpToParams ActivationParams)
	{
		Params = ActivationParams;
		MoveToComp.ActivateMoveTo(Params.MoveTo);

		if (Params.bIsInstant)
		{
			ApplySmoothTeleport(Owner, Params.MoveTo.Params, Params.MoveTo.Destination);
			MoveToComp.FinishMoveTo(Params.MoveTo);
		}
		else
		{
			FTransform DestinationTransform = Params.MoveTo.Destination.CalculateDestination(Owner.ActorTransform, Params.MoveTo.Params);
			RelativeStartLocation = DestinationTransform.InverseTransformPosition(Owner.ActorLocation);
			StartRotation = Owner.ActorQuat;

			Owner.BlockCapabilitiesExcluding(n"GameplayAction", n"UsableDuringMoveTo", this);
			Owner.BlockCapabilitiesExcluding(n"Movement", n"UsableDuringMoveTo", this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FJumpToDeactivationParams DeactivationParams)
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
				if (SkeletalMesh != nullptr && SkeletalMesh.CanRequestLocomotion())
					SkeletalMesh.RequestLocomotion(n"Jump", this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Params.bIsInstant)
		{
			float LerpPct = Math::Clamp(ActiveDuration / Math::Max(Params.Duration, 0.01), 0.0, 1.0);

			FTransform DestinationTransform = Params.MoveTo.Destination.CalculateDestination(Owner.ActorTransform, Params.MoveTo.Params);

			FVector RelativeWorldUp = DestinationTransform.InverseTransformVector(MoveComp.WorldUp);

			FVector HorizontalOffset = Math::Lerp(RelativeStartLocation, FVector::ZeroVector, LerpPct);
			HorizontalOffset = HorizontalOffset.ConstrainToPlane(RelativeWorldUp);

			float VerticalOffset = Params.VerticalVelocity * ActiveDuration - MoveComp.GravityForce * Math::Square(ActiveDuration) * 0.5;
			VerticalOffset += RelativeStartLocation.DotProduct(RelativeWorldUp);

			FVector RelativeFrameLocation = HorizontalOffset + RelativeWorldUp * VerticalOffset;

			// Snap to the rotation towards the point, then blend to the target rotation
			Owner.SetActorLocationAndRotation(
				DestinationTransform.TransformPosition(RelativeFrameLocation),
				FQuat::Slerp(StartRotation, DestinationTransform.Rotation, LerpPct)
			);

			// Request the animation on the character
			if (SkeletalMesh != nullptr)
				SkeletalMesh.RequestLocomotion(n"Jump", this);
		}
	}
};