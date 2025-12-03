class UHackableSniperTurretDeactivationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	AHackableSniperTurret SniperTurret;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneHijackComponent HijackComponent;
	UPlayerMovementComponent MovementComponent;

	USteppingMovementData MoveData;

	bool bSniperTurretHackingStopped = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();

		// We should only have one in the level
		SniperTurret = TListedActors<AHackableSniperTurret>().GetSingle();
		if (SniperTurret != nullptr)
		{
			SniperTurret.OnHackingStarted.AddUFunction(this, n"OnSniperTurretHackingStarted");
			SniperTurret.OnHackingStopped.AddUFunction(this, n"OnSniperTurretHackingStopped");
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SwarmDroneComponent == nullptr)
			return false;

		if (SniperTurret == nullptr)
			return false;

		if (!bSniperTurretHackingStopped)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SwarmDroneComponent == nullptr)
			return true;

		if (SniperTurret == nullptr)
			return true;

		// This is the very end of the level, so capability will perish by its own

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);

		// Block swarm bot movement, we handle it hier
		SwarmDroneComponent.ApplySwarmBotMovementBlock(this);

		// Teleport player to final position
		FVector Location = SniperTurret.HijackTargetableComp.WorldLocation;
		FRotator Rotation = FRotator::MakeFromXZ(SniperTurret.ActorForwardVector, Player.MovementWorldUp);
		Player.TeleportActor(Location, Rotation, this, false);

		// Initial lil' hop
		FVector JumpImpulse = SniperTurret.HijackTargetableComp.ForwardVector * 850;
		Player.SetActorVelocity(JumpImpulse);

		// Prepare bots
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			SwarmBot.ApplyRespawnBlock(this);

			FVector BotLocation = SwarmDroneHijack::GetRandomWorldDiveTransformForHijackable(SniperTurret.HijackTargetableComp).Location;
			SwarmBot.SetActorLocation(BotLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);

		SwarmDroneComponent.ClearSwarmBotMovementBlock(this);

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
			SwarmDroneComponent.SwarmBots[i].ClearRespawnBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector Velocity = MovementComponent.Velocity;
				Velocity -= MovementComponent.WorldUp * Drone::Gravity * DeltaTime;

				MoveData.AddVelocity(Velocity);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}

		// Now tick bots
		MoveSwarm(DeltaTime);
	}

	void MoveSwarm(float DeltaTime)
	{
		const float ScaleAlpha = Math::Saturate(ActiveDuration / 0.1);

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];

			// Scale up bots to smooth-in transition
			if (SwarmBot.Id <= SwarmDrone::DeployedBotCount)
			{
				FVector Scale = FVector(ScaleAlpha * ScaleAlpha * SwarmBot.RetractedScale);
				SwarmBot.GroupSkelMeshAnimData.Transform.SetScale3D(Scale);
			}

			// Add offset from swarm center
			FVector Offset = SwarmBot.ActorUpVector * Math::PerlinNoise1D(Time::GameTimeSeconds + SwarmBot.Id) * 60;

			// Add some twist
			FVector BotToPlayer = SwarmBot.ActorLocation - Player.ActorLocation;
			Offset += BotToPlayer.GetSafeNormal().CrossProduct(Player.ActorRightVector).GetSafeNormal() * 100.0;

			// Add some noise in the velocity vector
			float ForwardMultiplier = SwarmBot.Id - SwarmDrone::DeployedBotCount * 0.8;
			Offset += MovementComponent.Velocity.GetSafeNormal() * ForwardMultiplier * 6.0;

			// Move!
			FVector BotVelocity = SwarmBot.AttachParentActor.ActorVelocity + Offset;
			MoveBot(SwarmBot, BotVelocity);

			SwarmBot.RootComponent.AddRelativeRotation(Offset.Rotation() * DeltaTime);
		}
	}

	void MoveBot(ASwarmBot SwarmBot, FVector Velocity)
	{
		FVector FrameVelocity = Velocity;

		FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
		Trace.UseSphereShape(SwarmBot.Collider.SphereRadius * 2.0);
		Trace.IgnorePlayers();

		FHitResult HitResult = Trace.QueryTraceSingle(SwarmBot.ActorLocation, SwarmBot.ActorLocation + Velocity * Time::GetActorDeltaSeconds(SwarmBot));
		if (HitResult.bBlockingHit)
			FrameVelocity += HitResult.ImpactNormal * FrameVelocity.ConstrainToDirection(HitResult.ImpactNormal).Size();

		SwarmBot.SetActorLocation(SwarmBot.ActorLocation + FrameVelocity * Time::GetActorDeltaSeconds(SwarmBot));
	}

	// Setup is run before player possesses drone...fetch stuff here instead
	UFUNCTION(NotBlueprintCallable)
	void OnSniperTurretHackingStarted(FSwarmDroneHijackParams HijackParams)
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		HijackComponent = UPlayerSwarmDroneHijackComponent::Get(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSniperTurretHackingStopped()
	{
		bSniperTurretHackingStopped = true;
	}
}