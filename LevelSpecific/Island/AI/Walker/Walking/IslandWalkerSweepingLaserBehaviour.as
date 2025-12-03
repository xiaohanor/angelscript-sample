struct FWalkerLaserTargetData
{
	AHazePlayerCharacter Player;
	UTargetTrailComponent TrailComp;
	FVector LocalLocation;
	FVector LocalVelocity;
	FHazeAcceleratedFloat AccDelay;
}

class UIslandWalkerSweepingLaserBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandWalkerSettings Settings;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerShellCasingsLauncher CasingsLauncher;

	FWalkerLaserTargetData TargetData;
	FBasicAIAnimationActionDurations Durations;
	bool bActiveLaser = false;

	float EjectShellTime;
	float EjectShellInterval;
	FVector CasingsLauncherPrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		CasingsLauncher = UIslandWalkerShellCasingsLauncher::Get(Owner);
		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

// Testing hack
// UFUNCTION(BlueprintOverride)
// void PreTick(float DeltaTime)
// {
// 	WalkerComp.LastAttack = EISlandWalkerAttackType::None;
// 	Cooldown.Reset();
// }

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
 		if (!WalkerComp.CanPerformAttack(EISlandWalkerAttackType::Laser))
 			return false;
		float NearRadius = Settings.LaserBeamWidth * 5.0 + 200.0;
		float FarRadius = NearRadius + Settings.LaserRange * Math::Tan(Math::DegreesToRadians(Settings.LaserValidAngle * 0.25));
		FVector FarCenter = Swivel.WorldLocation + Swivel.ForwardVector * (Settings.LaserRange - FarRadius);
		if (!TargetComp.Target.ActorLocation.IsInsideTeardrop(Swivel.WorldLocation, FarCenter, NearRadius, FarRadius))
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

		WalkerComp.LastAttack = EISlandWalkerAttackType::Laser;
		bActiveLaser = false;

		WalkerComp.Laser.EndLocation = Owner.ActorLocation + Owner.ActorForwardVector * 2700;
		TargetData.LocalLocation = GetLaserTransform().InverseTransformPosition(WalkerComp.Laser.EndLocation);
		TargetData.LocalVelocity = FVector::ZeroVector;
		TargetData.AccDelay.SnapTo(1.0);
		TargetData.Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TargetData.TrailComp = UTargetTrailComponent::GetOrCreate(TargetData.Player);

		Durations.Telegraph = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::SweepingLaser, SubTagWalkerSweepingLaser::Start, Settings.LaserTelegraphDuration);
		Durations.Anticipation = 0.0; // Not used, played as threeshot
		Durations.Action = Settings.LaserDuration;
		Durations.Recovery = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::SweepingLaser, SubTagWalkerSweepingLaser::Start, Settings.LaserRecoverDuration);
		AnimComp.RequestFeature(FeatureTagWalker::SweepingLaser, SubTagWalkerSweepingLaser::Start, EBasicBehaviourPriority::Medium, this, Durations.Telegraph);
		WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::SweepingLaser, SubTagWalkerSweepingLaser::Start, EBasicBehaviourPriority::Medium, this, Durations.Telegraph);

		CasingsLauncher.ReserveShellCasings(Math::TruncToInt(Durations.Action * Settings.GatlingCasingsPerSecond) + 1);
		EjectShellTime = Durations.PreActionDuration;
		EjectShellInterval = 1.0 / float(Settings.GatlingCasingsPerSecond);
		CasingsLauncherPrevLocation = CasingsLauncher.WorldLocation;

		UIslandWalkerEffectHandler::Trigger_OnTelegraphLaser(Owner, FIslandWalkerLaserEventData(WalkerComp.Laser, Settings.LaserBeamWidth));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.LaserCooldown);
		
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	

		if (bActiveLaser)
			UIslandWalkerEffectHandler::Trigger_OnStoppedLaser(Owner);
	}

	FTransform GetLaserTransform()
	{
		return Owner.ActorTransform;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bActiveLaser)
		{
			if (Durations.IsInActionRange(ActiveDuration))
			{
				bActiveLaser = true;
				UIslandWalkerEffectHandler::Trigger_OnStartedLaser(Owner, FIslandWalkerLaserEventData(WalkerComp.Laser, Settings.LaserBeamWidth));
			}
		}
		else if (Durations.IsInRecoveryRange(ActiveDuration))
		{
			bActiveLaser = false;
			AnimComp.RequestFeature(FeatureTagWalker::SweepingLaser, SubTagWalkerSweepingLaser::End, EBasicBehaviourPriority::Medium, this, Durations.GetTotal() - ActiveDuration);
			UIslandWalkerEffectHandler::Trigger_OnStoppedLaser(Owner);
		}

		if (bActiveLaser)
		{
			float TrailAge = TargetData.AccDelay.AccelerateTo(Settings.LaserLagBehindTargetTime, Durations.GetPreRecoveryDuration() * 0.2, DeltaTime);
			FVector TargetLoc = TargetData.TrailComp.GetTrailLocation(TrailAge);
			TargetLoc.Z = Owner.ActorLocation.Z + 60.0;

			// Track targets
			FTransform Transform = GetLaserTransform();
			FVector LocalToTarget = Transform.InverseTransformPosition(TargetLoc) - TargetData.LocalLocation;
			if (IsValidAngle(TargetData.Player) && !LocalToTarget.IsNearlyZero(40.0))
			{
				// Accelerate towards target
				TargetData.LocalVelocity += LocalToTarget.GetSafeNormal() * Settings.LaserFollowSpeed * DeltaTime;
			}
			// Apply friction
			TargetData.LocalVelocity *= Math::Pow(Math::Exp(-Settings.LaserFollowDamping), DeltaTime);
			TargetData.LocalLocation += TargetData.LocalVelocity * DeltaTime; 

			FVector EmissionLoc = WalkerComp.Laser.WorldLocation;
			FVector EndLocation = Transform.TransformPosition(TargetData.LocalLocation);
			FVector LaserDirection = (EndLocation -EmissionLoc).GetSafeNormal();
			FVector LaserEndLocation = EmissionLoc + LaserDirection * Settings.LaserRange;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			Trace.IgnoreActor(Owner);
			FHitResult Hit = Trace.QueryTraceSingle(EmissionLoc, LaserEndLocation);

			if(Hit.bBlockingHit)
			{
				LaserEndLocation = Hit.ImpactPoint;
				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if ((Player != nullptr) && Player.HasControl())
				{
					Player.DealTypedDamageBatchedOverTime(Owner, 8.0 * DeltaTime, EDamageEffectType::ProjectilesLarge, EDeathEffectType::ProjectilesLarge);
					Player.ApplyAdditiveHitReaction(LaserDirection, EPlayerAdditiveHitReactionType::Small);
					UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(Player);
				}
			}
			WalkerComp.Laser.EndLocation = LaserEndLocation;

			if ((ActiveDuration > EjectShellTime) && (DeltaTime > 0.0))
			{
				// Launch a shell casing, inheriting velocity from launcher (clamped for safety) with some scatter
				CasingsLauncher.Launch((CasingsLauncher.WorldLocation - CasingsLauncherPrevLocation) / DeltaTime);
				EjectShellTime += EjectShellInterval;
			}
		}
		CasingsLauncherPrevLocation = CasingsLauncher.WorldLocation;

		Swivel.Realign(Durations.Telegraph + Durations.Anticipation, DeltaTime);
	}

	private bool IsValidTarget(AHazePlayerCharacter Player) const
	{
		if(!Player.OtherPlayer.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.LaserRange))
			return false;

		if(!IsValidAngle(Player))
			return false;

		return true;
	}

	private bool IsValidAngle(AHazeActor Target) const
	{
		FVector Direction = Target.ActorLocation - Owner.ActorCenterLocation;
		Direction.Normalize();
		float Angle = Owner.ActorForwardVector.GetAngleDegreesTo(Direction);
		return Angle < Settings.LaserValidAngle;
	}
}