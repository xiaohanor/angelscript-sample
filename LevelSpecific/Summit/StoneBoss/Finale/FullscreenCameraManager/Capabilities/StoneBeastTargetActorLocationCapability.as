class UStoneBeastTargetActorLocationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AStoneBeastTargetActor TargetActor;
	FHazeAcceleratedVector AccelHorizontalVec;
	FHazeAcceleratedVector AccelVericalVec;

	UTeleportResponseComponent TeleportComp;

	TPerPlayer<UHazeMovementComponent> MoveComps;
	TPerPlayer<FVector> LastRelativeGroundLocation;
	TPerPlayer<AActor> AttachedSegment;

	float ZoeDeathTime;

	float VerticalAccelerateTime;
	float VerticalAccelerateTarget = 1.45;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetActor = Cast<AStoneBeastTargetActor>(Owner);
		MoveComps[Game::Mio] = UHazeMovementComponent::Get(Game::Mio);
		MoveComps[Game::Zoe] = UHazeMovementComponent::Get(Game::Zoe);

		TeleportComp = UTeleportResponseComponent::Get(Game::Zoe);

		TeleportComp.OnTeleported.AddUFunction(this, n"OnTeleported");
		UPlayerHealthComponent::Get(Game::Zoe).OnFinishDying.AddUFunction(this, n"OnFinishDying");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TargetActor.bHasInitialized)
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
		AccelHorizontalVec.SnapTo(GetTargetLocation());
		AccelVericalVec.SnapTo(GetTargetLocation());
		TargetActor.ActorLocation = AccelHorizontalVec.Value;
		VerticalAccelerateTime = VerticalAccelerateTarget;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TargetActor.Leader != nullptr)
		{
			TargetActor.ActorLocation = TargetActor.Leader.ActorLocation;
			return;
		}

		VerticalAccelerateTime = Math::FInterpConstantTo(VerticalAccelerateTime, VerticalAccelerateTarget, DeltaTime, 2.5);

		FVector TargetLocation = GetTargetLocation();
		AccelHorizontalVec.AccelerateTo(TargetLocation, 1.1, DeltaTime);
		AccelVericalVec.AccelerateTo(TargetLocation, VerticalAccelerateTime, DeltaTime);

		TargetActor.ActorLocation = FVector(AccelHorizontalVec.Value.X, AccelHorizontalVec.Value.Y, AccelVericalVec.Value.Z);
	}
	
	UFUNCTION()
	private void OnTeleported()
	{
		// Don't snap camera target if zoe has teleported due to a respawn, as target should already be on Mio in that case
		float TimeSinceSpawn = Time::GetGameTimeSince(ZoeDeathTime);
		if (TimeSinceSpawn < 3)
			return;

		AccelHorizontalVec.SnapTo(GetTargetLocation());
		AccelVericalVec.SnapTo(GetTargetLocation());
		TargetActor.ActorLocation = AccelHorizontalVec.Value;
		VerticalAccelerateTime = VerticalAccelerateTarget;
	}

	UFUNCTION()
	private void OnFinishDying()
	{
		ZoeDeathTime = Time::GameTimeSeconds;
	}

	FVector GetTargetLocation()
	{
		if (TargetActor.AlivePlayers.Num() > 1)
		{
			return (GetPlayersLocation(TargetActor.AlivePlayers[0]) + GetPlayersLocation(TargetActor.AlivePlayers[1])) / 2;
		}
		else if (TargetActor.AlivePlayers.Num() == 1)
		{
			return GetPlayersLocation(TargetActor.AlivePlayers[0]);
		}

		return TargetActor.ActorLocation;
	}

	FVector GetPlayersLocation(AHazePlayerCharacter Player)
	{
		if(MoveComps[Player].IsOnAnyGround())
		{
			AttachedSegment[Player] = MoveComps[Player].GroundContact.Actor.GetAttachParentActor();

			if (AttachedSegment[Player] == nullptr)
				return Player.ActorLocation;

			FVector ImpactLocation = MoveComps[Player].GroundContact.ImpactPoint;
			LastRelativeGroundLocation[Player] = AttachedSegment[Player].ActorTransform.InverseTransformPosition(ImpactLocation);
		}

		if (AttachedSegment[Player] == nullptr)
			return Player.ActorLocation;

		float HeightDiff = AttachedSegment[Player].ActorTransform.InverseTransformPosition(Player.ActorLocation).Z - LastRelativeGroundLocation[Player].Z;

		if (TargetActor.bDebugOn)
		{
			// if (Player.IsMio())
			// {
			// 	// PrintToScreen(f"{HeightDiff=}");
			// 	PrintToScreen(f"{VerticalAccelerateTime=}");
			// 	// PrintToScreen("LastRelativeGroundLocation[Player]: " + LastRelativeGroundLocation[Player]);
			// }
		}

		if (HeightDiff >= -10.0) 
		{
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.UseLine();
			TraceSettings.IgnoreActor(Player);
			TraceSettings.IgnoreActor(Player.OtherPlayer);

			FVector Start = Player.ActorLocation + AttachedSegment[Player].ActorUpVector * 50.0;
			FHitResult Hit = TraceSettings.QueryTraceSingle(Start, Start + -FVector::UpVector * 450.0); 
			FVector HeightImpact = Player.ActorLocation;
		 	if (Hit.bBlockingHit)
			{
				HeightImpact = Hit.ImpactPoint;
			}

			if (TargetActor.bDebugOn)
			{
				// if (Player.IsMio())
				// {
				// 	Debug::DrawDebugSphere(FVector(Player.ActorLocation.X, Player.ActorLocation.Y, LastRelativeGroundLocation[Player].Z), 40.0, 12, FLinearColor::Green, 10.0);
				// 	PrintToScreen(f"RETURN GROUNDED " + AttachedSegment[Player].Name);
				// }
			}

			return FVector(Player.ActorLocation.X, Player.ActorLocation.Y, HeightImpact.Z);  
		}
		else
		{
			if (TargetActor.bDebugOn)
			{
				// if (Player.IsMio())
				// {
				// 	Debug::DrawDebugSphere(Player.ActorLocation, 150.0, 12, FLinearColor::Green, 10.0);
				// 	PrintToScreen(f"RETURN LOCATION " + AttachedSegment[Player].Name);
				// 	// Print(f"{HeightDiff=}");
				// }
			}

			return Player.ActorLocation;
		}
	}
};