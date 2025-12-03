// class UTundra_SimonSaysPerchJumpUpCapability : UHazePlayerCapability
// {
// 	default TickGroup = EHazeTickGroup::ActionMovement;
// 	default TickGroupOrder = 0;
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);
// 	default CapabilityTags.Add(TundraSimonSays::SimonSaysPerchJump);

// 	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	UPlayerMovementComponent MoveComp;
// 	UTeleportingMovementData Movement;
// 	ATundra_SimonSaysManager Manager;
// 	UTundra_SimonSaysPlayerComponent PlayerComp;
// 	UPlayerPerchComponent PerchComp;
// 	UTundra_SimonSaysPlayerSettings Settings;

// 	bool bMoveDone = false;
// 	ACongaDanceFloorTile CurrentTile;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MoveComp = UPlayerMovementComponent::Get(Player);
// 		Movement = MoveComp.SetupTeleportingMovementData();
// 		Manager = TundraSimonSays::GetManager();
// 		PlayerComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Player);
// 		PerchComp = UPlayerPerchComponent::Get(Player);
// 		Settings = UTundra_SimonSaysPlayerSettings::GetSettings(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(MoveComp.HasMovedThisFrame())
// 			return false;
		
// 		if(PlayerComp.CurrentPerchTarget != nullptr)
// 			return false;

// 		if(PlayerComp.CurrentPerchedTile == nullptr)
// 			return false;

// 		if(!WasActionStarted(ActionNames::MovementJump))
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(MoveComp.HasMovedThisFrame())
// 			return true;

// 		if(bMoveDone)
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		bMoveDone = false;
// 		Player.AddMovementImpulseToReachHeight(Settings.PerchJumpUpHeight);
// 		CurrentTile = PlayerComp.CurrentPerchedTile;
// 		PerchComp.Data.bJumpingOff = true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		PlayerComp.CurrentPerchedTile = CurrentTile;
// 		PerchComp.Data.bJumpingOff = false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MoveComp.PrepareMove(Movement))
// 		{
// 			if(HasControl())
// 			{
// 				FVector Target = CurrentTile.SimonSaysTargetable.WorldLocation;

// 				float VerticalDelta = MoveComp.VerticalSpeed * DeltaTime;
// 				VerticalDelta += MoveComp.GetGravityForce() * (DeltaTime * DeltaTime * 0.5);

// 				float NextPlayerZ = Player.ActorLocation.Z + VerticalDelta;
// 				if(ActiveDuration > 0.0 && NextPlayerZ <= Target.Z)
// 				{
// 					bMoveDone = true;
// 					Movement.AddDelta(Target - Player.ActorLocation);
// 				}
// 				else
// 				{
// 					Movement.AddDelta((Target - Player.ActorLocation), EMovementDeltaType::HorizontalExclusive);
// 					Movement.AddPendingImpulses();
// 					Movement.AddOwnerVerticalVelocity();
// 					Movement.AddGravityAcceleration();
// 				}

// 				if(PlayerComp.CurrentPerchTarget != nullptr)
// 				{
// 					FVector PlayerToTarget = (PlayerComp.CurrentPerchTarget.SimonSaysTargetable.WorldLocation - Player.ActorLocation).GetSafeNormal2D();
// 					FQuat TargetRotation = PlayerToTarget.ToOrientationQuat();
// 					Movement.InterpRotationTo(TargetRotation, Settings.RotationInterpSpeed);
// 				}
// 				else
// 				{
// 					Movement.InterpRotationTo(Settings.DefaultForwardDirection.ToOrientationQuat(), Settings.RotationInterpSpeed);
// 				}
// 			}
// 			else
// 			{
// 				Movement.ApplyCrumbSyncedAirMovement();
// 			}

// 			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Perch");
// 		}
// 	}
// }