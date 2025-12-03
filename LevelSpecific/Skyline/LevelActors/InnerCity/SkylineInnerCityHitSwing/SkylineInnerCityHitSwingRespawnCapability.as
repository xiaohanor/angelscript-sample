struct FSkylineInnerCityHitSwingRespawnDeactivateParams
{
	bool bNatural = false;
}

class USkylineInnerCityHitSwingRespawnCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASkylineInnerCityHitSwing SwingThing;

	UHazeMovementComponent MoveComp;
	bool bBlockedZoeSwingy = false;
	bool bDisabledSwing = false;
	bool bHasOpenedDoor = false;
	bool bEarlyFakeDestroy = false;

	AHazePlayerCharacter Zoe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingThing = Cast<ASkylineInnerCityHitSwing>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		Zoe = Game::Zoe;
		SwingThing.OnDestroyed.AddUFunction(this, n"UnblockThings");
	}

	UFUNCTION()
	private void UnblockThings(AActor DestroyedActor)
	{
		if (bBlockedZoeSwingy)
		{
			Zoe.UnblockCapabilities(PlayerMovementTags::Swing, this);
			Zoe.UnblockCapabilities(PlayerMovementTags::Grapple, this);
		}
		bBlockedZoeSwingy = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 0.1)
			return false;
		if (SwingThing.bFalling)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineInnerCityHitSwingRespawnDeactivateParams & Params) const
	{
		if (ActiveDuration >= InnerCityHitSwing::FallRespawnTime)
		{
			Params.bNatural = true;
			return true;
		}
		if (bEarlyFakeDestroy && SwingThing.RespawnCloset.State == ESkylineInnerCityHitSwingRespawnClosetDoorState::Open)
		{
			Params.bNatural = true;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bEarlyFakeDestroy = false;
		bHasOpenedDoor = false;

		if (!SwingThing.SwingPoint.bIsPlayerUsingPoint[Zoe])
		{
			SwingThing.SwingPoint.Disable(this);
			bDisabledSwing = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineInnerCityHitSwingRespawnDeactivateParams Params)
	{	
		if (!Params.bNatural)
			return;
		if (SwingThing.IsActorBeingDestroyed())
			return;

		RespawnSwingThing();

		if (Zoe.HasControl() && SwingThing.SwingPoint.bIsPlayerUsingPoint[Zoe])
		{
			bBlockedZoeSwingy = true;
			Zoe.BlockCapabilities(PlayerMovementTags::Swing, this);
			Zoe.BlockCapabilities(PlayerMovementTags::Grapple, this);
		}
		Timer::SetTimer(this, n"CloseDoor", 0.3);
	}

	void RespawnSwingThing()
	{
		SwingThing.RemoveActorVisualsBlock(this);
		SwingThing.RemoveActorCollisionBlock(this);
		SwingThing.BladeCombatTargetComp.Enable(this);
		SwingThing.EnableSwingPoint();
		SwingThing.TeleportActor(
			SwingThing.RespawnCloset.RespawnLocation.WorldLocation,
			SwingThing.RespawnCloset.RespawnLocation.WorldRotation,
			this
		);

		// :puke:
		SwingThing.MoveComp.AddMovementIgnoresActor(this, SwingThing.RespawnCloset);
		TArray<AActor> AttachedActors;
		SwingThing.RespawnCloset.GetAttachedActors(AttachedActors);
		SwingThing.MoveComp.AddMovementIgnoresActors(this, AttachedActors);

		SwingThing.MoveComp.Reset(true, SwingThing.ActorUpVector, true, 100);
		SwingThing.MoveComp.SnapToGround(false);
		
		SwingThing.MoveComp.RemoveMovementIgnoresActor(this);

		SwingThing.MoveComp.AddPendingImpulse(SwingThing.RespawnCloset.ActorForwardVector * InnerCityHitSwing::RespawnSpeed);
		SwingThing.RespawningFrame = Time::GameTimeSeconds;
		SwingThing.LastHitTime = 0.0;
		SwingThing.EnableVFX();
		
		USkylineInnerCityHitSwingEventHandler::Trigger_OnRespawn(SwingThing);
	} 

	UFUNCTION()
	private void CloseDoor()
	{
		if (bBlockedZoeSwingy)
		{
			Zoe.UnblockCapabilities(PlayerMovementTags::Swing, this);
			Zoe.UnblockCapabilities(PlayerMovementTags::Grapple, this);
		}
		if (bDisabledSwing)
			SwingThing.SwingPoint.Enable(this);

		bBlockedZoeSwingy = false;
		SwingThing.RespawnCloset.SetOpenState(false);
		bDisabledSwing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bShouldOpenDoor = ActiveDuration >= InnerCityHitSwing::FallRespawnTime -0.33;
		if (HasControl() && bShouldOpenDoor && !bHasOpenedDoor)
		{
			bHasOpenedDoor = true;
			NetOpenDoor();
		}

		auto CeilHit = SwingThing.MoveComp.GetContact(EMovementImpactType::Ceiling);
		auto WallHit = SwingThing.MoveComp.GetContact(EMovementImpactType::Wall);
		bool bShouldDestroy = CeilHit.bBlockingHit || WallHit.bBlockingHit;
		if (!bEarlyFakeDestroy && HasControl() && bShouldDestroy)
		{
			bEarlyFakeDestroy = true;
			CrumbFakeDestroy();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbFakeDestroy()
	{
		//SwingThing.SwingPoint.Disable(this);
		SwingThing.DisableSwingPoint();
		SwingThing.BladeCombatTargetComp.Disable(this);
		SwingThing.AddActorCollisionBlock(this);
		SwingThing.AddActorVisualsBlock(this);
		SwingThing.DisableVFX();
		
		USkylineInnerCityHitSwingEventHandler::Trigger_OnFakeDestroyedAgainstEnvironment(SwingThing);
	}

	UFUNCTION(NetFunction)
	void NetOpenDoor()
	{
		if (Zoe.HasControl() && SwingThing.SwingPoint.bIsPlayerUsingPoint[Zoe])
		{
			if (!Zoe.IsPlayerRespawning())
				NetKillZoe();
		}
		SwingThing.RespawnCloset.SetOpenState(true);
	}

	UFUNCTION(NetFunction)
	void NetKillZoe()
	{
		Zoe.KillPlayer();
	}


};