
class UIslandOverseerLaserBombAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(n"Attack");
	default CapabilityTags.Add(n"OpenDoorAttack");

	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerLaserBombComponent LaserBombComp;
	UIslandOverseerDoorComponent DoorComp;
	UAnimInstanceIslandOverseer AnimInstance;

	UIslandOverseerSettings Settings;
	AAIIslandOverseer Overseer;

	FIslandOverseerLaserAttackData Data;
	float TargetDistance = 1000;
	bool bActivatedLasers;
	bool bStoppedLasers;
	float AimYawMin = -0.5;
	float AimYawMax = 0.5;
	FHazeAcceleratedFloat AccAimYaw;

	FHazeAcceleratedFloat AccLaserDistance;

	int Sweeps;
	int MaxSweeps = 2;
	bool bCompletedSweep;
	bool bReverse;

	FVector BombLocation;
	FVector PreviousBombLocation;
	float BombDistance;
	float BombDistanceMin = 200;
	float BombDistanceMax = 400;

	float AnticipationDuration = 1;
	float RecoveryDuration = 1;

	float StartLaserTime;
	float EndTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		LaserBombComp = UIslandOverseerLaserBombComponent::GetOrCreate(Owner);
		DoorComp = UIslandOverseerDoorComponent::GetOrCreate(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Overseer.Mesh.AnimInstance);

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
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagIslandOverseer::LaserBombAttack, SubTagIslandOverseerLaserBombAttack::Start, EBasicBehaviourPriority::Medium, this);
		VisorComp.Open();
		bActivatedLasers = false;
		bCompletedSweep = false;
		bStoppedLasers = false;
		AccAimYaw.SnapTo(0);
		DoorComp.bDoorAttack = true;
		StartLaserTime = 0;
		EndTime = 0;
		Sweeps = 0;
		BombDistance = Math::RandRange(BombDistanceMin, BombDistanceMax);
		PreviousBombLocation = FVector::ZeroVector;
		bReverse = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(1);
		UIslandOverseerEventHandler::Trigger_OnLaserBombAttackStop(Owner, Data);
		DoorComp.bDoorAttack = false;
		AnimComp.AimYaw.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float StartDuration = AnimInstance.LaserBombAttackStart.Sequence.PlayLength;
		if(ActiveDuration < StartDuration)
			return;

		if(ActiveDuration < StartDuration + AnticipationDuration)
		{
			float TargetYaw = bReverse ? AimYawMax : AimYawMin;
			AccAimYaw.AccelerateTo(TargetYaw, AnticipationDuration, DeltaTime);
			AnimComp.AimYaw.Apply(AccAimYaw.Value, this);
			return;
		}

		if(EndTime > 0)
		{
			if(Time::GetGameTimeSince(EndTime) > AnimInstance.LaserBombAttackEnd.Sequence.PlayLength)
				DeactivateBehaviour();
			return;
		}

		if(bCompletedSweep)
		{			
			Sweeps++;
			if(Sweeps < MaxSweeps)
			{
				bCompletedSweep = false;
				bReverse = !bReverse;
				bActivatedLasers = false;
				bStoppedLasers = false;
				return;
			}

			AccAimYaw.AccelerateTo(0, RecoveryDuration, DeltaTime);
			AnimComp.AimYaw.Apply(AccAimYaw.Value, this);

			if(Math::IsNearlyEqual(AccAimYaw.Value, 0, 0.01))
			{
				EndTime = Time::GameTimeSeconds;
				AnimComp.RequestSubFeature(SubTagIslandOverseerLaserBombAttack::End, this);
			}
			return;
		}

		bool bMovingLaser = StartLaserTime > 0 && Time::GetGameTimeSince(StartLaserTime) > 1;
		if(bMovingLaser)
		{
			float Speed = 0.25;
			if(bReverse)
				Speed *= -1;
			AccAimYaw.Value += DeltaTime * Speed;
			AnimComp.AimYaw.Apply(AccAimYaw.Value, this);
		}

		bCompletedSweep = bReverse ? AnimComp.AimYaw.Get() <= AimYawMin : AnimComp.AimYaw.Get() >= AimYawMax;

		bool bStop = AccAimYaw.Value > 0.2;
		if(bReverse)
			bStop = AccAimYaw.Value < -0.2;

		if(!bStoppedLasers && bStop)
		{
			bStoppedLasers = true;
			UIslandOverseerEventHandler::Trigger_OnLaserBombAttackStop(Owner, Data);
		}

		if(!bActivatedLasers)
			ActivateLasers();

		if(bStoppedLasers || !bActivatedLasers)
			return;

		for(UIslandOverseerLaserAttackEmitter Laser : Data.Lasers)
		{
			FRotator HeadRotation = Overseer.Mesh.GetSocketRotation(n"Head");
			FVector PlayerLine = Game::Mio.ActorLocation;
			PlayerLine.Z = Owner.ActorLocation.Z;
			FVector AttackLocation = Math::LinePlaneIntersection(PlayerLine, PlayerLine + Owner.ActorRightVector * 1000, Laser.WorldLocation, HeadRotation.RightVector);
			FVector LaunchDir = (AttackLocation - Laser.WorldLocation).GetSafeNormal();

			if(bMovingLaser)
				Laser.BeamWidth = 150;

			Laser.TrailStart = Laser.WorldLocation + Laser.RightVector * (Laser.BeamWidth * 0.05) + Laser.UpVector * (Laser.BeamWidth * 0.05);
			Laser.Direction = LaunchDir;

			AccLaserDistance.AccelerateTo(TargetDistance, 4, DeltaTime);
			Laser.TrailEnd = Laser.TrailStart + Laser.Direction * AccLaserDistance.Value;			
			Laser.ImpactLocation = Laser.TrailEnd;

			if(bMovingLaser)
			{
				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
				Trace.UseLine();
				Trace.IgnoreActor(Owner);
				FHitResult Hit = Trace.QueryTraceSingle(Laser.TrailStart, Laser.TrailEnd);

				if(Hit.bBlockingHit)
				{
					Laser.ImpactLocation = Hit.Location;
					Laser.TrailEnd = Laser.ImpactLocation;
					auto HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
					if ((HitPlayer != nullptr) && HitPlayer.HasControl())
					{
						HitPlayer.DealBatchedDamageOverTime(Settings.LaserBombAttackPlayerDamagePerSecond * DeltaTime, FPlayerDeathDamageParams());
						HitPlayer.ApplyAdditiveHitReaction(Laser.Direction, EPlayerAdditiveHitReactionType::Small);
						UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(HitPlayer);
					}
				}
			}
		}
	}

	void ActivateLasers()
	{
		bActivatedLasers = true;
		bStoppedLasers = false;
		ActivateLaser(Data.Lasers[0]);
		ActivateLaser(Data.Lasers[1]);
		Data.Type = EIslandOverseerLaserType::Straight;
		UIslandOverseerEventHandler::Trigger_OnLaserBombAttackStart(Owner, Data);
		StartLaserTime = Time::GameTimeSeconds;
	}

	void ActivateLaser(UIslandOverseerLaserAttackEmitter Laser)
	{
		Laser.Direction = Laser.WorldRotation.ForwardVector;
		Laser.BeamWidth = 25;
		Laser.Distance = TargetDistance;
		AccLaserDistance.SnapTo(0);
	}
}