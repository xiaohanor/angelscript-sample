class UPlayerAirborneLedgeMantleExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleMovement);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleRoll);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 5;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerLedgeMantleComponent MantleComp;

	FVector RelativeExitLocation;
	float MoveSpeed;
	bool bMoveCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MantleComp.Data.HasValidData())
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::AirborneRollEnter)
			return false;

		if (!MantleComp.Data.bEnterCompleted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (bMoveCompleted)
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (MoveComp.HasWallContact())
			return true;

		if (MantleComp.Data.TopHitComponent == nullptr || MantleComp.Data.ExitFloorHit.Component == nullptr)
			return true;

		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;

		if (ActiveDuration >= MantleComp.Settings.AirborneRollMantleExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);

		// if(Player.IsMovementCameraBehaviorEnabled())
		// {
				//Camera impulse/FF needed
		// }

		if(HasControl())
		{
			bMoveCompleted = false;
			FVector EndLocation = MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(MantleComp.Data.FloorRelativeExitLocation);

			FVector ToTarget = EndLocation - Player.ActorLocation;
			FVector ToTargetFlattened = ToTarget.ConstrainToPlane(MoveComp.WorldUp);
			MoveSpeed = ToTargetFlattened.Size() / MantleComp.Settings.AirborneRollMantleExitDuration;
		}

		MoveComp.FollowComponentMovement(MantleComp.Data.TopHitComponent, this);
		MantleComp.SetState(EPlayerLedgeMantleState::AirborneRollExit);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Roll_ExitStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);

		MoveComp.UnFollowComponentMovement(this);
		MantleComp.StateCompleted(EPlayerLedgeMantleState::AirborneRollExit);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Roll_ExitFinished(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector ToTarget = MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(MantleComp.Data.FloorRelativeExitLocation) - Player.ActorLocation;
			ToTarget = ToTarget.ConstrainToPlane(MantleComp.Data.ExitFloorHit.Normal);
			FVector DeltaMove = ToTarget.GetSafeNormal() * MoveSpeed * DeltaTime;

			FRotator TargetRotation = MantleComp.Data.ExitFacingDirection.Rotation();
			FRotator NewRotation = Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 540);

			if (ToTarget.Size() < DeltaMove.Size())
			{
				bMoveCompleted = true;
				Movement.OverrideFinalGroundResult(MantleComp.Data.ExitFloorHit);
			}

#if !RELEASE
			if (IsDebugActive() || PlayerLedgeMantle::CVar_DebugLedgeMantle.GetInt() == 1)
			{
				Debug::DrawDebugSphere(MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(MantleComp.Data.FloorRelativeExitLocation), 25, LineColor = FLinearColor::Red, Duration = 5);
				Debug::DrawDebugString(MantleComp.Data.ExitFloorHit.Component.WorldTransform.TransformPosition(MantleComp.Data.FloorRelativeExitLocation), "ExitLocation", FLinearColor::DPink);
			}
#endif
			Movement.AddDeltaWithCustomVelocity(DeltaMove, MantleComp.Data.Direction * MoveSpeed);
			Movement.SetRotation(NewRotation);
		}
		// Remote update
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement ,n"LedgeMantle");
	}
	
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog Log)
	{
		Log.Value("Valid TopHit: ", MantleComp.Data.TopLedgeHit.bBlockingHit);
		Log.Value("Valid ExitHit: ", MantleComp.Data.ExitFloorHit.bBlockingHit);
	}
};
