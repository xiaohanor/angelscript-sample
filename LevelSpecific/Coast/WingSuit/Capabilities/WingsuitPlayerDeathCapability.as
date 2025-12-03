class UWingsuitPlayerDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Death");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UWingSuitPlayerComponent WingSuitComp;
	UPlayerMovementComponent MoveComp;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthComponent HealthComp;
	UWingSuitSettings Settings;
	AWingSuit ActiveWingSuit;
	FSplinePosition RespawnPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UWingSuitSettings::GetSettings(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
		HealthComp = UPlayerHealthComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WingSuitComp.bWingsuitActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WingSuitComp.bWingsuitActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ActiveWingSuit = WingSuitComp.WingSuit;
		
		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"GetRespawnLocation");
		RespawnComp.ApplyRespawnOverrideDelegate(this, RespawnOverride, EInstigatePriority::Normal);

		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnComp.ClearRespawnOverride(this);
		RespawnComp.OnPlayerRespawned.Unbind(this, n"OnRespawn");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		const FVector Velocity = MoveComp.Velocity;
		const FVector MoveDir = Velocity.GetSafeNormal();

		// Moving deaths
		if(!Velocity.IsNearlyZero())
		{
			if(MoveComp.HasWallContact())
			{		
				float ImpactAngle = Math::DotToDegrees(MoveComp.WallContact.ImpactNormal.DotProduct(MoveDir));
				if(ImpactAngle > Settings.WallImpactDeathAngleMax)
				{
					KillPlayer();
				}
			}
			else if(MoveComp.HasCeilingContact())
			{
				float ImpactAngle = Math::DotToDegrees(MoveComp.CeilingContact.ImpactNormal.DotProduct(MoveDir));
				if(ImpactAngle > Settings.CeilingImpactDeathAngleMax)
				{
					KillPlayer();
				}
			}
			else if(MoveComp.HasGroundContact())
			{
				float ImpactAngle = Math::DotToDegrees(MoveComp.GroundContact.ImpactNormal.DotProduct(MoveDir));
				if(ImpactAngle > Settings.GroundImpactDeathAngleMax)
				{
					KillPlayer();
				}
			}
		}		
	}

	UFUNCTION()
	void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		if(WingSuitComp.bShouldRespawnInWaterski)
		{
			DeactivateWingSuit(Player);
			auto WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
			WaterskiComp.StartWaterskiing(WingSuitComp.RespawnInWaterskiAttachPoint, false);
			FRespawnLocation RespawnLocation;
			WaterskiComp.GetRespawnTransform(RespawnLocation);
			Player.TeleportActor(RespawnLocation.RespawnTransform.Location, RespawnLocation.RespawnTransform.Rotator(), WingSuitComp);
		}

		if(!WingSuitComp.bWingSuitSplineRespawningActive.Get())
		{
			if(WingSuitComp.bDisableWingsuitOnRespawnBlock.Get())
				DeactivateWingSuit(Player);
			return;
		}

		FVector StartVelocity = RespawnPosition.WorldForwardVector * (1000 + Player.GetActorVelocity().Size());
		RespawnedPlayer.SetActorVelocity(StartVelocity);
		WingSuitComp.AutoSteeringTimeLeft = Settings.AutoSteeringTimeAfterDeath;
		
		if(WingSuitComp.bWingsuitActive)
			WingSuitComp.bShouldSnapCameraPostRespawn = true;
	}

	UFUNCTION()
	bool GetRespawnLocation(AHazePlayerCharacter RespawnPlayer, FRespawnLocation& OutLocation)
	{
		if(!WingSuitComp.bWingSuitSplineRespawningActive.Get())
			return false;

		TPerPlayer<AWingSuit> WingSuits;
		WingSuits[RespawnPlayer] = Manager.GetWingSuit(RespawnPlayer);
		WingSuits[RespawnPlayer.OtherPlayer] = Manager.GetWingSuit(RespawnPlayer.OtherPlayer);

		TPerPlayer<FSplinePosition> ClosestSplinePosition;
		ClosestSplinePosition[RespawnPlayer] = Manager.GetClosestSplineRespawnPosition(WingSuits[RespawnPlayer].ActorLocation);
		ClosestSplinePosition[RespawnPlayer.OtherPlayer] = Manager.GetClosestSplineRespawnPosition(WingSuits[RespawnPlayer.OtherPlayer].ActorLocation);
		RespawnPosition = ClosestSplinePosition[RespawnPlayer];

		int AHeadIndex = -1;
		int BehindIndex = -1;

		if(ClosestSplinePosition[0].CurrentSplineDistance >= ClosestSplinePosition[1].CurrentSplineDistance)
		{
			AHeadIndex = 0;
			BehindIndex = 1;
		}
		else
		{
			AHeadIndex = 1;
			BehindIndex = 0;
		}

		const float Distance = ClosestSplinePosition[AHeadIndex].CurrentSplineDistance - ClosestSplinePosition[BehindIndex].CurrentSplineDistance;
		const bool bIsAhead = WingSuits[RespawnPlayer] == WingSuits[AHeadIndex];
		if(bIsAhead)
		{
			if(Settings.MaxRespawnDistanceWhenAHead >= 0)
			{
				const float MaxDistance = Settings.MaxRespawnDistanceWhenAHead;
				RespawnPosition = ClosestSplinePosition[BehindIndex];
				RespawnPosition.Move(Math::Min(Distance, MaxDistance));
			}	
		}
		else
		{
			if(Settings.MaxRespawnDistanceWhenBehind >= 0)
			{
				const float MaxDistance = Settings.MaxRespawnDistanceWhenBehind;
				RespawnPosition = ClosestSplinePosition[AHeadIndex];
				RespawnPosition.Move(-Math::Min(Distance, MaxDistance));
			}
		}

		OutLocation.RespawnTransform = RespawnPosition.WorldTransform;
		OutLocation.bRecalculateOnRespawnTriggered = true;
		return true;
	}

	void KillPlayer()
	{		
		Player.KillPlayer(FPlayerDeathDamageParams(FVector(0.0), 3.0, NewCameraStopDuration = 0.2), DeathEffect = WingSuitComp.DefaultDeathEffect);
	}

	AWingsuitManager GetManager() const property
	{
		return WingSuitComp.Manager;
	}
};