// class UDroneSwarmBotMovementCapability : UHazeCapability
// {
// 	default TickGroup = EHazeTickGroup::Movement;

// 	ADroneSwarmBot SwarmBotOwner;

// 	UHazeMovementComponent MovementComponent;
// 	USteppingMovementData MoveData;

// 	AActor Leader;
// 	UHazeMovementComponent LeadMovementComponent;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		SwarmBotOwner = Cast<ADroneSwarmBot>(Owner);

// 		MovementComponent = SwarmBotOwner.MovementComponent;
// 		MoveData = SwarmBotOwner.MovementComponent.SetupSteppingMovementData();

// 		Leader = SwarmBotOwner.AttachParentActor;
// 		LeadMovementComponent = UHazeMovementComponent::Get(Leader);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if (MovementComponent.HasMovedThisFrame())
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if (MovementComponent.HasMovedThisFrame())
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if (!SwarmBotOwner.bSwarmActive)
// 		{
// 			Owner.SetActorLocation(Leader.ActorLocation);
// 			return;
// 		}


// 		if (!MovementComponent.Velocity.IsNearlyZero())
// 			Owner.SetMovementFacingDirection(MovementComponent.Velocity.GetSafeNormal());

// 		if (!MoveComp.PrepareMove(MoveData))
// 			return;

// 		// Add lead bot velocity
// 		// FVector LeaderVelocity = LeadMovementComponent.Velocity;
// 		// MoveData.AddVelocity(LeaderVelocity);

// 		FVector Velocity = LeadMovementComponent.Velocity;
// 		FVector BotToLeader = Leader.ActorLocation - Owner.ActorLocation; // Eman TODO: Have ideal distance on duderinos

// 		// Don't push backwards the drones in the front
// 		if (!Velocity.IsNearlyZero())
// 			Velocity += BotToLeader * Math::Max(0.5, BotToLeader.GetSafeNormal().DotProduct(Velocity.GetSafeNormal()));
// 		else
// 			Velocity += BotToLeader;

// 		if (!BotToLeader.IsNearlyZero())
// 		{
// 			FHazeTraceSettings Trace = Trace::InitFromMovementComponent(MovementComponent);
// 			FHitResult HitResult = Trace.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + BotToLeader);
// 			if (HitResult.bBlockingHit)
// 			{
// 				// Print("lmao! " + HitResult.Distance, 0.0);
// 				if (HitResult.Distance < 20.0)
// 				{
					
// 					// Velocity -= BotToLeader.RotateTowards(BotToLeader.CrossProduct(SwarmBotOwner.MovementWorldUp), DeltaTime * 500.0);

// 				}
// 				else
// 				{
					
// 				}
// 				// BotToLeader = BotToLeader.GetClampedToMaxSize(HitResult.Distance);
// 			}
// 		}

// 		if (MovementComponent.HasWallImpact())
// 		{
// 			// Velocity += MovementComponent.WallImpact.ImpactNormal * 1000.0 * DeltaTime;

// 			// BotToLeader = BotToLeader.RotateTowards(BotToLeader.CrossProduct(SwarmBotOwner.MovementWorldUp) + MovementComponent.WallImpact.ImpactNormal, 20.0);
// 		}

// 		// Handle other bot down impact
// 		if (MovementComponent.GroundImpact.Actor != nullptr)
// 		{
// 			FHitResult GroundImpact = MovementComponent.GroundImpact;
// 			if (GroundImpact.Actor.IsA(ADroneSwarmBot) || GroundImpact.Actor.IsA(AHazePlayerCharacter))
// 			{
// 				FVector SlideVelocity = GroundImpact.ImpactNormal.CrossProduct(FVector::RightVector);
// 				// SlideVelocity = SlideVelocity.CrossProduct(GroundImpact.ImpactNormal);
// 				// Debug::DrawDebugDirectionArrow(Owner.ActorLocation, SlideVelocity, SlideVelocity.Size() * 200.0);
// 				Velocity = SlideVelocity;
// 			}
// 		}


// 		MoveData.AddVelocity(Velocity);

// 		// Add gravity
// 		MoveData.AddAcceleration(-SwarmBotOwner.MovementWorldUp * Drone::Gravity);

// 		if (!Velocity.IsNearlyZero())
// 			MoveData.InterpRotationToTargetFacingRotation(20.0);

// 		MovementComponent.ApplyMove(MoveData);


// 		// Print("HBlah"+ SwarmBotOwner.CollisionShape.CollisionProfileName, 0.0);

// 		TempRockingMeshLol(DeltaTime);
// 	}

// 	void TempRockingMeshLol(float DeltaTime)
// 	{
// 		float SpeedMultiplier = MovementComponent.Velocity.Size() / 1000.0;
// 		float Roll = Math::DegreesToRadians(Math::Sin(Time::GameTimeSeconds * 40.0) * 10.0 * SpeedMultiplier);
// 		FQuat Rotation = FQuat(FVector::ForwardVector, Roll);
// 		SwarmBotOwner.Mesh.SetRelativeRotation(Rotation);
// 	}
// }