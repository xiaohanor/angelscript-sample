struct FWingsuitBossMachineGunAttackActivatedParams
{
	AHazePlayerCharacter PlayerTarget;
}

class UWingsuitBossMachineGunAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(WingsuitBossTags::WingsuitBossAttack);
	default CapabilityTags.Add(WingsuitBossTags::WingsuitBossMachineGun);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AWingsuitBoss Boss;
	UWingsuitBossSettings Settings;
	FVector Direction;
	FVector TangentDirection;
	AHazePlayerCharacter PreviousPlayerShotOn;
	TOptional<float> TimeOfDone;
	float TimeOfLastShot = -100.0;
	bool bShootFromRightMuzzle = true;
	float DistanceToPlayer;
	AOceanWavePaint OceanWavePaint;
	float DistanceOffset;
	FVector InterpedPlayerRelativeLocation;

	FInstigator RightWaveInstigator = FInstigator(this, n"RightTurret");
	FInstigator LeftWaveInstigator = FInstigator(this, n"LeftTurret");

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PreviousPlayerShotOn = Game::Mio;
		Boss = Cast<AWingsuitBoss>(Owner);
		Settings = UWingsuitBossSettings::GetSettings(Owner);
		OceanWavePaint = TListedActors<AOceanWavePaint>().Single;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("Offset", DistanceOffset);
		TemporalLog.Point("Player Location", GetPlayerLocation(), 20.f);
		TemporalLog.Point("Shoot Target Right Location", GetShootTargetLocation(true), 20.f, FLinearColor::Green);
		TemporalLog.Point("Shoot Target Left Location", GetShootTargetLocation(false), 20.f, FLinearColor::Green);
		TemporalLog.Value("Current Delay", OceanWaves::GetCurrentDelayInSeconds());
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWingsuitBossMachineGunAttackActivatedParams& Params) const
	{
		if(!Boss.bWeaponsActive)
			return false;

		if(DeactiveDuration < Settings.MachineGunDelayBetweenBursts)
			return false;

		Params.PlayerTarget = PreviousPlayerShotOn.OtherPlayer;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.bWeaponsActive)
			return true;

		if(TimeOfDone.IsSet() && Time::GetGameTimeSince(TimeOfDone.Value) > Settings.MachineGunPostBurstDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWingsuitBossMachineGunAttackActivatedParams Params)
	{
		if(OceanWavePaint == nullptr)
			OceanWavePaint = TListedActors<AOceanWavePaint>().Single;

		TimeOfDone.Reset();
		PreviousPlayerShotOn = Params.PlayerTarget;
		UpdateDirectionAndDistance(0.0, true);
		Boss.OverrideTargetRotation.Apply(FRotator::MakeFromXZ(Direction, FVector::UpVector), this);
		Boss.AnimData.RotationInterpSpeed = 120.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.OverrideTargetRotation.Clear(this);
		Boss.ResetTurretRotation(true);
		Boss.ResetTurretRotation(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TimeOfDone.IsSet())
			return;

		float Alpha = (ActiveDuration - Settings.MachineGunPreBurstDelay) / Settings.MachineGunBurstDuration;
		Alpha = Math::Saturate(Alpha);
		if(Alpha == 1.0)
		{
			TimeOfDone.Set(Time::GetGameTimeSeconds());
		}
		DistanceOffset = Math::Lerp(-Settings.MachineGunPlayerFrontDistance, Settings.MachineGunPlayerBackDistance, Alpha);
		UpdateDirectionAndDistance(DeltaTime);
		OceanWaves::RequestWaveData(RightWaveInstigator, GetShootTargetLocation(true, true));
		OceanWaves::RequestWaveData(LeftWaveInstigator, GetShootTargetLocation(false, true));

		if(ActiveDuration < Settings.MachineGunPreBurstDelay)
			return;

		UpdateTurretRotation();

		if(Time::GetGameTimeSince(TimeOfLastShot) < Settings.MachineGunBulletCooldown)
			return;

		Shoot();
	}

	void UpdateDirectionAndDistance(float DeltaTime, bool bSnapPlayerLocation = false)
	{
		FVector TargetLocation = Boss.ActorTransform.InverseTransformPosition(PreviousPlayerShotOn.ActorCenterLocation);
		if(bSnapPlayerLocation)
			InterpedPlayerRelativeLocation = TargetLocation;
		else
			InterpedPlayerRelativeLocation = Math::VInterpTo(InterpedPlayerRelativeLocation, TargetLocation, DeltaTime, Settings.MachineGunPredictedPlayerLocationInterpSpeed);

		FVector Location = Boss.ActorTransform.TransformPosition(InterpedPlayerRelativeLocation);
		Direction = (Location - Boss.ActorLocation).GetSafeNormal2D();
		TangentDirection = FVector::UpVector.CrossProduct(Direction);
		DistanceToPlayer = Location.DistXY(Boss.ActorLocation);
	}

	void Shoot()
	{
		ShootFromSocket(bShootFromRightMuzzle ? n"RightLowerTurretMuzzle" : n"LeftLowerTurretMuzzle", bShootFromRightMuzzle);
		ShootFromSocket(bShootFromRightMuzzle ? n"RightUpperTurretMuzzle" : n"LeftUpperTurretMuzzle", bShootFromRightMuzzle);

		TimeOfLastShot = Time::GetGameTimeSeconds();
		bShootFromRightMuzzle = !bShootFromRightMuzzle;
	}

	void ShootFromSocket(FName Socket, bool bRight)
	{
		FVector Origin = Boss.Mesh.GetSocketLocation(Socket);
		FVector TargetLocation = GetShootTargetLocation(bRight);
		FVector ShootDir = (TargetLocation - Origin).GetSafeNormal();

		FWingsuitShootMachineGunBulletEffectParams Params;
		Params.MuzzleLocation = Origin;
		Params.TargetLocation = TargetLocation;
		Params.Direction = ShootDir;
		Params.ComponentToAttachTo = Boss.Mesh;
		Params.SocketName = Socket;
		UWingsuitBossEffectHandler::Trigger_OnShootMachineGunBullet(Boss, Params);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseLine();
		Trace.IgnoreActor(Boss);
		FVector TraceStart = Origin;
		FVector TraceEnd = Origin + ShootDir * 15000.0;
		FHitResult Hit = Trace.QueryTraceSingle(TraceStart, TraceEnd);

#if EDITOR
		TEMPORAL_LOG(this).HitResults("Shoot Hit", Hit, FHazeTraceShape::MakeLine());
#endif
		
		if(Hit.bBlockingHit)
		{
			if(Hit.Actor.IsA(ALandscape))
			{
				Trace.IgnoreActor(Hit.Actor);
				Hit = Trace.QueryTraceSingle(TraceStart, TraceEnd);
				if(Hit.bBlockingHit && Hit.Actor.IsA(AHazePlayerCharacter))
				{
					TriggerHit(Hit.ImpactPoint, Hit.ImpactNormal, Hit);
					return;
				}

				FWaveData WaveData = OceanWaves::GetLatestWaveData(bRight ? RightWaveInstigator : LeftWaveInstigator);
				TriggerHit(WaveData.PointOnWave, WaveData.PointOnWaveNormal);
			}
			else
			{
				TriggerHit(Hit.ImpactPoint, Hit.ImpactNormal, Hit);
			}
		}
	}

	void TriggerHit(FVector Point, FVector Normal, FHitResult Hit = FHitResult())
	{
		if(Hit.bBlockingHit)
		{
			auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(Player != nullptr)
				Player.DamagePlayerHealth(0.2);
		}

		FWingsuitMachineGunBulletImpactEffectParams Params;
		Params.ImpactLocation = Point;
		Params.ImpactNormal = Normal;
		Params.bImpactOnWater = !Hit.bBlockingHit;
		UWingsuitBossEffectHandler::Trigger_OnMachineGunBulletImpact(Boss, Params);

#if EDITOR
		TEMPORAL_LOG(this).Point("Hit Location", Point, 20.f, FLinearColor::DPink);
#endif
	}

	FVector GetShootTargetLocation(bool bRight, bool bLandscapeZ = false) const
	{
		float AdditionalTangentOffset = bRight ? Settings.MachineGunTargetTurretSidewaysOffset : -Settings.MachineGunTargetTurretSidewaysOffset;
		FVector Location = Boss.ActorLocation + Direction * (DistanceToPlayer + DistanceOffset) + TangentDirection * (Math::Sin(ActiveDuration / Settings.MachineGunSidewaysSinFullCycleDuration * TWO_PI) * Settings.MachineGunMaxSidewaysSinOffset + AdditionalTangentOffset);
		if(bLandscapeZ)
			Location.Z = OceanWavePaint.TargetLandscape.ActorLocation.Z;
		else
			Location.Z = OceanWaves::GetLatestWaveData(bRight ? RightWaveInstigator : LeftWaveInstigator).PointOnWave.Z;
		return Location;
	}

	FVector GetPlayerLocation() const
	{
		FVector Location = Boss.ActorLocation + Direction * DistanceToPlayer;
		Location.Z = OceanWavePaint.TargetLandscape.ActorLocation.Z;
		return Location;
	}

	void UpdateTurretRotation()
	{
		FVector RightTargetLocation = GetShootTargetLocation(true);
		FVector LeftTargetLocation = GetShootTargetLocation(false);
		Boss.SetTurretTargetWorldLocation(RightTargetLocation, true);
		Boss.SetTurretTargetWorldLocation(LeftTargetLocation, false);
	}
}