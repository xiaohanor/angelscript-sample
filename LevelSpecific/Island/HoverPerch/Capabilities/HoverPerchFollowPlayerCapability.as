// struct FHoverPerchFollowPlayerActivatedParams
// {
// 	AHazePlayerCharacter PerchingPlayer;
// }

// class UHoverPerchFollowPlayerCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	default DebugCategory = n"Movement";

// 	default TickGroup = EHazeTickGroup::LastMovement;
// 	default TickGroupOrder = 180;

// 	UHazeMovementComponent MoveComp;
// 	USweepingMovementData Movement;

// 	AHoverPerchActor PerchActor;
// 	AHazePlayerCharacter PerchingPlayer;

// 	const float FollowPlayerDuration = 5;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MoveComp = UHazeMovementComponent::Get(Owner);
// 		Movement = MoveComp.SetupSweepingMovementData();

// 		PerchActor = Cast<AHoverPerchActor>(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate(FHoverPerchFollowPlayerActivatedParams& Params) const
// 	{
// 		if(MoveComp.HasMovedThisFrame())
// 			return false;

// 		if(PerchActor.HoverPerchComp.bIsDestroyed)
// 			return false;

// 		if(PerchActor.HoverPerchComp.PerchingPlayer == nullptr)
// 			return false;

// 		if(!PerchActor.PlayerIsJumping())
// 			return false;

// 		if(PerchActor.HoverPerchComp.PerchingPlayer.IsPlayerDead())
// 			return false;

// 		if(Time::GetGameTimeSince(PerchActor.TimeOfStopPerch) > FollowPlayerDuration)
// 			return false;

// 		if(PerchActor.HoverPerchComp.bHasHasImpactSincePerching)
// 			return false;

// 		Params.PerchingPlayer = PerchActor.HoverPerchComp.PerchingPlayer;
// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(MoveComp.HasMovedThisFrame())
// 			return true;

// 		if(PerchActor.HoverPerchComp.bIsDestroyed)
// 			return true;

// 		if(PerchActor.HoverPerchComp.PerchingPlayer == nullptr)
// 			return true;

// 		if(!PerchActor.PlayerIsJumping())
// 			return true;

// 		if(PerchActor.HoverPerchComp.PerchingPlayer.IsPlayerDead())
// 			return true;

// 		if(Time::GetGameTimeSince(PerchActor.TimeOfStopPerch) > FollowPlayerDuration)
// 			return true;

// 		if(PerchActor.HoverPerchComp.bHasHasImpactSincePerching)
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FHoverPerchFollowPlayerActivatedParams Params)
// 	{
// 		PerchingPlayer = Params.PerchingPlayer;
// 		MoveComp.OverrideResolver(UHoverPerchActorSweepingResolver, this);
// 		// Because perch point land follows perch, but the hoverperch follows the player, so we don't want it
// 		PerchingPlayer.BlockCapabilities(PlayerPerchPointTags::PerchPointLand, this);

// 		// MoveComp.FollowComponentMovement(PerchingPlayer.CapsuleComponent, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::High);
// 		// MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::OnlyFollowReferenceFrame);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		MoveComp.ClearResolverOverride(UHoverPerchActorSweepingResolver, this);
// 		PerchingPlayer.UnblockCapabilities(PlayerPerchPointTags::PerchPointLand, this);

// 		// MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);
// 		// MoveComp.ClearFollowEnabledOverride(this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MoveComp.PrepareMove(Movement))
// 		{
// 			if(HasControl())
// 			{
// 				FVector TargetLocation = PerchingPlayer.ActorLocation;
// 				TargetLocation.Z = PerchActor.ActorLocation.Z;

// 				FVector TargetDelta = TargetLocation - PerchActor.ActorLocation;

// 				Movement.AddDelta(TargetDelta);

// 				PerchActor.ApplyHeightResetMovement(Movement, DeltaTime);

// 				PerchActor.MeshComp.AddLocalRotation(FRotator(0, (PerchActor.ActorVelocity.Size() / 2) * DeltaTime, 0));
// 				PerchActor.SyncedMeshRelativeRotation.Value = PerchActor.MeshComp.RelativeRotation;

// 				// if(MoveComp.HasAnyValidBlockingContacts())
// 				// 	PerchActor.HoverPerchComp.bHasHasImpactSincePerching = true;

// 				TEMPORAL_LOG(PerchActor, "Follow Player")
// 					.Sphere("Perch Actor Location", PerchActor.ActorLocation + FVector::UpVector * 200, 5, FLinearColor::Blue, 2)
// 					.Sphere("Target Location", TargetLocation + FVector::UpVector * 200, 5, FLinearColor::Red, 2)
// 					.Sphere("Player Location", PerchingPlayer.ActorLocation, 10, FLinearColor::Green, 2)
// 					.Value("Perching Player", PerchingPlayer.Name)
// 				;
// 			}
// 			else
// 			{
// 				Movement.ApplyCrumbSyncedAirMovement();
// 				PerchActor.MeshComp.RelativeRotation = PerchActor.SyncedMeshRelativeRotation.Value;
// 			}

// 			MoveComp.ApplyMove(Movement);
// 		}
// 	}
// }