struct FDentistBossSpitOutDenturesActivationParams
{
	float Duration;
}

class UDentistBossSpitOutDenturesCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolDentures Dentures;

	UHazeMovementComponent MoveComp;

	FDentistBossSpitOutDenturesActivationParams Params;
	UDentistBossSettings Settings;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
		MoveComp = UHazeMovementComponent::Get(Dentures);
				
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossSpitOutDenturesActivationParams InParams)
	{
		Params = InParams;

		FDentistBossEffectHandlerOnDenturesReleasedParams EffectParams;
		EffectParams.Dentures = Dentures;
		UDentistBossEffectHandler::Trigger_OnDenturesReleased(Dentist, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Params.Duration)
			return true;

		if(IsOnGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentures.AttachToComponent(Dentist.SkelMesh, n"Align");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentures.DetachFromActor(EDetachmentRule::KeepWorld);
		Dentures.bIsAttachedToJaw = false;
		Dentures.ActorLocation = Dentist.Cake.ActorLocation + DentistBossMeasurements::DenturesLandRelativeLocation;
		Dentures.EyesSpringinessEnabled.Clear(Dentures);

		Dentures.SetActorVelocity(FVector::ZeroVector);
		Dentures.bHasLandedOnGround = true;
		Dentures.LastTimeLandedOnGround = Time::GameTimeSeconds;

		float ClosestDistSqrd = MAX_flt;
		for(auto Player : Game::Players)
		{
			float DistSqrd = Player.ActorLocation.DistSquared2D(Dentures.ActorLocation, FVector::UpVector);
			if(DistSqrd < ClosestDistSqrd)
			{
				Dentures.TargetPlayer.Set(Player);
				ClosestDistSqrd = DistSqrd;
			}
		}
		
		FDentistBossEffectHandlerOnDenturesLandedParams EffectParams;
		EffectParams.Dentures = Dentures;
		UDentistBossEffectHandler::Trigger_OnDenturesLanded(Dentist, EffectParams);
	}

	bool IsOnGround() const
	{
		FHazeTraceSettings GroundTrace;
		GroundTrace.TraceWithComponent(Dentures.BoxComp);
		GroundTrace.IgnorePlayers();
		GroundTrace.IgnoreActor(Dentures);
		GroundTrace.IgnoreActor(Dentist);

		FVector Start = Dentures.ActorLocation;
		FVector End = Start + FVector::DownVector * 20.0;
		auto Hit = GroundTrace.QueryTraceSingle(Start, End);
		TEMPORAL_LOG(Dentures).HitResults("Landing Trace", Hit, MoveComp.CollisionShape);
		if(Hit.bBlockingHit)
		{
			if(Hit.Actor.IsA(ADentistBossCake))
				return true;
			else
				return false;
		}

		return false;
	}
};