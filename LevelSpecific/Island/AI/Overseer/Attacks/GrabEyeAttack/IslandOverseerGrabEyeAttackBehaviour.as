
class UIslandOverseerGrabEyeAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerVisorComponent VisorComp;

	UIslandOverseerSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;

	FIslandOverseerLaserAttackData Data;
	float TargetDistance = 3000;
	bool bActivated;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);

		Data = FIslandOverseerLaserAttackData();
		Owner.GetComponentsByClass(UIslandOverseerLaserAttackEmitter, Data.Lasers);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;		
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Durations.Telegraph = 2.31;
		Durations.Recovery = 1.77;
		Durations.Action = 13 - Durations.Telegraph - Durations.Recovery;
		AnimComp.RequestAction(FeatureTagIslandOverseer::GrabEye, EBasicBehaviourPriority::Medium, this, Durations);
		VisorComp.Open();
		bActivated = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(3);
		UIslandOverseerEventHandler::Trigger_OnLaserAttackStop(Owner, Data);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Durations.IsInTelegraphRange(ActiveDuration))
			return;

		if(Durations.IsInRecoveryRange(ActiveDuration))
		{
			if(bActivated)
			{
				bActivated = false;
				UIslandOverseerEventHandler::Trigger_OnLaserAttackStop(Owner, Data);
			}
			return;
		}

		if(!bActivated)
		{
			bActivated = true;
			ActivateLaser(Data.Lasers[0]);
			ActivateLaser(Data.Lasers[1]);
			Data.Type = EIslandOverseerLaserType::Straight;
			UIslandOverseerEventHandler::Trigger_OnLaserAttackStart(Owner, Data);
		}

		for(UIslandOverseerLaserAttackEmitter Laser : Data.Lasers)
		{
			Laser.TrailStart = Laser.WorldLocation;
			Laser.Direction = Overseer.Mesh.GetSocketRotation(n"LeftEye").UpVector;
			Laser.TrailEnd = Laser.TrailStart + Laser.Direction * Laser.Distance;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			Trace.IgnoreActor(Owner);
			FHitResult Hit = Trace.QueryTraceSingle(Laser.TrailStart, Laser.TrailEnd);

			if(Hit.bBlockingHit)
			{
				auto HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				if ((HitPlayer != nullptr) && HitPlayer.HasControl())
				{
					HitPlayer.DealBatchedDamageOverTime(Settings.LaserAttackPlayerDamagePerSecond * DeltaTime, FPlayerDeathDamageParams());
					HitPlayer.ApplyAdditiveHitReaction(Laser.Direction, EPlayerAdditiveHitReactionType::Small);
					UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(HitPlayer);
				}
			}
		}
	}

	void ActivateLaser(UIslandOverseerLaserAttackEmitter Laser)
	{
		Laser.Direction = Laser.WorldRotation.ForwardVector;
		Laser.BeamWidth = 50;
		Laser.Distance = TargetDistance;
	}
}