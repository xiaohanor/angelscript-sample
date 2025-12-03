
class UPlayerLedgeGrabCancelCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerLedgeGrabTags::LedgeGrabCancel);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 12;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerLedgeGrabComponent LedgeGrabComp;

	const float CancelDuration = 0.4;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		// if (LedgeComp.bShouldEnterWallRun)
		// 	return false;

		if (LedgeGrabComp.State != EPlayerLedgeGrabState::LedgeGrab)
			return false;

		if (!IsActioning(ActionNames::Cancel))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnWalkableGround())
			return true;

		if (ActiveDuration >= CancelDuration)
			return true;

		if (LedgeGrabComp.State != EPlayerLedgeGrabState::Cancel)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeGrab, this);

		// Inherited Velocity
		// FVector InheritedVelocity = MoveComp.GetInheritedVelocity(false);
		// FVector HorizontalInheritedVelocity = InheritedVelocity.ConstrainToPlane(MoveComp.WorldUp);
		// float VerticalInheritedSpeed = InheritedVelocity.DotProduct(MoveComp.WorldUp);

		//MoveComp.Velocity = (WallNormal * 300.0) + HorizontalInheritedVelocity + (MoveComp.WorldUp * VerticalInheritedSpeed);

		LedgeGrabComp.State = EPlayerLedgeGrabState::Cancel;

		Player.SetActorVelocity(LedgeGrabComp.Data.WallImpactNormal * 300.0);

		// Player.TriggerEffectEvent(n"PlayerLedgeGrab.CancelActivated"); // UNKNOWN EFFECT EVENT NAMESPACE

		// The rotation will snap 180 degrees, so we need a transition to prevent a bad lerp
		MoveComp.TransitionCrumbSyncedPosition(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeGrab, this);
		
		LedgeGrabComp.ResetLedgeGrab();

		// Player.TriggerEffectEvent(n"PlayerLedgeGrab.CancelDeactivated"); // UNKNOWN EFFECT EVENT NAMESPACE
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector VerticalVelocity = MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp);
				FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);

				HorizontalVelocity -= HorizontalVelocity * 1.0 * DeltaTime;

				float GravityBlendIn = Math::Clamp(ActiveDuration / 0.2, 0.0, 1.0);
				
				VerticalVelocity -= MoveComp.WorldUp * LedgeGrabComp.Settings.CancelGravityStrength * GravityBlendIn * DeltaTime;

				// Terminal Velocity
				if (VerticalVelocity.DotProduct(MoveComp.WorldUp) < -LedgeGrabComp.Settings.CancelTerminalVelocity)
					VerticalVelocity = VerticalVelocity.GetClampedToMaxSize(LedgeGrabComp.Settings.CancelTerminalVelocity);

				Movement.AddVerticalVelocity(VerticalVelocity);
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.SetRotation(FRotator::MakeFromX(LedgeGrabComp.Data.WallImpactNormal));
			}
			else // Remote
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeGrab");
		}
	}
}