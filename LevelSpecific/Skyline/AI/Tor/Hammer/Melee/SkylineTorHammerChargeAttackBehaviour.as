
class USkylineTorHammerChargeAttackBehaviour : UBasicBehaviour
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

	TArray<AHazeActor> HitTargets;
	bool bTelegraphing;
	bool bAnticipating;
	bool bRecovered;
	float InterruptDamage;
	int BladeInterruptedNum;
	float Roll;

	FBasicAIAnimationActionDurations Durations;
	float TotalDuration;

	private ASkylineTorHammer Hammer;
	FHazeAcceleratedRotator AccMeshRotation;
	FHazeAcceleratedVector AccMeshLocation;
	AHazePlayerCharacter Target;
	FHazeAcceleratedFloat AccSpinSpeed;

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
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::MeleeSecond)
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
		if(HammerComp.CurrentMode != ESkylineTorHammerMode::MeleeSecond)
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
		if(TargetComp.Target.GetDistanceTo(Owner) > 500)
			return false;
		if(!CooldownComp.AttackCooldown.IsOver())
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
		TotalDuration = 0;

		Durations.Telegraph = 1;
		Durations.Anticipation = 1;
		Durations.Action = 3;
		Durations.Recovery = 2;

		HitTargets.Empty();
		PreviousBodyDamageLocation = FVector::ZeroVector;

		USkylineTorHammerEventHandler::Trigger_OnSwingAttackTelegraphStart(Owner);
		USkylineTorHammerEventHandler::Trigger_OnChargeAttackTelegraphStart(Owner);
		bTelegraphing = true;
		bAnticipating = false;
		bRecovered = false;

		AccMeshRotation.SnapTo(FRotator::ZeroRotator);
		AccMeshLocation.SnapTo(FVector::ZeroVector);

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
		AccSpinSpeed.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		InterruptDamage = 0;
		USkylineTorHammerEventHandler::Trigger_OnSwingAttackTelegraphStop(Owner);
		USkylineTorHammerEventHandler::Trigger_OnSwingAttackAnticipationStop(Owner);
		HammerComp.ResetTranslations();
		HammerComp.bBlockReturn = false;		

		if(Settings.ShieldBreakModeEnabled)
		{
			if(BladeInterruptedNum <= 0)
				TargetComp.SetTarget(Game::Zoe);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Target == nullptr)
			return;

		TotalDuration += DeltaTime;

		if(TotalDuration > Durations.GetTotal())
			Cooldown.Set(1);

		if(Durations.IsBeforeAction(TotalDuration))
			DestinationComp.RotateTowards(Target);

		if(Durations.IsInRecoveryRange(TotalDuration))
		{
			AccMeshRotation.SpringTo(FRotator::ZeroRotator, 150, 0.2, DeltaTime);
			Hammer.TranslationComp.SetRelativeRotation(AccMeshRotation.Value);
			AccMeshLocation.SpringTo(FVector::ZeroVector, 150, 0.2, DeltaTime);
			Hammer.TranslationComp.SetRelativeLocation(AccMeshLocation.Value);
			Hammer.ExtraTranslationComp.RelativeRotation = FRotator::ZeroRotator;

			if(!bRecovered)
			{
				USkylineTorHammerEventHandler::Trigger_OnChargeAttackStop(Owner);
				bRecovered = true;
			}

			return;
		}

		if(Durations.IsInTelegraphRange(TotalDuration))
		{
			AccMeshRotation.AccelerateTo(FRotator(-90, 0, 0), Durations.Telegraph, DeltaTime);
			Hammer.TranslationComp.SetRelativeRotation(AccMeshRotation.Value);
			AccMeshLocation.AccelerateTo(FVector(-150, 0, 25), Durations.Telegraph, DeltaTime);
			Hammer.TranslationComp.SetRelativeLocation(AccMeshLocation.Value);

			AccSpinSpeed.AccelerateTo(250, 1, DeltaTime);
			Hammer.ExtraTranslationComp.AddRelativeRotation(FRotator(0, AccSpinSpeed.Value, 0) * DeltaTime);

			return;
		}
		else
		{
			AccSpinSpeed.AccelerateTo(1250, 0.5, DeltaTime);
			Hammer.ExtraTranslationComp.AddRelativeRotation(FRotator(0, AccSpinSpeed.Value, 0) * DeltaTime);
		}

		if(bTelegraphing)
		{
			bTelegraphing = false; 
			USkylineTorHammerEventHandler::Trigger_OnSwingAttackTelegraphStop(Owner);
		}

		if(Durations.IsInAnticipationRange(TotalDuration))
		{
			if(!bAnticipating)
			{
				bAnticipating = true;
				USkylineTorHammerEventHandler::Trigger_OnSwingAttackAnticipationStart(Owner);
			}
			return;
		}

		if(bAnticipating)
		{
			bAnticipating = false;
			USkylineTorHammerEventHandler::Trigger_OnSwingAttackAnticipationStop(Owner);
			USkylineTorHammerEventHandler::Trigger_OnChargeAttackStart(Owner);
		}

		FVector TargetLocation = Owner.ActorLocation + Owner.ActorForwardVector * 500;
		DestinationComp.MoveTowards(TargetLocation, 2500);

		FVector MeshLocation;
		bool bStopAttack = !Pathfinding::FindNavmeshLocation(TargetLocation, 100, 500, MeshLocation);
		if(!bStopAttack)
			bStopAttack = !Pathfinding::StraightPathExists(Owner.ActorLocation, MeshLocation);
		if(bStopAttack)
		{
			USkylineTorHammerEventHandler::Trigger_OnChargeAttackWallHit(Owner);
			TotalDuration = Durations.Telegraph + Durations.Anticipation + Durations.Action;
			return;
		}

		if(PreviousBodyDamageLocation == FVector::ZeroVector)
			PreviousBodyDamageLocation = DamageCapsule.WorldLocation;
		FVector Delta = PreviousBodyDamageLocation - DamageCapsule.WorldLocation;
		if(Delta.Size() < 0.1)
			return;
		if (HammerComp.HoldHammerComp == nullptr)
			return;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseCapsuleShape(DamageCapsule);
		Trace.IgnoreActors(HitTargets);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(HammerComp.HoldHammerComp.Owner);
		FHitResultArray Hits = Trace.QueryTraceMulti(PreviousBodyDamageLocation, DamageCapsule.WorldLocation);
		PreviousBodyDamageLocation = DamageCapsule.WorldLocation;

		for(auto Hit : Hits)
		{
			if(Hit.bBlockingHit && Hit.Actor.IsA(AHazePlayerCharacter))
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(HitTargets.Contains(Player))
					continue;
				HitTargets.Add(Player);
				
				float Damage = Math::Clamp(UPlayerHealthComponent::GetOrCreate(Player).Health.CurrentHealth - 0.5, 0, 0.5);
				Player.DamagePlayerHealth(Damage, DamageEffect = HammerComp.DamageEffect, DeathEffect = HammerComp.DeathEffect);

				USkylineTorHammerEventHandler::Trigger_OnHitGeneral(Owner, FSkylineTorHammerOnHitEventData(Hit));

				FKnockdown HitReaction;
				FVector Dir = (Player.ActorLocation - Owner.ActorLocation).Rotation().RightVector + FVector::UpVector * 0.15;
				HitReaction.Move = Dir * 1000;
				HitReaction.Duration = 1;
				Player.ApplyKnockdown(HitReaction);
			}
		}
	}
}