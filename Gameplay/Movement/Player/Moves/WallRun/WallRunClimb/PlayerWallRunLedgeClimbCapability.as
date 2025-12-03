
class UPlayerWallRunLedgeClimbCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::WallRun);
	default CapabilityTags.Add(PlayerMovementTags::LedgeGrab);
	default CapabilityTags.Add(PlayerWallRunTags::WallRunClimb);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 29;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	UPlayerWallRunComponent WallRunComp;

	float MoveSpeed = 0.0;
	bool bReachedTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		WallRunComp = UPlayerWallRunComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerWallRunClimbData& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (WallRunComp.State != EPlayerWallRunState::WallRunLedge)
        	return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;
		
		// Ensure input is towards the wall
		if (MoveComp.MovementInput.DotProduct(WallRunComp.ActiveData.WallNormal) >= 0.0)
			return false;

		FPlayerWallRunClimbData ClimbData;
		if (!TraceClimbUp(ClimbData, IsDebugActive()))
			return false;	

		if (!ClimbData.HitComponent.HasTag(n"LedgeClimbable"))
			return false;	
		
		ActivationParams = ClimbData;	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (bReachedTarget)
			return true;

		if (ActiveDuration >= WallRunComp.ClimbSettings.Duration)
			return true;

		if (WallRunComp.State != EPlayerWallRunState::WallRunLedgeClimb)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerWallRunClimbData ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::WallRun, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		WallRunComp.SetState(EPlayerWallRunState::WallRunLedgeClimb);
		WallRunComp.ClimbData = ActivationParams;

		bReachedTarget = false;
		MoveSpeed = (WallRunComp.ClimbData.TargetLocation - Owner.ActorLocation).Size() / WallRunComp.ClimbSettings.Duration;


		// Player.TriggerEffectEvent(n"PlayerWallRun.LedgeClimbActivated"); // UNKNOWN EFFECT EVENT NAMESPACE
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::WallRun, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		WallRunComp.StateCompleted(EPlayerWallRunState::WallRunLedgeClimb);

		WallRunComp.ActiveData.Reset();
		WallRunComp.ClimbData.Reset();

		// Player.TriggerEffectEvent(n"PlayerWallRun.LedgeClimbDeactivated"); // UNKNOWN EFFECT EVENT NAMESPACE
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(MoveComp.PrepareMove(Movement))
		{
			Movement.SetRotation(Owner.ActorRotation);

			FVector ToTarget = WallRunComp.ClimbData.TargetLocation - Owner.ActorLocation;

			const float Delta = MoveSpeed * DeltaTime;		
			if (ToTarget.Size() < Delta)
			{
				bReachedTarget = true;
				Movement.AddDeltaWithCustomVelocity(ToTarget, FVector::ZeroVector);
				Movement.OverrideFinalGroundResult(WallRunComp.ClimbData.Hit);
			}
			else
			{
				Movement.AddDelta(ToTarget.GetSafeNormal() * Delta);
			}
					
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WallRun");
		}
	}

	bool TraceClimbUp(FPlayerWallRunClimbData& ClimbData, bool bDebug = false) const
	{
		const float TraceMargin = 25.0;
		const float CapsuleHalfHeight = Player.CapsuleComponent.CapsuleHalfHeight - TraceMargin;

		// Reduce the capsule height by the margin so we don't trace higher than the capsule will ever be 
		FHazeTraceSettings TargetTraceSettings = Trace::InitFromMovementComponent(MoveComp);
		TargetTraceSettings.UseCapsuleShape(
			Player.CapsuleComponent.CapsuleRadius, CapsuleHalfHeight,
			Player.CapsuleComponent.RelativeRotation.Quaternion(),
		);
		TargetTraceSettings.UseShapeWorldOffset(FVector(0.0, 0.0, CapsuleHalfHeight));

		if (IsDebugActive())
			TargetTraceSettings.DebugDraw(5.0);

		// Trace for target location
		FVector TargetLocation = WallRunComp.ActiveData.LedgeGrabData.LedgeLocation;

		TargetLocation -= WallRunComp.ActiveData.LedgeGrabData.TopRotation.ForwardVector * WallRunComp.ClimbSettings.TargetLocationDepth;
		TargetLocation += WallRunComp.ActiveData.LedgeGrabData.WallRotation.RightVector
						 * WallRunComp.ActiveData.LedgeGrabData.TopRotation.RightVector.DotProduct(MoveComp.Velocity)
						 * WallRunComp.ClimbSettings.Duration;

		const FVector TargetTraceStart = TargetLocation + Player.MovementWorldUp * TraceMargin;
		const FVector TargetTraceEnd = TargetLocation - Player.MovementWorldUp * TraceMargin;

		FHitResult TargetTraceHit = TargetTraceSettings.QueryTraceSingle(TargetTraceStart, TargetTraceEnd);

		if (TargetTraceHit.bStartPenetrating)
			return false;
		if (!TargetTraceHit.bBlockingHit)
			return false;

		FHazeTraceSettings ReachTraceSettings = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		ReachTraceSettings.UseLine();
		if (bDebug)
			ReachTraceSettings.DebugDrawOneFrame();
		
		const FVector ReachTraceStart = WallRunComp.ActiveData.LedgeGrabData.LedgeLocation + (Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight) + (WallRunComp.ActiveData.LedgeGrabData.TopRotation.ForwardVector * WallRunComp.WallSettings.TargetDistanceToWall);
		const FVector ReachTraceEnd = TargetLocation + Player.MovementWorldUp * Player.CapsuleComponent.CapsuleHalfHeight;
		FHitResult ReachHit = ReachTraceSettings.QueryTraceSingle(ReachTraceStart, ReachTraceEnd);

		if (ReachHit.bStartPenetrating)
			return false;
		if (ReachHit.bBlockingHit)
			return false;

		ClimbData.TargetLocation = TargetTraceHit.Location;
		ClimbData.Hit = TargetTraceHit;

		if (bDebug)
		{
			Debug::DrawDebugCapsule(ReachTraceEnd, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, Player.ActorRotation, FLinearColor::Green, 1.0, 0.0 );
			Debug::DrawDebugCapsule(Player.CapsuleComponent.WorldLocation, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, Player.ActorRotation, FLinearColor::Red, 1.0, 0.0 );
			Debug::DrawDebugLine(ReachTraceStart, ReachTraceEnd, FLinearColor::Green, 2.0, 0.0);
			Debug::DrawDebugLine(Player.ActorLocation, TargetTraceHit.Location, FLinearColor(1.0, 0.5, 0.0), 2.0, 0.0);
		}

		return true;
	}
}