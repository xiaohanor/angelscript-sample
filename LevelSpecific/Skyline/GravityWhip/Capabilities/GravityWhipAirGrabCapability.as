class UGravityWhipAirGrabCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipAirGrab);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGameplay);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::GravityWell);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 106;

	UGravityWhipUserComponent UserComp;
	bool bHasHitOtherPlayer = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSinceRelease = Time::GetGameTimeSince(UserComp.ReleaseTimestamp);
		if (TimeSinceRelease < GravityWhip::Grab::ReleaseDuration)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, GravityWhip::Grab::ReleaseDuration) && !UserComp.IsWhipPressBuffered())
			return false;

		if (UserComp.IsTargetingAny())
			return false;

		if (UserComp.IsGrabbingAny())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		
		if (ActiveDuration > GravityWhip::Grab::AirGrabDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(GravityWhipTags::GravityWhipGrab, this);
		Player.BlockCapabilities(GravityWhipTags::GravityWhipTarget, this);
		Player.BlockCapabilities(PlayerMovementTags::RollDash, this);

		bHasHitOtherPlayer = false;
		UserComp.bIsAirGrabbing = true;
		UserComp.bWhipGrabHadTarget = false;
		UserComp.bReleaseStrafeImmediately = false;
		UserComp.GrabTimestamp = Time::GameTimeSeconds;
		UserComp.AnimationData.LastAirGrabFrame = Time::FrameNumber;
		UserComp.ConsumeBufferedWhipPress();

		UserComp.AnimationData.bHasTurnedIntoWhipHit = false;

		UGravityWhipEventHandler::Trigger_WhipAirGrabStart(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(GravityWhipTags::GravityWhipGrab, this);
		Player.UnblockCapabilities(GravityWhipTags::GravityWhipTarget, this);
		Player.UnblockCapabilities(PlayerMovementTags::RollDash, this);

		UserComp.bIsAirGrabbing = false;
		UserComp.ReleaseTimestamp = Time::GameTimeSeconds;
		UserComp.AnimationData.bIsRequestingWhip = false;

		UGravityWhipEventHandler::Trigger_WhipAirGrabEnd(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitPlayerWithWhip(AHazePlayerCharacter HitPlayer, FVector Direction, bool bApplyStumble)
	{
		if (!HitPlayer.IsPlayerInvulnerable()
			&& !HitPlayer.IsCapabilityTagBlocked(n"PvPDamage"))
		{
			auto HealthComp = UPlayerHealthComponent::Get(HitPlayer);
			if (HealthComp.WouldDieFromDamage(0.2, true) && HealthComp.CanTakeDamage(false))
			{
				USkylinePVPEffectHandler::Trigger_KilledByOtherPlayer(HitPlayer);

				auto RespawnComp = UPlayerRespawnComponent::Get(HitPlayer);
				RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawnAfterKilledByOtherPlayer");
			}
			else
			{
				USkylinePVPEffectHandler::Trigger_HitByOtherPlayer(HitPlayer);
			}

			HitPlayer.DamagePlayerHealth(0.2);
			if (bApplyStumble)
				HitPlayer.ApplyStumble(Direction, 1.0);
		}
	}

	UFUNCTION()
	private void OnRespawnAfterKilledByOtherPlayer(AHazePlayerCharacter RespawnedPlayer)
	{
		auto RespawnComp = UPlayerRespawnComponent::Get(RespawnedPlayer);
		RespawnComp.OnPlayerRespawned.UnbindObject(this);

		USkylinePVPEffectHandler::Trigger_RespawnedAfterKilledByOtherPlayer(RespawnedPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto AimingRay = UserComp.GetAimingRay();
		FVector TargetLocation = UserComp.GetDragOrigin(GravityWhip::Grab::AirGrabDistance);
		if (!TargetLocation.Equals(AimingRay.Origin))
		{
			auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
			auto HitResult = Trace.QueryTraceSingle(AimingRay.Origin, TargetLocation);

			FVector HitLocation = HitResult.TraceEnd;
			if (HitResult.bBlockingHit)
				HitLocation = HitResult.ImpactPoint;
			
			UserComp.GrabCenterLocation = HitLocation;

			// Check if we've hit the other player
			if (HasControl() && !bHasHitOtherPlayer)
			{
				FVector ClosestOnLine = Math::ClosestPointOnLine(
					Player.ActorCenterLocation,
					UserComp.GrabCenterLocation,
					Player.OtherPlayer.CapsuleComponent.WorldLocation
				);

				if (ClosestOnLine.Distance(Player.OtherPlayer.CapsuleComponent.WorldLocation) < 80.0)
				{
					CrumbHitPlayerWithWhip(
						Player.OtherPlayer,
						(UserComp.GrabCenterLocation - Player.ActorCenterLocation).GetSafeNormal2D(Player.MovementWorldUp),
						bApplyStumble = (Math::RandRange(0.0, 1.0) <= 0.25),
					);
					bHasHitOtherPlayer = true;
				}
			}
		}

		if (Player.Mesh.CanRequestOverrideFeature())
		{
			Player.Mesh.RequestOverrideFeature(n"GravityWhip", this);
			UserComp.AnimationData.bIsRequestingWhip = true;
		}
		else
		{
			UserComp.AnimationData.bIsRequestingWhip = false;
		}

		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && ActiveDuration > GravityWhip::Grab::CanBufferHitsAfterDuration)
			UserComp.BufferWhipPress();
	}
}