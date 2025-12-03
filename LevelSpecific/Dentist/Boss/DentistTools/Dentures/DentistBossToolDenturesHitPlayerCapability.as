struct FDentistBossToolDenturesHitPlayerActivationParams
{
	TArray<AHazePlayerCharacter> HitPlayers;
}

class UDentistBossToolDenturesHitPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;

	UDentistBossSettings Settings;

	const float TraceStartForwardsOffset = 50.0;
	const float TraceEndDelta = 50.0;
	const float TraceHeightExtentSubtraction = 20.0;

	TPerPlayer<bool> HasHitPlayerSinceJumpStarted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();
		Dentures.OnJump.AddUFunction(this, n"OnDenturesJumped");

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistBossToolDenturesHitPlayerActivationParams& Params) const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.bActive)
			return false;

		if(!Dentures.bShouldTraceForPlayerInFront)
			return false;
		
		auto HitPlayers = TraceForPlayersInFront();
		if(HitPlayers.IsEmpty())
			return false;

		Params.HitPlayers = HitPlayers;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistBossToolDenturesHitPlayerActivationParams Params)
	{
		for(auto Player : Params.HitPlayers)
		{
			if(Dentures.TargetPlayer.Value == Player)
				Dentures.bHasHitTarget = true;

			ApplyImpulseToPlayer(Player);
			UDentistToothDashComponent::Get(Player).ResetDashUsage();
			Player.DamagePlayerHealth(Settings.DenturesHitPlayerDamage);

			FDentistBossEffectHandlerOnDenturesBitePushPlayerParams EventParams;
			EventParams.Dentures = Dentures;
			EventParams.PushedPlayer = Player;
			UDentistBossEffectHandler::Trigger_OnDenturesPushBitePlayer(Dentist, EventParams);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	
	}

	TArray<AHazePlayerCharacter> TraceForPlayersInFront() const
	{
		TArray<AHazePlayerCharacter> PlayersInFront;

		for(auto Player : Game::Players)
		{
			if(HasHitPlayerSinceJumpStarted[Player])
				continue;

			if(Settings.bPlayersImmortalToDenturesDuringDash)
			{
				auto DashComp = UDentistToothDashComponent::Get(Player);
				if(DashComp.IsDashing())
					continue;
			}

			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Player.CapsuleComponent);
			FVector BoxExtents = Dentures.BoxComp.ScaledBoxExtent;
			BoxExtents.Z -= TraceHeightExtentSubtraction; // Don't want to hit anything on top
			FVector TopOfTraceBox = Dentures.BoxComp.WorldLocation + FVector::UpVector * (BoxExtents.Z * 0.5);
			float BoxTopHeightOverCake = (TopOfTraceBox - Dentist.Cake.ActorLocation).DotProduct(FVector::UpVector);
			BoxExtents.Z = BoxTopHeightOverCake * 0.5;

			FVector TraceBoxLocation = Dentures.BoxComp.WorldLocation
				+ Dentures.BoxComp.ForwardVector * TraceStartForwardsOffset;
			TraceBoxLocation.Z = Dentist.Cake.ActorLocation.Z + BoxTopHeightOverCake * 0.5;

			FHazeTraceShape Shape = FHazeTraceShape::MakeBox(BoxExtents, Dentures.BoxComp.ComponentQuat);
			Trace.UseShape(Shape);
			Trace.IgnoreActor(Dentures);

			FVector Start = TraceBoxLocation;
			FVector End = Start + Dentures.BoxComp.ForwardVector * TraceEndDelta;
			auto Hit = Trace.QueryTraceComponent(Start, End);

			TEMPORAL_LOG(Dentures)
				.HitResults(f"{Player} trace", Hit, Shape)
			;

			if(Hit.bBlockingHit)
			{
				auto HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(HitPlayer == nullptr)
					continue;
				
				bool bPlayerHasBeenHit = false;
				if(!bPlayerHasBeenHit)
					PlayersInFront.Add(HitPlayer);
			}
		}

		return PlayersInFront;
	} 

	UFUNCTION()
	private void OnDenturesJumped()
	{
		HasHitPlayerSinceJumpStarted[EHazePlayer::Mio] = false;
		HasHitPlayerSinceJumpStarted[EHazePlayer::Zoe] = false;
	}

	void ApplyImpulseToPlayer(AHazePlayerCharacter Player)
	{
		FVector Impulse;
		Impulse += Dentures.BoxComp.ForwardVector * Settings.DenturesHitPlayerForwardImpulse;
		Impulse += FVector::UpVector * Settings.DenturesHitPlayerUpImpulse;
		UDentistToothImpulseResponseComponent::Get(Player).OnImpulseFromObstacle.Broadcast(Dentures, Impulse, Settings.DenturesHitPlayerRagdollSettings);
		HasHitPlayerSinceJumpStarted[Player] = true;
	}
};