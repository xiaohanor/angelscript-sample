class UCoastPoltroonAttackBehaviour : UBasicBehaviour
{
	UCoastPoltroonSettings Settings;
	UCoastPoltroonMuzzleComponent MuzzleComp;
	UCoastPoltroonAttackComponent AttackComp;

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
		Settings = UCoastPoltroonSettings::GetSettings(Owner);
		MuzzleComp = UCoastPoltroonMuzzleComponent::Get(Owner);
		AttackComp = UCoastPoltroonAttackComponent::Get(Owner);
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
		UCoastPoltroonEffectHandler::Trigger_OnTelegraph(Owner, FCoastPoltroonOnTelegraphEffectData(MuzzleComp));
		AnimComp.RequestFeature(CoastPoltroonFeatureTag::Attack, EBasicBehaviourPriority::Medium, this, Settings.AttackInterval);

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Settings.AttackTelegraphDuration));			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UCoastPoltroonEffectHandler::Trigger_OnTelegraphStop(Owner);
		Cooldown.Set(5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SetTargetPlayer();

		if(TargetPlayer == nullptr)
			return;

		FRotator Rotation = (TargetPlayer.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Owner.ActorUpVector).Rotation();
		RotationAcc.AccelerateTo(Rotation, Settings.AttackRotationDuration, DeltaTime);
		Owner.ActorRotation = RotationAcc.Value;

		if(ActiveDuration < Settings.AttackTelegraphDuration)
			return;

		if(ActiveDuration > Settings.AttackTelegraphDuration + Settings.AttackDuration)
			return;

		if(Time::GetGameTimeSince(IntervalTime) > Settings.AttackInterval)
		{
			NumShotsFired++;

			UCoastPoltroonEffectHandler::Trigger_OnTelegraphStop(Owner);
			UCoastPoltroonEffectHandler::Trigger_OnShoot(Owner, FCoastPoltroonOnShootEffectData(MuzzleComp));

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(MuzzleComp.WorldLocation, TargetPlayer.ActorCenterLocation);
			if(Hit.bBlockingHit)
			{
				UCoastPoltroonEffectHandler::Trigger_OnHit(Owner, FCoastPoltroonOnHitEffectData(Hit));
				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(HitPlayer != nullptr)
				{
					HitPlayer.DamagePlayerHealth(Settings.AttackPlayerDamage);
					HitPlayer.PlayCameraShake(AttackComp.PlayerImpactCameraShake, this);
					HitPlayer.PlayForceFeedback(AttackComp.PlayerImpactForceFeedback, false, false, this);
					HitPlayer.AddWidget(AttackComp.PlayerImpactWidget);
				}
			}
			
			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(MuzzleComp.WorldLocation, MuzzleComp.WorldRotation.Vector() * 120000.0, NumShotsFired, Math::CeilToInt(Settings.AttackDuration / Settings.AttackInterval)));

			IntervalTime = Time::GameTimeSeconds;
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