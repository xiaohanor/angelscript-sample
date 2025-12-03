asset TeenDragonTailGeckoClimbJumpMissBlend of UTeenDragonTailGeckoClimbBlend
{

}

class UTeenDragonTailGeckoClimbJumpMissCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionMovement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UCameraUserComponent CameraUser;
	
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	FVector StartWorldUp;
	FVector CurrentWorldUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		CameraUser = UCameraUserComponent::Get(Player);
	
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!GeckoClimbComp.bMissedGeckoJumping)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration >= ClimbSettings.JumpMissTransitionDuration)
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GeckoClimbComp.StopClimbing();

		StartWorldUp = GeckoClimbComp.GetClimbUpVector();
		GeckoClimbComp.OverrideCameraTransitionAlpha(0);

		Player.ApplyBlendToCurrentView(ClimbSettings.JumpMissTransitionDuration, TeenDragonTailGeckoClimbJumpMissBlend);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GeckoClimbComp.bMissedGeckoJumping = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / ClimbSettings.JumpMissTransitionDuration;
		CurrentWorldUp = FQuat::Slerp(StartWorldUp.ToOrientationQuat(), FVector::UpVector.ToOrientationQuat(), Alpha).ForwardVector;

		FVector Velocity = MoveComp.Velocity;
		FVector VelocityDirection = Velocity.GetSafeNormal();

		float VelocityDotWorldDown = -FVector::UpVector.DotProduct(Velocity);
		FVector VelocityTowardsWorldDown =  VelocityDirection * VelocityDotWorldDown;
		FVector VelocityNotTowardsWorldDown = Velocity - VelocityTowardsWorldDown;

		FVector SlowedDownVelocityNotTowardsWorldDown = Math::VInterpTo(VelocityNotTowardsWorldDown, FVector::ZeroVector, 
			DeltaTime, ClimbSettings.JumpMissHorizontalSlowDownSpeed);
		FVector NewVelocity = SlowedDownVelocityNotTowardsWorldDown + VelocityTowardsWorldDown;

		Player.SetActorVelocity(NewVelocity);

		if (MoveComp.PrepareMove(Movement, CurrentWorldUp))
		{
			if (HasControl())
			{
				Movement.AddOwnerVelocity();
				Movement.SetRotation(Player.ActorRotation);
				Movement.AddGravityAcceleration();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::AirMovement);
		}
	}
};