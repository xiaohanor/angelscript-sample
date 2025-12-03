
class USkylineTorHammerSwingAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerMeleeComponent MeleeComp;
	USkylineTorDamageCapsuleComponent DamageCapsule;
	USkylineTorCooldownComponent CooldownComp;
	UGravityBladeCombatResponseComponent BladeResponse;
	USkylineTorHammerStealComponent StealComp;
	USkylineTorSettings Settings;

	FVector PreviousBodyDamageLocation;
	FVector PreviousHammerDamageLocation;
	ASkylineTorHammer Hammer;

	TArray<AHazeActor> HitTargets;
	bool bTelegraphing;
	bool bAnticipating;
	float InterruptDamage;
	AHazePlayerCharacter Target;
	int BladeInterruptedNum;
	float SpinRotation;
	float StartRecoveryTime;
	float EarlyRecoveryTime;

	FBasicAIAnimationActionDurations Durations;
	FHazeAcceleratedRotator AccMeshRotation;
	FHazeAcceleratedVector AccMeshLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Hammer = Cast<ASkylineTorHammer>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		MeleeComp = USkylineTorHammerMeleeComponent::GetOrCreate(Owner);
		DamageCapsule = USkylineTorDamageCapsuleComponent::GetOrCreate(Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		BladeResponse = UGravityBladeCombatResponseComponent::GetOrCreate(Owner);

		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::Melee)
		{
			BladeInterruptedNum = 0;
			return;
		}

		if(IsActive())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if(!Settings.ShieldBreakModeEnabled)
		{
			if(Player == nullptr || Player == Game::Mio)
				TargetComp.SetTarget(Game::Zoe);
		}
		else
		{
			if(Player == nullptr)
			{
				TargetComp.SetTarget(Game::Zoe);
			}
			else
			{
				if(Player.IsPlayerDead() && !Player.OtherPlayer.IsPlayerDead())
					TargetComp.SetTarget(Player.OtherPlayer);
				if(BladeInterruptedNum <= 0)
				{
					if(Player == Game::Mio && !Game::Zoe.IsPlayerDead())
						TargetComp.SetTarget(Game::Zoe);
				}
			}
		}
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::Melee)
			return;
		if(!Settings.ShieldBreakModeEnabled)
			return;

		if(TargetComp.Target != CombatComp.Owner)
		{
			BladeInterruptedNum = 1;	
			TargetComp.SetTarget(Game::Mio);
			Cooldown.Set(0.1);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!TargetComp.HasValidTarget())
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
		if(EarlyRecoveryTime > SMALL_NUMBER && Time::GetGameTimeSince(EarlyRecoveryTime) > Durations.Recovery)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Durations.Telegraph = 1;
		Durations.Anticipation = 1;
		Durations.Action = 0.4;
		Durations.Recovery = 0.5;
		StartRecoveryTime = 0;
		EarlyRecoveryTime = 0;

		HitTargets.Empty();
		PreviousBodyDamageLocation = FVector::ZeroVector;

		USkylineTorHammerEventHandler::Trigger_OnSwingAttackTelegraphStart(Owner);
		bTelegraphing = true;

		AccMeshRotation.SnapTo(FRotator::ZeroRotator);
		AccMeshLocation.SnapTo(FVector::ZeroVector);
		SpinRotation = 0;

		PreviousBodyDamageLocation = FVector::ZeroVector;
		PreviousHammerDamageLocation = FVector::ZeroVector;

		HammerComp.bBlockReturn = true;

		if(!Settings.ShieldBreakModeEnabled)
		{
			if(TargetComp.Target == Game::Mio && TargetComp.IsValidTarget(Game::Zoe))
			{
				TargetComp.SetTarget(Game::Zoe);
				DeactivateBehaviour();
				return;
			}
		}
		else
		{
			if(BladeInterruptedNum > 0)
				BladeInterruptedNum--;
		}

		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);

		HammerComp.bGroundOffset.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		InterruptDamage = 0;
		USkylineTorHammerEventHandler::Trigger_OnSwingAttackAnticipationStop(Owner);
		USkylineTorHammerEventHandler::Trigger_OnSwingAttackTelegraphStop(Owner);
		Hammer.TranslationComp.RelativeLocation = FVector::ZeroVector;
		Hammer.TranslationComp.RelativeRotation = FRotator::ZeroRotator;
		Hammer.ExtraTranslationComp.RelativeRotation = FRotator::ZeroRotator;
		HammerComp.bBlockReturn = false;

		if(Settings.ShieldBreakModeEnabled)
		{
			if(BladeInterruptedNum <= 0)
				TargetComp.SetTarget(Game::Zoe);
		}

		Cooldown.Set(0.1);
		HammerComp.bGroundOffset.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Target == nullptr)
			return;

		if(Durations.IsInRecoveryRange(ActiveDuration) || EarlyRecoveryTime > SMALL_NUMBER)
		{
			float HalfRecoveryTime = Durations.Recovery / 2;
			if(StartRecoveryTime < SMALL_NUMBER)
				StartRecoveryTime = Time::GameTimeSeconds;

			if(Time::GetGameTimeSince(StartRecoveryTime) < HalfRecoveryTime)
				return;
			
			AccMeshRotation.AccelerateTo(FRotator::ZeroRotator, HalfRecoveryTime, DeltaTime);
			Hammer.TranslationComp.SetRelativeRotation(AccMeshRotation.Value);
			AccMeshLocation.AccelerateTo(FVector::ZeroVector, HalfRecoveryTime, DeltaTime);
			Hammer.TranslationComp.SetRelativeLocation(AccMeshLocation.Value);
			return;
		}

		if(Durations.IsBeforeAction(ActiveDuration) && Owner.ActorLocation.Distance(Target.ActorLocation) > 150)
		{
			DestinationComp.MoveTowards(Target.ActorLocation, 500);
		}

		if(Durations.IsInTelegraphRange(ActiveDuration))
		{
			DestinationComp.RotateTowards(Target);
			
			AccMeshRotation.AccelerateTo(FRotator(25, 0, 0), Durations.Telegraph, DeltaTime);
			Hammer.TranslationComp.SetRelativeRotation(AccMeshRotation.Value);
			AccMeshLocation.AccelerateTo(FVector(0, 0, 35), Durations.Telegraph, DeltaTime);
			Hammer.TranslationComp.SetRelativeLocation(AccMeshLocation.Value);

			SpinRotation = Math::Sin(ActiveDuration * 10) * 25;
			Hammer.ExtraTranslationComp.SetRelativeRotation(FRotator(0, SpinRotation, 0));

			return;
		}

		if(bTelegraphing)
		{
			bTelegraphing = false; 
			USkylineTorHammerEventHandler::Trigger_OnSwingAttackTelegraphStop(Owner);
			HammerComp.bGroundOffset.Clear(this);
		}

		if(Durations.IsInAnticipationRange(ActiveDuration))
		{
			if(!bAnticipating)
			{
				bAnticipating = true;
				USkylineTorHammerEventHandler::Trigger_OnSwingAttackAnticipationStart(Owner);
			}

			SpinRotation = Math::Sin(ActiveDuration * 25) * 25;
			Hammer.ExtraTranslationComp.SetRelativeRotation(FRotator(0, SpinRotation, 0));

			AccMeshRotation.AccelerateTo(FRotator(65, 0, 0), Durations.Telegraph, DeltaTime);
			Hammer.TranslationComp.SetRelativeRotation(AccMeshRotation.Value);

			AccMeshLocation.AccelerateTo(FVector(0, 0, 75), Durations.Telegraph, DeltaTime);
			Hammer.TranslationComp.SetRelativeLocation(AccMeshLocation.Value);

			return;
		}

		if(bAnticipating)
		{
			bAnticipating = false;
			USkylineTorHammerEventHandler::Trigger_OnSwingAttackAnticipationStop(Owner);
			USkylineTorHammerEventHandler::Trigger_OnSwingAttack(Owner);
			Hammer.ExtraTranslationComp.SetRelativeRotation(FRotator(0, 0, 0));
		}

		FRotator TelegraphRotator = FRotator(45, 0, 0);
		FRotator Rotator = FRotator(-180, 0, 0);
		float Alpha = Math::Clamp((ActiveDuration - Durations.Anticipation - Durations.Telegraph) / Durations.Action, 0, 1);
		FRotator MeshRotation = FRotator(Math::Lerp(TelegraphRotator.Pitch, Rotator.Pitch, Alpha), Math::Lerp(TelegraphRotator.Yaw, Rotator.Yaw, Alpha), Math::Lerp(TelegraphRotator.Roll, Rotator.Roll, Alpha));

		AccMeshRotation.SnapTo(MeshRotation);
		Hammer.TranslationComp.SetRelativeRotation(AccMeshRotation.Value);		
		AccMeshLocation.AccelerateTo(FVector(0, 0, 10), Durations.Action, DeltaTime);
		Hammer.TranslationComp.SetRelativeLocation(AccMeshLocation.Value);

		if(PreviousBodyDamageLocation == FVector::ZeroVector)
			PreviousBodyDamageLocation = DamageCapsule.WorldLocation;
		
		if(PreviousHammerDamageLocation == FVector::ZeroVector)
			PreviousHammerDamageLocation = Hammer.HeadLocation.WorldLocation;

		FVector Delta = PreviousBodyDamageLocation - DamageCapsule.WorldLocation;
		if(Delta.Size() < 0.1)
			return;
		if (HammerComp.HoldHammerComp == nullptr)
			return;

		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(HitTargets.Contains(Player))
				continue;

			FHazeTraceSettings Trace = Trace::InitAgainstComponent(Player.CapsuleComponent);
			Trace.UseCapsuleShape(DamageCapsule.CapsuleRadius, DamageCapsule.CapsuleHalfHeight, DamageCapsule.WorldRotation.Quaternion());
			FHitResult PlayerHit = Trace.QueryTraceComponent(PreviousBodyDamageLocation, DamageCapsule.WorldLocation);

			if(!PlayerHit.bBlockingHit)
				continue;
			if(Owner.ActorForwardVector.DotProduct(Player.ActorLocation - Owner.ActorLocation) < 0)
				continue;

			float Damage = Math::Clamp(UPlayerHealthComponent::GetOrCreate(Player).Health.CurrentHealth - 0.5, 0, 0.5);
			Player.DamagePlayerHealth(Damage, DamageEffect = HammerComp.DamageEffect, DeathEffect = HammerComp.DeathEffect);

			USkylineTorHammerEventHandler::Trigger_OnHitGeneral(Owner, FSkylineTorHammerOnHitEventData(PlayerHit));

			FKnockdown HitReaction;
			FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) + FVector::UpVector * 0.4;
			HitReaction.Move = Dir * 1500;
			HitReaction.Duration = 1;
			Player.ApplyKnockdown(HitReaction);

			BladeInterruptedNum = 0;
			HitTargets.Add(Player);
		}
		PreviousBodyDamageLocation = DamageCapsule.WorldLocation;

		FHazeTraceSettings HammerTrace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		HammerTrace.IgnoreActors(Game::Players);
		HammerTrace.IgnoreActor(Owner);
		HammerTrace.IgnoreActor(HammerComp.HoldHammerComp.Owner);
		HammerTrace.UseSphereShape(80);
		FHitResult HammerHit = HammerTrace.QueryTraceSingle(PreviousHammerDamageLocation, Hammer.HeadLocation.WorldLocation);
		PreviousHammerDamageLocation = Hammer.HeadLocation.WorldLocation;

		if(HammerHit.bBlockingHit)
		{
			EarlyRecoveryTime = Time::GameTimeSeconds;
			FRotator Rotation = HammerHit.ImpactNormal.Rotation().UpVector.Rotation();
			USkylineTorHammerEventHandler::Trigger_OnSwingAttackImpact(Owner, FOnSwingAttackData(HammerHit.ImpactPoint, Rotation));
		}
	}
}