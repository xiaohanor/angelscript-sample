class UCoastWaterJetAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UCoastWaterJetSettings Settings;
	UCoastWaterJetWeaponMuzzleComponent Muzzle;
	
	float AttackTime;
	bool bWasTelegraphing;
	int NumShotsFired = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastWaterJetSettings::GetSettings(Owner);
		Muzzle = UCoastWaterJetWeaponMuzzleComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.Target.ActorForwardVector.DotProduct((Owner.ActorLocation - TargetComp.Target.ActorLocation).GetSafeNormal2D()) < 0.7)
			return false; // Need to be ahead of target
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if ((PlayerTarget != nullptr) && !SceneView::IsInView(PlayerTarget, Owner.ActorLocation))
			return false; // Only start attack when on screen
		if (!Owner.ActorLocation.IsWithinDist(PlayerTarget.ActorLocation, Settings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.AttackTelegraphDuration + Settings.AttackDuration + Settings.AttackRecoverDuration)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AttackTime = Time::GameTimeSeconds + Settings.AttackTelegraphDuration;
		UCoastWaterJetEffectHandler::Trigger_OnTelegraph(Owner, FCoastWaterJetOnTelegraphEffectData(Muzzle));
		bWasTelegraphing = true;
		NumShotsFired = 0;

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Settings.AttackTelegraphDuration));			
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (bWasTelegraphing)
			UCoastWaterJetEffectHandler::Trigger_OnTelegraphStop(Owner);
		Cooldown.Set(5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Settings.AttackTelegraphDuration)
			return;

		if(ActiveDuration > Settings.AttackTelegraphDuration + Settings.AttackDuration)
			return;

		if(Time::GameTimeSeconds > AttackTime)
		{
			if (bWasTelegraphing)
				UCoastWaterJetEffectHandler::Trigger_OnTelegraphStop(Owner);
			bWasTelegraphing = false;
			NumShotsFired++;

			UCoastWaterJetEffectHandler::Trigger_OnAttack(Owner, FCoastWaterJetOnAttackEffectData(Muzzle));

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(Muzzle.WorldLocation, TargetComp.Target.ActorCenterLocation);
			if(Hit.bBlockingHit)
			{
				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				UCoastWaterJetEffectHandler::Trigger_OnAttackImpact(Owner, FCoastWaterJetOnAttackImpactEffectData(Hit));
				if(HitPlayer != nullptr)
					HitPlayer.DamagePlayerHealth(Settings.AttackPlayerDamage);
			}

			AttackTime += Settings.AttackInterval;

			UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Muzzle.WorldLocation, Muzzle.WorldRotation.Vector() * 120000.0, NumShotsFired, Math::CeilToInt(Settings.AttackDuration / Settings.AttackInterval)));
		}
	}
}
