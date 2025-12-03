class UIslandWalkerHeadDetachIntroBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	bool bCompleted;
	float DoneTime = BIG_NUMBER;
	bool bRising;
	FVector Destination;
	
	UIslandWalkerSettings Settings;
	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerSpawnerComponent SpawnerComp;
	AIslandWalkerArenaLimits Arena;
	AIslandWalkerHeadStumpTarget Stump;
	AHazePlayerCharacter Target;

	UHazeTeam SpawnTeam;
	float DestroySpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		if (HeadComp.NeckCableOrigin != nullptr)
			SpawnerComp = UIslandWalkerSpawnerComponent::Get(HeadComp.NeckCableOrigin.Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner); 
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget StumpTarget)
	{
		Stump = StumpTarget;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bCompleted)
			return false;
		if (SpawnerComp == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > DoneTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Arena = UIslandWalkerComponent::Get(HeadComp.NeckCableOrigin.Owner).ArenaLimits;
		DoneTime = BIG_NUMBER;
		bRising = false;
		SpawnerComp.bAllowSpawning = false;
		SpawnTeam = UHazeActorSpawnerComponent::Get(HeadComp.NeckCableOrigin.Owner).SpawnedActorsTeam;
		if (SpawnTeam != nullptr)
			DestroySpawnTime = 0.5;

		HeadComp.bSubmerged = (Owner.ActorLocation.Z < Arena.PoolSurfaceHeight);
		if (!HeadComp.bSubmerged)
			Stump.PowerUp();

		// Steady on until free flying
		UIslandWalkerSettings::SetHeadWobbleAmplitude(Owner, FVector::ZeroVector, this, EHazeSettingsPriority::Gameplay);
		UMovementGravitySettings::SetGravityScale(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);

		Stump.IgnoreDamage();

		// When force field starts to power up it'll do so faster than normally, from back to front
		UIslandWalkerSettings::SetForceFieldReplenishAmountPerSecond(Owner, Settings.DetachIntroForcefieldGrowthSpeed, this);
		FVector InitialBreachLoc = Owner.ActorLocation + Owner.ActorForwardVector * Stump.ForceFieldComp.BoundsRadius;
		Stump.ForceFieldComp.LocalBreachLocation = Stump.ForceFieldComp.WorldTransform.InverseTransformPosition(InitialBreachLoc);

		// Turn off any bullet reflection for our remainnig life time
		auto BulletReflector = UIslandRedBlueReflectComponent::Get(Owner);
		if (BulletReflector != nullptr)
			BulletReflector.AddReflectBlockerForBothPlayers(this);

		if (Owner.ActorLocation.Z < Arena.PoolSurfaceHeight)
		{
			// Rise out of pool! 
			AnimComp.RequestFeature(FeatureTagWalker::HeadRiseFromPool, EBasicBehaviourPriority::Medium, this);
			Stump.PowerUp();

			// Normal bounds are to small to cover this animation
			Cast<AHazeCharacter>(Owner).Mesh.SetBoundsScale(3.0);
		}

		UIslandWalkerHeadEffectHandler::Trigger_OnStartedFlying(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
		Owner.ClearSettingsByInstigator(this);

		if (Owner.Level.IsBeingRemoved())
			return; // Closing down game while in this behaviour, no need to follow through

		// Head can now be damaged
		UIslandWalkerHeadStumpRoot::Get(Owner).Target.PowerUp();
		Stump.AllowDamage();

		// Destroy any remaining spawn
		if (SpawnTeam != nullptr)
		{
			for (AHazeActor Spawn : SpawnTeam.GetMembers())
			{
				if (Spawn != nullptr)
					UBasicAIHealthComponent::Get(Spawn).TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
			}
		}

		// Restore bounds
		Cast<AHazeCharacter>(Owner).Mesh.SetBoundsScale(2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;

		// Rise to the edge of the pool closest to the players
		if (!bRising)
		{
			bRising = true;

			// Aggro against the player who shot off our neck
			AHazePlayerCharacter NeckBreaker = Game::GetPlayer(UIslandWalkerNeckRoot::Get(HeadComp.NeckCableOrigin.Owner).NeckTarget.ShootablePanel.UsableByPlayer);
			Target = NeckBreaker;
			if (!TargetComp.IsValidTarget(NeckBreaker))
				Target = NeckBreaker.OtherPlayer;
			TargetComp.SetTarget(Target);

			// Go to edge position closest to target
			float Dummy;
			FVector EdgeStart, EdgeEnd;
			Arena.GetInnerEdge(Target.ActorLocation, EdgeStart, EdgeEnd, -800.0);
			Math::ProjectPositionOnLineSegment(EdgeStart, EdgeEnd, Target.ActorLocation, Destination, Dummy);
			Destination.Z = Arena.Height + Settings.DetachIntroRiseHeight;

			TArray<UIslandWalkerHeadThruster> Thrusters;
			Owner.GetComponentsByClass(Thrusters);
			for (UIslandWalkerHeadThruster Thruster : Thrusters)
			{
				Thruster.Deploy();
				Thruster.Ignite();
			}
		}

		float BottomZ = Arena.Height - 1000.0;
		if ((OwnLoc.Z < BottomZ) && !OwnLoc.IsWithinDist2D(Destination, 800.0))
		{
			// Move in underneath destination in the murky depths of the pool
			DestinationComp.MoveTowardsIgnorePathfinding(FVector(Destination.X, Destination.Y, BottomZ), Settings.DetachIntroMoveSpeed); 
		}
		else if (OwnLoc.Z < Destination.Z) 
		{
			// Rise up!
			DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.DetachIntroMoveSpeed);
		}
		else if (DoneTime == BIG_NUMBER)
		{
			DoneTime = ActiveDuration + Settings.DetachIntroPauseDuration;
		}

		DestinationComp.RotateTowards(Target);	

		if (HeadComp.bSubmerged && (OwnLoc.Z > Arena.PoolSurfaceHeight))
		{
			HeadComp.bSubmerged = false;

			FIslandWalkerPoolSurfaceParams Params;
			Params.SurfaceLocation = OwnLoc;
			Params.SurfaceLocation.Z = Arena.PoolSurfaceHeight;
			UIslandWalkerHeadEffectHandler::Trigger_OnIntroRiseOutOfPool(Owner, Params);				
		}

		if (ActiveDuration > DestroySpawnTime)
		{
			DestroySpawnTime = BIG_NUMBER;
			if (SpawnTeam != nullptr)
			{
				for (AHazeActor Spawn : SpawnTeam.GetMembers())
				{
					if (!IsValid(Spawn))
						continue;
					UBasicAIHealthComponent::Get(Spawn).TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
					DestroySpawnTime = ActiveDuration + Math::RandRange(0.3, 0.8);
					break;
				}
			}
		}
	}
}