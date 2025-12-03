class UCoastContainerTurretWeaponAttackCapability : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UCoastContainerTurretSettings Settings;
	UCoastContainerTurretWeaponMuzzleComponent MuzzleComp;
	UCoastContainerTurretWeaponAttackComponent AttackComp;

	AHazeActor TargetPlayer;
	float IntervalTime;
	FHazeAcceleratedRotator RotationAcc;
	float RetargetInterval = 0.25;
	float RetargetTime;
	int NumShotsFired = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastContainerTurretSettings::GetSettings(Owner);
		MuzzleComp = UCoastContainerTurretWeaponMuzzleComponent::Get(Owner);
		AttackComp = UCoastContainerTurretWeaponAttackComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(TargetComp.Target == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.AttackTelegraphDuration + Settings.AttackDuration + Settings.AttackRecoverDuration)
			return true;
		if(TargetComp.Target == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if(TargetComp.Target == nullptr)
			return;

		NumShotsFired = 0;	
		IntervalTime = Time::GameTimeSeconds;
		RotationAcc.Value = Owner.ActorRotation;
		UCoastContainerTurretEffectHandler::Trigger_OnTelegraph(MuzzleComp.Weapon.Turret, FCoastContainerTurretOnTelegraphEffectData(MuzzleComp));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Settings.AttackTelegraphDuration));	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UCoastContainerTurretEffectHandler::Trigger_OnTelegraphStop(MuzzleComp.Weapon.Turret);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SetTargetPlayer();

		if(TargetPlayer == nullptr)
			return;

		FRotator Rotation = (TargetPlayer.ActorLocation - Owner.ActorLocation).ConstrainToPlane(MuzzleComp.Weapon.Turret.ActorUpVector).Rotation();
		RotationAcc.AccelerateTo(Rotation, Settings.AttackRotationDuration, DeltaTime);
		Owner.ActorRotation = RotationAcc.Value;

		if(ActiveDuration < Settings.AttackTelegraphDuration)
			return;

		if(ActiveDuration > Settings.AttackTelegraphDuration + Settings.AttackDuration)
			return;

		if(Time::GetGameTimeSince(IntervalTime) > Settings.AttackInterval)
		{
			NumShotsFired++;			
			UCoastContainerTurretEffectHandler::Trigger_OnTelegraphStop(MuzzleComp.Weapon.Turret);
			UCoastContainerTurretEffectHandler::Trigger_OnShoot(MuzzleComp.Weapon.Turret, FCoastContainerTurretOnShootEffectData(MuzzleComp));

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(MuzzleComp.WorldLocation, TargetPlayer.ActorCenterLocation);
			if(Hit.bBlockingHit)
			{
				UCoastContainerTurretEffectHandler::Trigger_OnHit(MuzzleComp.Weapon.Turret, FCoastContainerTurretOnHitEffectData(Hit));
				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(HitPlayer != nullptr)
				{
					HitPlayer.DamagePlayerHealth(Settings.AttackPlayerDamage);
					HitPlayer.PlayCameraShake(AttackComp.PlayerImpactCameraShake, this);
					HitPlayer.PlayForceFeedback(AttackComp.PlayerImpactForceFeedback, false, false, this);
					HitPlayer.AddWidget(AttackComp.PlayerImpactWidget);
				}
				else
				{
					for(AHazePlayerCharacter NearbyPlayer: Game::Players)
					{
						if(NearbyPlayer.ActorLocation.IsWithinDist(Hit.Location, Settings.AttackWallImpactCameraShakeDistance))
						{
							NearbyPlayer.PlayCameraShake(AttackComp.WallImpactCameraShake, this);
							NearbyPlayer.PlayForceFeedback(AttackComp.WallImpactForceFeedback, false, false, this);
						}
					}
				}
			}

			IntervalTime = Time::GameTimeSeconds;

			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(MuzzleComp.WorldLocation, MuzzleComp.WorldRotation.Vector() * 120000.0, NumShotsFired, Math::CeilToInt(Settings.AttackDuration / Settings.AttackInterval)));
		}
	}

	void SetTargetPlayer()
	{
		if(ActiveDuration > Settings.AttackTelegraphDuration * 0.75)
			return;

		if(RetargetTime > 0 && Time::GetGameTimeSince(RetargetTime) < RetargetInterval)
			return;

		RetargetTime = Time::GameTimeSeconds;
		TargetPlayer = TargetComp.Target;
	}
}