
namespace MovementInput
{
	const int CapabilityTickGroupOrder = 10;
	
	const float WalkableSlopePercentage = 0.8;
	const float InverseThreshold = 0.5;

	FVector FixupMovementForwardVector(const FRotator ControlRotation, FVector WorldUp)
	{
		const float Dot = ControlRotation.UpVector.DotProduct(WorldUp);
		if (Math::IsNearlyZero(Dot, KINDA_SMALL_NUMBER))
			return ControlRotation.UpVector;

		const float Sign = Math::Sign(Dot);
		const float TiltedDot = ControlRotation.RightVector.DotProductLinear(WorldUp) * Sign;
		if (TiltedDot > WalkableSlopePercentage || TiltedDot < -InverseThreshold)
		{
			return ControlRotation.UpVector;
		}
		else
		{
			FVector Forward = ControlRotation.ForwardVector.ConstrainToPlane(WorldUp).GetSafeNormal();
			if (Forward.IsZero())
				Forward = ControlRotation.UpVector.ConstrainToPlane(WorldUp).GetSafeNormal();
			return Forward;
		}
	}

	FVector FixupMovementRightVector(FRotator ControlRotation, FVector WorldUp, FVector Forward)
	{
		const float Dot = ControlRotation.UpVector.DotProduct(WorldUp);
		if (Math::IsNearlyZero(Dot, KINDA_SMALL_NUMBER))
			return WorldUp.CrossProduct(Forward);

		const float Sign = Math::Sign(Dot);
		const float UpsideDownDot = (1.0 - ControlRotation.RightVector.DotProductLinear(WorldUp)) * Sign;
		if ((UpsideDownDot > 1.0 - WalkableSlopePercentage || UpsideDownDot < -InverseThreshold))
		{
			return WorldUp.CrossProduct(Forward) * Sign;
		}
		else
		{
			return WorldUp.CrossProduct(Forward);
		}	
	}
}


/* This is the current direction and magnitude we should be moving in. If it is the player, it is usually the stick input. */
UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint), Category = "Movement")
mixin void ApplyMovementInput(AHazeActor Actor, FVector InputVector, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low)
{
	if (Actor == nullptr)
		return;
		
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if (MoveComp == nullptr)
	{
		devError(f"The actor {Actor} needs a movement component to handle 'SetMovementInput' function calls");
		return;
	}

	MoveComp.ApplyMovementInput(InputVector, Instigator, Priority);
}

UFUNCTION(NotBlueprintCallable, meta = (NotInLevelBlueprint), Category = "Movement")
mixin void ClearMovementInput(AHazeActor Actor, FInstigator Instigator)
{
	if (Actor == nullptr)
		return;
	
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if (MoveComp == nullptr)
		return;

	MoveComp.ClearMovementInput(Instigator);
}

// One 30fps frame of snapback detection
const float SNAPBACK_DETECTION_DURATION = 1.0 / 33.0;

struct FStickSnapbackDetector
{
	bool bDetectedSnapback = false;
	FVector SnapbackStoredDirection;
	FVector SnapbackBaseInput;
	float SnapbackDetectedTime = 0.0;

	FVector LastStickInput;
	FVector LastMovementDirection;

	bool IsReverseDirection(FVector Input, FVector Base) const
	{
		if (Base.IsZero() || Input.IsZero())
			return false;
		if (Math::Sign(Input.X) != Math::Sign(Base.X) && Math::Abs(Input.X) > 0.01)
			return true;
		if (Math::Sign(Input.Y) != Math::Sign(Base.Y) && Math::Abs(Input.Y) > 0.01)
			return true;
		return false;
	}

	FVector RemoveStickSnapbackJitter(FVector RawStick, FVector MovementDirection)
	{
		if (bDetectedSnapback)
		{
			if (IsReverseDirection(RawStick, SnapbackBaseInput))
			{
				// Snapback timed out, we probably actually reversed direction!
				float TimeDiff = Time::RealTimeSeconds - SnapbackDetectedTime;
				if (TimeDiff > SNAPBACK_DETECTION_DURATION)
				{
					bDetectedSnapback = false;

					LastStickInput = RawStick;
					LastMovementDirection = MovementDirection;
					return MovementDirection;
				}

				// Still detecting a snapback, so keep going in original direction
				LastStickInput = RawStick;
				LastMovementDirection = MovementDirection;
				return SnapbackStoredDirection;
			}
			else
			{
				// Snapback ended, allow input through
				if (!RawStick.IsZero())
				{
					// Only end snapback if we gave input in the 'right' direction,
					// otherwise just wait it out.
					bDetectedSnapback = false;
				}

				LastStickInput = RawStick;
				LastMovementDirection = MovementDirection;
				return MovementDirection;
			}
		}
		else
		{
			if (IsReverseDirection(RawStick, LastStickInput))
			{
				// Trigger a new snapback detection
				bDetectedSnapback = true;
				SnapbackBaseInput = LastStickInput;
				SnapbackStoredDirection = LastMovementDirection;
				SnapbackDetectedTime = Time::RealTimeSeconds;
				return SnapbackStoredDirection;
			}

			// Snapback detection did not trigger, so just use the input
			LastStickInput = RawStick;
			LastMovementDirection = MovementDirection;
			return MovementDirection;
		}
	}

	void ClearSnapbackDetection()
	{
		bDetectedSnapback = false;
		LastStickInput = FVector::ZeroVector;
		LastMovementDirection = FVector::ZeroVector;
	}
};