struct FSkylineBossTankMortarBallImpactedActivateParams
{
	FVector Location;
	FVector Normal;
};

struct FSkylineBossTankMortarBallImpactedDeactivateParams
{
	bool bExplode = false;
	FVector ExplodeLocation = FVector::ZeroVector;
	bool bSpawnShockwaveMio = false;
	bool bSpawnShockwaveZoe = false;
};

class USkylineBossTankMortarBallImpactedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	ASkylineBossTankMortarBall MortarBall;
	UHazeMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	FQuat InitialRotation;
	FQuat TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MortarBall = Cast<ASkylineBossTankMortarBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankMortarBallImpactedActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		FHitResult Impact;
		if(!MortarBall.MoveComp.GetFirstValidImpact(Impact))
			return false;

		Params.Location = Impact.Location;
		Params.Normal = Impact.Normal;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineBossTankMortarBallImpactedDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > MortarBall::DetonationDelay)
		{
			Params.bExplode = true;
			Params.ExplodeLocation = MortarBall.ActorLocation;
			Params.bSpawnShockwaveMio = SceneView::IsInView(Game::Mio, Params.ExplodeLocation, FVector2D(-0.4, 1.4), FVector2D(-0.4, 1.4));
			Params.bSpawnShockwaveZoe = SceneView::IsInView(Game::Zoe, Params.ExplodeLocation, FVector2D(-0.4, 1.4), FVector2D(-0.4, 1.4));
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankMortarBallImpactedActivateParams Params)
	{
		OnImpact(Params.Location, Params.Normal);

		InitialRotation = MortarBall.ActorQuat;
		TargetRotation = FQuat::MakeFromXZ(FVector::DownVector, MortarBall.ActorForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineBossTankMortarBallImpactedDeactivateParams Params)
	{
		if(Params.bExplode)
		{
			Explode(Params.ExplodeLocation, Params.bSpawnShockwaveMio, Params.bSpawnShockwaveZoe);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		float Alpha = Math::Saturate(ActiveDuration / MortarBall::DetonationDelay) * 2;
		Alpha = Math::EaseOut(0, 1, Math::Saturate(Alpha), 2);

		MoveData.SetRotation(FQuat::Slerp(InitialRotation, TargetRotation, Alpha));

		MoveComp.ApplyMove(MoveData);
	}

	private void OnImpact(FVector Location, FVector Normal)
	{
		MortarBall.SetActorLocation(Location);

		FSkylineBossTankMortarBallOnImpactEventData EventData;
		EventData.Location = Location;
		EventData.Normal = Normal;
		USkylineBossTankMortarBallEventHandler::Trigger_OnImpact(MortarBall, EventData);

		MortarBall.OnMortarImpact.Broadcast(Location, Normal);
/*
		for (auto Player : Game::Players)
		{
			MortarBall.DangerWidget[Player] = Player.AddWidget(MortarBall.DangerWidgetClass);
			MortarBall.DangerWidget[Player].AttachWidgetToComponent(MortarBall.TargetDecal);
		}
*/
	}

	private void Explode(FVector ExplodeLocation, bool bSpawnShockwaveMio, bool bSpawnShockwaveZoe)
	{
		MortarBall.SetActorLocation(ExplodeLocation);

		FSkylineBossTankMortarBallOnExplodeEventData EventData;
		EventData.Location = ExplodeLocation;
		USkylineBossTankMortarBallEventHandler::Trigger_OnExplode(MortarBall, EventData);
/*
		if (bSpawnShockwaveMio)
		{
			PrintToScreen("SHOCKWAVE FOR MIO", 2.0);

			auto Shockwave = SpawnActor(MortarBall.ShockwaveClass, ExplodeLocation - FVector::UpVector * 150.0, bDeferredSpawn = true);
			Shockwave.UniqueForPlayer = Game::Mio;
			FinishSpawningActor(Shockwave);
		}

		if (bSpawnShockwaveZoe)
		{
			PrintToScreen("SHOCKWAVE FOR ZOE", 2.0);

			auto Shockwave = SpawnActor(MortarBall.ShockwaveClass, ExplodeLocation - FVector::UpVector * 150.0, bDeferredSpawn = true);
			Shockwave.UniqueForPlayer = Game::Zoe;
			FinishSpawningActor(Shockwave);
		}
*/
		if (MortarBall.FireClass != nullptr)
		{
			bool bShouldSpawnFire = true;

			auto MortarBallComp = USkylineBossTankMortarBallComponent::Get(TListedActors<ASkylineBossTank>().Single);

			for (auto MortarBallFire : MortarBallComp.MortarBallFires)
			{
				if (ExplodeLocation.Distance(MortarBallFire.ActorLocation) < MortarBallFire.Radius)
				{
					bShouldSpawnFire = false;
					break;
				}
			}

			if (bShouldSpawnFire)
			{
				if (MortarBallComp.MortarBallFires.Num() >= MortarBallComp.MaxMortarBallFires)
					MortarBallComp.RemoveOldestFire();

				MortarBallComp.MortarBallFires.Add(
					SpawnActor(MortarBall.FireClass, ExplodeLocation - FVector::UpVector * 150.0, FRotator(0.0, ExplodeLocation.Size(), 0.0))
				);
			}
		}

		MortarBall.DestroyActor();
	}
};