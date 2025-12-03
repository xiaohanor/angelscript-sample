class UTrainPlayerCrashIntoWaterLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"TrainPlayerCrashIntoWaterLaunch");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default SeparateInactiveTick(EHazeTickGroup::InfluenceMovement, 9);

	UPlayerMovementComponent MoveComp;
	UTrainPlayerCrashIntoWaterLaunchComponent LaunchComp;

	USimpleMovementData Movement;

	bool bCollisionIsBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		LaunchComp = UTrainPlayerCrashIntoWaterLaunchComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(LaunchComp.ActorToLaunchTo == nullptr)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(LaunchComp.ActorToLaunchTo == nullptr)
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// This is checked from the train inherit movement component
		Player.BlockCapabilities(n"TrainInheritMovement", this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		if(LaunchComp.bBlockCollisionWhenLaunched)
		{
			Player.BlockCapabilities(CapabilityTags::Collision, this);
			bCollisionIsBlocked = true;
		}

		FVector PlayerVelocity = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, LaunchComp.ActorToLaunchTo.ActorLocation, 
			MoveComp.GravityForce, 0, -1.0, MoveComp.WorldUp);
		
		Player.SetActorVelocity(PlayerVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"TrainInheritMovement", this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		

		LaunchComp.ActorToLaunchTo = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVelocity();

				if(bCollisionIsBlocked 
				&& ActiveDuration > LaunchComp.CollisionBlockDuration)
				{
					Player.UnblockCapabilities(CapabilityTags::Collision, this);
					bCollisionIsBlocked = false;
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}
};