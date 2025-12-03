class UStoneBeastPlayerRespawnCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(n"StoneBeastPlayerRespawn");

	default TickGroup = EHazeTickGroup::BeforeMovement;

	bool bHasBlockedRespawn;

	USceneComponent RespawnSceneComp;

	float MaxLookAheadDistance = 200;

	FSplinePosition RespawnSplinePosition;
	bool bCanRespawn;
	bool bCanActivate = true;
	UDragonSwordUserComponent SwordComp;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SwordComp == nullptr)
			SwordComp = UDragonSwordUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Player);
		RespawnSceneComp = USceneComponent::Create(Player, n"StoneBeastRespawnSceneComp");
		Player.ApplyDefaultSettings(StonebeastPlayerSpline::StoneBeastPlayerDefaultRespawnSettings);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SwordComp == nullptr)
			return false;

		if (!SwordComp.SwordIsActive())
			return false;
		
		if (!bCanActivate)
			return false;
		
		if (StonebeastPlayerSpline::GetClosestPlayerSpline(Player.ActorLocation) == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandlePlayerRespawn"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearRespawnPointOverride(this);
		if (bHasBlockedRespawn)
		{
			Player.UnblockCapabilities(n"Respawn", this);
		}
		bHasBlockedRespawn = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateRespawn();

		if (!bCanRespawn && !bHasBlockedRespawn)
		{
			Player.BlockCapabilities(n"Respawn", this);
			bHasBlockedRespawn = true;
		}
		else if (bCanRespawn && bHasBlockedRespawn)
		{
			Player.UnblockCapabilities(n"Respawn", this);
			bHasBlockedRespawn = false;
		}

		//Debug::DrawDebugSphere(RespawnSceneComp.WorldLocation, 100, 4, Player.IsMio() ? PlayerColor::Mio : PlayerColor::Zoe);
	}

	void UpdateRespawn()
	{
		if (Player.OtherPlayer.IsPlayerDead() || Player.OtherPlayer.IsPlayerRespawning())
		{
			bCanRespawn = false;
			return;
		}

		auto ClosestPlayerSpline = StonebeastPlayerSpline::GetClosestPlayerSpline(Player.OtherPlayer.ActorCenterLocation);
		auto ClosestSplinePosition = ClosestPlayerSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.OtherPlayer.ActorCenterLocation);
		
		auto ClosestAlongSplineData = ClosestPlayerSpline.Spline.FindClosestComponentAlongSpline(UStoneBeastPlayerSplineRespawnZoneComponent, false, ClosestSplinePosition.CurrentSplineDistance + MaxLookAheadDistance);
		if (!ClosestAlongSplineData.IsSet())
		{
			bCanRespawn = false;
			return;
		}

		auto RespawnZoneComp = Cast<UStoneBeastPlayerSplineRespawnZoneComponent>(ClosestAlongSplineData.Value.Component);
		auto RespawnSettings = Player.OtherPlayer.GetSettings(UStoneBeastPlayerRespawnSettings); //get settings from otherplayer

		float SpawnDistance = RespawnSettings.RespawnDistance;

		FSplinePosition SplinePosition;
		if (!RespawnZoneComp.TryGetRespawnSplinePositionInsideZone(ClosestSplinePosition.CurrentSplineDistance, SpawnDistance, SplinePosition))
		{
			bCanRespawn = false;
			return;
		}

		RespawnSplinePosition = SplinePosition;
		bCanRespawn = true;
	}

	UFUNCTION()
	private bool HandlePlayerRespawn(AHazePlayerCharacter _, FRespawnLocation& OutLocation)
	{
		auto OtherPlayer = Player.OtherPlayer;

		FHazeTraceSettings RespawnTrace;
		RespawnTrace.UseLine();
		RespawnTrace.TraceWithPlayerProfile(OtherPlayer);
		// RespawnTrace.DebugDraw(5);
		auto Hit = RespawnTrace.QueryTraceSingle(RespawnSplinePosition.WorldLocation, RespawnSplinePosition.WorldLocation + FVector::DownVector * 20000);

		if (!Hit.bBlockingHit)
		{
			OutLocation.RespawnTransform = RespawnSplinePosition.WorldTransform;
		}
		else
		{
			RespawnSceneComp.WorldLocation = Hit.ImpactPoint;
			RespawnSceneComp.WorldRotation = RespawnSplinePosition.WorldRotation.Rotator();
			RespawnSceneComp.AttachTo(Hit.Component, NAME_None, EAttachLocation::KeepWorldPosition);
			OutLocation.RespawnRelativeTo = RespawnSceneComp;
		}

		return true;
	}
};