class USkylineGeckoHitBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	USkylineGeckoSettings Settings;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MovementComponent;
	USkylineGeckoComponent GeckoComp;
	UGravityWhippableComponent WhippableComp;

	float HitTime = -BIG_NUMBER;
	AHazePlayerCharacter Attacker;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MovementComponent = UBasicAICharacterMovementComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		WhippableComp = UGravityWhippableComponent::Get(Owner);

		auto WhipResponseComp = UGravityWhipResponseComponent::Get(Owner);
		WhipResponseComp.OnHitByWhip.AddUFunction(this, n"OnWhipHit");

		auto BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	private void OnWhipHit(UGravityWhipUserComponent UserComponent, EHazeCardinalDirection HitDirection,
	                       EAnimHitPitch HitPitch, float HitWindowExtraPushback,
	                       float HitWindowPushbackMultiplier)
	{
		if(IsActive())
			return;
		if (GeckoComp.bShielded)
			return;
		if (HealthComp.IsInvulnerable())
			return;
		
		DealDamage(Cast<AHazeActor>(UserComponent.Owner), Settings.WhipDamage);
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(IsActive())
			return;
		if (GeckoComp.bShielded)
			return;
		if (WhippableComp.bGrabbed && !Settings.bCanBeKilledWhenGrabbed)
			return;
		if (HealthComp.IsInvulnerable())
			return;

		DealDamage(Cast<AHazeActor>(CombatComp.Owner), Settings.BladeDamage);
		GeckoComp.Team.LastGeckoBladeHitTime = Time::GameTimeSeconds;			
	}

	private void DealDamage(AHazeActor Instigator, float WeaponDamage)
	{
		float Damage = WeaponDamage;
		USkylineGeckoEffectHandler::Trigger_OnTakeDamage(Owner);
		if (HealthComp.IsStunned() || GeckoComp.bOverturned)
			Damage = HealthComp.MaxHealth; // Coup de grace

		if ((Damage > HealthComp.CurrentHealth) && !Settings.bCanBeKilledByBlade)
			Damage = HealthComp.CurrentHealth * 0.9; // Never die by the blade, we only get overturned

		HealthComp.TakeDamage(Damage, EDamageType::MeleeSharp, Instigator);

		Attacker = Cast<AHazePlayerCharacter>(HealthComp.LastAttacker);
		if (Attacker != nullptr)
		{
			FVector SideDir = Attacker.ViewRotation.RightVector.GetSafeNormal2D();
			FVector ViewIntersection = Math::RayPlaneIntersection(Attacker.ViewLocation, Attacker.ViewRotation.ForwardVector, FPlane(Owner.ActorLocation, FVector::UpVector));
			if (SideDir.DotProduct(ViewIntersection - Owner.ActorLocation) > 0.0)
				SideDir *= -1.0;

			// Add some direction away from attacker
			FVector AttackLoc = Attacker.ActorLocation - Attacker.ActorForwardVector * 80.0;
			FVector AwayDir = (Owner.ActorLocation - AttackLoc).GetSafeNormal2D();
			FVector FlinchDir = SideDir * 0.3 + AwayDir * 0.7;

			float FlinchSpeed = Settings.HitReactionFlinchSpeed;
			if (MovementComponent.IsInAir())
				FlinchSpeed *= 0.75;
			if (HealthComp.IsDead())
				FlinchSpeed *= 2.0;

			MovementComponent.AddPendingImpulse(FlinchDir * FlinchSpeed);
		}

		DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor(1, 1, 1, 1));
		HitTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;		
		if(Time::GetGameTimeSince(HitTime) > 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.HitDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagGecko::TakeDamage, EBasicBehaviourPriority::Medium, this, 0.5);
		GeckoComp.bAllowBladeHits.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HitTime = 0;
		GeckoComp.bAllowBladeHits.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Attacker != nullptr)
			DestinationComp.RotateTowards(Attacker);
	}
}