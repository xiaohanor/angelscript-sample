
class UTundraPlayerSnowMonkeySwimmingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	UTundraPlayerShapeshiftingComponent ShapeShiftComponent;
	UTundraPlayerSnowMonkeyComponent MonkeyComponent;
	UPlayerMovementComponent MoveComp;
	UPlayerSwimmingComponent SwimmingComp;
	USweepingMovementData Movement;
	UTundraPlayerSnowMonkeySettings Settings;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 8;
	default TickGroupSubPlacement = 5;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	//float NextDamageTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeShiftComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		MonkeyComponent = UTundraPlayerSnowMonkeyComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSweepingMovementData();
		Settings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SwimmingComp.IsSwimming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ShapeShiftComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!SwimmingComp.IsSwimming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Swimming, this);

		SwimmingComp.AnimData.State = EPlayerSwimmingState::Underwater;
		SwimmingComp.AnimData.CurrentRotation = FRotator::MakeFromXY(MoveComp.Velocity.GetSafeNormal(), Owner.ActorRightVector);

		// Player.TriggerEffectEvent(n"PlayerSwimming.Activated"); // UNKNOWN EFFECT EVENT NAMESPACE

		//Reset eventual movement options
		Player.ResetWallScrambleUsage();
		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Swimming, this);
		// Player.TriggerEffectEvent(n"PlayerSwimming.Deactivated"); // UNKNOWN EFFECT EVENT NAMESPACE
		//NextDamageTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector Velocity = MoveComp.Velocity;
				Velocity += GetFrameRateIndependentDrag(Velocity, 12, DeltaTime);
				Movement.AddVelocity(Velocity);
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"UnderwaterSwimming");
		}
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}
}