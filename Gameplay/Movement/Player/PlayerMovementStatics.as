
UFUNCTION(meta = (NotInLevelBlueprint))
mixin void ApplyCameraUsesMovementFollowDeltaRotation(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto MoveComp = UCameraFollowMovementFollowDataComponent::Get(Player);
	if(MoveComp == nullptr)
	{
		return;
	}
	
	MoveComp.StartApplyMovementRotationToCamera(Instigator);
}

UFUNCTION(meta = (NotInLevelBlueprint))
mixin void ClearCameraUsesMovementFollowDeltaRotation(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto MoveComp = UCameraFollowMovementFollowDataComponent::Get(Player);
	if(MoveComp == nullptr)
	{
		return;
	}
	
	MoveComp.StopApplyMovementRotationToCamera(Instigator);
}

/** The input will not be using the control rotation. Instead
 * Left / Right input will follow the 'HorizontalInputDirection'
 * Up / Down input will follow the 'VerticalInputDirection'
*/
UFUNCTION()
mixin void LockInputToPlane(AHazePlayerCharacter Player, FInstigator Instigator, FVector HorizontalInputDirection = FVector::ForwardVector, FVector VerticalInputDirection = FVector::RightVector, EInstigatePriority Priority = EInstigatePriority::Low)
{
	auto MoveComp = UPlayerMovementComponent::Get(Player);
	if(MoveComp == nullptr)
		return;
	
	if(!devEnsure(HorizontalInputDirection.IsUnit(), f"LockInputToPlane on {Player} was called from {Instigator} with a bad HorizontalInputDirection"))
		return;

	// if(!devEnsure(VerticalInputDirection.IsUnit(), f"LockInputToPlane on {Player} was called from {Instigator} with a bad VerticalInputDirection"))
	// 	return;
	
	FInputPlaneLock LockInfo;
	LockInfo.LeftRight = HorizontalInputDirection;
	LockInfo.UpDown = VerticalInputDirection;
	MoveComp.InputPlaneLock.Apply(LockInfo, Instigator, Priority);
}

/** The input will not be using the control rotation. Instead
 * Left / Right input will follow the 'Rotation Right'
 * Up / Down input will follow the 'Rotation Forward'
*/
UFUNCTION()
mixin void LockInputToPlaneOrientation(AHazePlayerCharacter Player, FInstigator Instigator, FRotator Rotation, EInstigatePriority Priority = EInstigatePriority::Low)
{
	auto MoveComp = UPlayerMovementComponent::Get(Player);
	if(MoveComp == nullptr)
		return;
	
	FInputPlaneLock LockInfo;
	LockInfo.LeftRight = Rotation.RightVector;
	LockInfo.UpDown = Rotation.ForwardVector;
	MoveComp.InputPlaneLock.Apply(LockInfo, Instigator, Priority);
}

UFUNCTION()
mixin void ClearLockInputToPlane(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto MoveComp = UPlayerMovementComponent::Get(Player);
	if(MoveComp == nullptr)
		return;

	MoveComp.InputPlaneLock.Clear(Instigator);
}


UFUNCTION()
mixin void ForceAttachToPole(AHazePlayerCharacter Player, APoleClimbActor Pole)
{
	UPlayerPoleClimbComponent PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);

	if(PoleClimbComp == nullptr)
		return;

	PoleClimbComp.ForceEnterPole(Pole);

}

/**
 * Force a HighSpeedLanding roll
 * - If no velocity is specified it will use current velocity and direction (unless velocity is 0 in which we dont perform one)
 * - If ExitSpeed is negative it will either put you at  1.5* Sprint or floormotion speed based on if sprint is toggled or not (If this is higher then our Start Velocity size you will accelerate)
 * 		- If Exitspeed is 0 it blends down to standstill
 * 		- If Exitspeed is a positive nonzero value its what we blend out into
 */
UFUNCTION()
mixin void ForceHighSpeedLanding(AHazePlayerCharacter Player, FVector StartVelocity = FVector::ZeroVector, float ExitSpeed = - 1.0)
{
	UPlayerFloorMotionComponent FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);

	if(FloorMotionComp == nullptr)
		return;

	UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);

	if(MoveComp == nullptr)
		return;
	
	if(StartVelocity.Size() <= KINDA_SMALL_NUMBER && MoveComp.HorizontalVelocity.Size() <= KINDA_SMALL_NUMBER)
		return;
	
	if(StartVelocity.Size() <= KINDA_SMALL_NUMBER)
		FloorMotionComp.Data.ForceHighSpeedLandingVelocity = MoveComp.HorizontalVelocity;
	else
		FloorMotionComp.Data.ForceHighSpeedLandingVelocity = StartVelocity;

	FloorMotionComp.Data.ForceHighSpeedExitSpeed = ExitSpeed;
	FloorMotionComp.Data.bForceHighSpeedLanding = true;
}

//Set how action mode animations should apply (How Player Idles)
UFUNCTION()
mixin void ApplyActionMode(AHazePlayerCharacter Player, EPlayerActionMode Mode, EInstigatePriority Priority, FInstigator Instigator)
{
	UPlayerActionModeComponent ActionModeComp = UPlayerActionModeComponent::Get(Player);

	if(ActionModeComp == nullptr)
	{
		devError("No Component found to apply ActionMode to");
		return;
	}

	ActionModeComp.ApplyActionMode(Mode, Instigator, Priority);
}

UFUNCTION()
mixin void ClearActionMode(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerActionModeComponent ActionModeComp = UPlayerActionModeComponent::Get(Player);

	if(ActionModeComp == nullptr)
	{
		devError("No Component found to clear ActionMode from");
		return;
	}

	ActionModeComp.ClearActionMode(Instigator);
}

UFUNCTION()
mixin void ApplyMovingBalanceBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerFloorMotionComponent FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);

	if(FloorMotionComp == nullptr)
	{
		devError("No Component found to apply blocker to");
		return;
	}

	FloorMotionComp.AddMovingBalanceBlocker(Instigator);
}

UFUNCTION()
mixin void ClearMovingBalanceBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerFloorMotionComponent FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);

	if(FloorMotionComp == nullptr)
	{
		devError("No Component found to clear blocker from");
		return;
	}

	FloorMotionComp.ClearMovingBalanceBlocker(Instigator);
}

UFUNCTION()
mixin void ApplyRelaxIdleBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerFloorMotionComponent FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);

	if(FloorMotionComp == nullptr)
	{
		devError("No Component found to apply blocker to");
		return;
	}

	FloorMotionComp.AddRelaxIdleBlocker(Instigator);
}

UFUNCTION()
mixin void ClearRelaxIdleBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerFloorMotionComponent FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);

	if(FloorMotionComp == nullptr)
	{
		devError("No Component found to clear blocker from");
		return;
	}

	FloorMotionComp.ClearRelaxIdleBlocker(Instigator);
}

UFUNCTION()
mixin void ApplyPerchIdleBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerPerchComponent PerchComp = UPlayerPerchComponent::Get(Player);

	if(PerchComp == nullptr)
	{
		devError("No Component found to apply blocker to");
		return;
	}

	PerchComp.AddPerchIdleBlocker(Instigator);
}

UFUNCTION()
mixin void ClearPerchIdleBlocker(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerPerchComponent PerchComp = UPlayerPerchComponent::Get(Player);

	if(PerchComp == nullptr)
	{
		devError("No Component found to clear blocker from");
		return;
	}

	PerchComp.RemovePerchIdleBlocker(Instigator);
}

/**
 * Apply a standard player knockback impulse
 * 
 * Knockback impulses don't apply additively to the player's current velocity, so
 * the player can't shoot off in a direction by jumping or already moving.
 * 
 * They also have a cooldown and potentially restrict the player's air control for a short duration.
 */
UFUNCTION(Category = "Knockback")
mixin void AddKnockbackImpulse(AHazePlayerCharacter Player, FVector Direction, float HorizontalImpulse = 900.0, float VerticalImpulse = 1200.0, float AirControlWeakenDuration = 0.6)
{
	FVector WorldUp = Player.MovementWorldUp;

	FVector KnockDirection = Direction.ConstrainToPlane(WorldUp).GetSafeNormal();
	float ExistingSpeed = Player.ActorVelocity.DotProduct(KnockDirection);

	FVector Impulse = KnockDirection * Math::Clamp(HorizontalImpulse - ExistingSpeed, 0.0, HorizontalImpulse);
	Impulse.Z = Math::Max(0.0, VerticalImpulse - Player.ActorVelocity.Z);

	Player.AddMovementImpulseWithCooldown(Impulse, n"KnockbackImpulse", 0.5);

	if (AirControlWeakenDuration > 0.0)
	{
		auto AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		AirMotionComp.TemporarilyWeakenAirControl(
			0.0,
			AirControlWeakenDuration,
			0.0,
			AirControlWeakenDuration,
			bWeakenFacingRotation = false);
	}
}

namespace Movement
{

/**
 * Knock back any players in the radius around the point away from the point.
 */
UFUNCTION(Category = "Knockback")
void KnockbackPlayersInRadius(FVector Location, float Radius, float KnockbackHorizontalImpulse, float KnockbackVerticalImpulse, float AirControlWeakenDuration = 0.6)
{
	for (AHazePlayerCharacter Player : Game::Players)
	{
		if (Overlap::QueryShapeOverlap(
			Player.CapsuleComponent.GetCollisionShape(),
			Player.CapsuleComponent.WorldTransform,
			FCollisionShape::MakeSphere(Radius),
			FTransform(Location),
		))
		{
			Player.AddKnockbackImpulse((Player.ActorCenterLocation - Location).GetSafeNormal(), KnockbackHorizontalImpulse, KnockbackVerticalImpulse, AirControlWeakenDuration);
		}
	}
}

}