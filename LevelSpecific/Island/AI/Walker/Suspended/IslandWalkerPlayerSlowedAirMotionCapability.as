
class UIslandWalkerPlayerSlowedAirMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);
	default CapabilityTags.Add(n"WalkerBossfight");

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 159; // Just before regular air motion

	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	UIslandWalkerPlayerSlowdownComponent SlowdownComp;
	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	UMovementGravitySettings GravitySettings;
	USteppingMovementData Movement;

	bool bUseGroundedTraceDistance = false;
	float PreviousSpeedFactor;
	FVector ActualHorizontalVelocity;
	FVector ActualVerticalVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		SlowdownComp = UIslandWalkerPlayerSlowdownComponent::GetOrCreate(Player);
		GravitySettings = UMovementGravitySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (SlowdownComp.SpeedFactor > 1.0 - SMALL_NUMBER)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (SlowdownComp.SpeedFactor > 1.0 - SMALL_NUMBER)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
		WeaponUserComp.AddOverrideFeatureBlocker(this);
		WeaponUserComp.AddForceHoldWeaponInHandInstigator(this);

		// If we find a follow velocity component on the object we just left
		if (MoveComp.PreviousGroundContact.IsValidBlockingHit())
		{
			UPlayerInheritVelocityComponent VelocityComp = Cast<UPlayerInheritVelocityComponent>(MoveComp.GetPreviousGroundContact().Actor.GetComponent(UPlayerInheritVelocityComponent));
			if(VelocityComp != nullptr)
			{
				FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();
				FVector VerticalVelocity = MoveComp.GetVerticalVelocity();

				VelocityComp.AddFollowAdjustedVelocity(MoveComp, HorizontalVelocity, VerticalVelocity);
				Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);
			}
		}

		PreviousSpeedFactor = 1.0;
		ActualVerticalVelocity = Owner.ActorUpVector * Owner.ActorUpVector.DotProduct(MoveComp.Velocity);
		ActualHorizontalVelocity = MoveComp.Velocity - ActualVerticalVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		WeaponUserComp.RemoveOverrideFeatureBlocker(this);
		WeaponUserComp.RemoveForceHoldWeaponInHandInstigator(this);
		bUseGroundedTraceDistance = false;

		// Speed up proportionally to speedfactor at end. This only has an effect if slowdown is abruptly stopped
		FVector ActualVelocity = MoveComp.Velocity / Math::Max(PreviousSpeedFactor, 0.01);
		Player.SetActorVelocity(ActualVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float SpeedFactor = Math::Max(SlowdownComp.SpeedFactor, 0.01);
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector PrevVel = ActualHorizontalVelocity * SpeedFactor;
				FVector HorizontalVelocity = AirMotionComp.CalculateStandardAirControlVelocity(MoveComp.MovementInput, PrevVel,	DeltaTime, SpeedFactor, SpeedFactor);
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				ActualHorizontalVelocity = HorizontalVelocity / SpeedFactor;

				float Gravity = GravitySettings.GravityAmount * GravitySettings.GravityScale;
				ActualVerticalVelocity -= Owner.ActorUpVector * Gravity * DeltaTime * SpeedFactor;
				Movement.AddVerticalVelocity(ActualVerticalVelocity * SpeedFactor);
				
				//	How fast should the player rotate when falling at fast speeds
				const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(ActualVerticalVelocity), 0.0);
				const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComp.Settings.MaximumTurnRateFallingSpeed) / AirMotionComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

				const float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComp.Settings.MaximumTurnRate, AirMotionComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
				Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveComp.MovementInput.Size() * SpeedFactor);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			// If this is the reset frame, we use a bigger stepdown
			// to find out if we are grounded or not
			if(!MoveComp.bHasPerformedAnyMovementSinceReset || bUseGroundedTraceDistance)
			{
				Movement.ForceGroundedStepDownSize();
			}

			// We need to request grounded if this capability finds
			// the ground, else we will get a small step animation
			// in the beginning after a reset
			if(MoveComp.IsOnAnyGround())
			{
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
				bUseGroundedTraceDistance = true;
			}
			else
			{
				Movement.RequestFallingForThisFrame();
				MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SlowMoFire");
			}
		}

		PreviousSpeedFactor = SlowdownComp.SpeedFactor;
	}
}

class UIslandWalkerPlayerSlowdownComponent : UActorComponent
{
	float SpeedFactor = 1.0;
}
