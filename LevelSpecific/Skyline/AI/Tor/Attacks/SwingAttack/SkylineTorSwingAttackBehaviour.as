
class USkylineTorSwingAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorCooldownComponent CooldownComp;
	USkylineTorDamageComponent DamageComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazeActor Target;
	private AHazeCharacter Character;

	FBasicAIAnimationActionDurations Durations;

	bool bTelegraping;
	bool bAction;

	FVector PreviousHammerDamageLocation;
	TArray<AHazeActor> HitTargets;

	float InterruptDamage;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);
		DamageComp = USkylineTorDamageComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
		HealthComp.OnTakeDamage.AddUFunction(this, n"TakeDamage");
	}

	UFUNCTION()
	private void TakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                        EDamageType DamageType)
	{
		if(!IsActive())
			return;

		InterruptDamage += Damage;

		if(InterruptDamage < 0.05)
			return;

		InterruptDamage = 0;
		DeactivateBehaviour();
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, 500))
			return false;
		if(HoldHammerComp.bDetached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
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

		AnimInstance.FinalizeDurations(FeatureTagSkylineTor::SwingAttack, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagSkylineTor::SwingAttack, EBasicBehaviourPriority::Medium, this, Durations);
		Target = TargetComp.Target;
		HitTargets.Empty();

		USkylineTorEventHandler::Trigger_OnSwingAttackTelegraphStart(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		bTelegraping = true;
		bAction = false;
		PreviousHammerDamageLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorEventHandler::Trigger_OnSwingAttackTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		InterruptDamage = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > Durations.GetTotal())
		{
			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
			if(PlayerTarget != nullptr)
				TargetComp.SetTarget(PlayerTarget.OtherPlayer);
			DeactivateBehaviour();
			return;
		}

		if(Durations.IsInTelegraphRange(ActiveDuration))
		{
			DestinationComp.RotateTowards(Target);
			return;
		}

		if(bTelegraping)
		{
			bTelegraping = false;
			USkylineTorEventHandler::Trigger_OnSwingAttackTelegraphStop(Owner, FSkylineTorEventHandlerGeneralData(HoldHammerComp.Hammer));
		}

		if(Durations.IsInAnticipationRange(ActiveDuration))
		{
			USkylineTorDamageCapsuleComponent DamageCapsule = HoldHammerComp.Hammer.DamageCapsule;

			if(PreviousHammerDamageLocation == FVector::ZeroVector)
				PreviousHammerDamageLocation = DamageCapsule.WorldLocation;
			FVector Delta = PreviousHammerDamageLocation - DamageCapsule.WorldLocation;
			if(Delta.Size() < 0.1)
				return;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseCapsuleShape(DamageCapsule);
			Trace.IgnoreActors(HitTargets);
			Trace.IgnoreActor(Owner);
			Trace.IgnoreActor(HoldHammerComp.Hammer);
			FHitResultArray Hits = Trace.QueryTraceMulti(PreviousHammerDamageLocation, DamageCapsule.WorldLocation);
			PreviousHammerDamageLocation = DamageCapsule.WorldLocation;

			for(auto Hit : Hits)
			{
				if(Hit.bBlockingHit && Hit.Actor.IsA(AHazePlayerCharacter))
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
					// Do not hit behind
					if(Owner.ActorForwardVector.DotProduct(Player.ActorLocation - Owner.ActorLocation) < 0)
						HitTargets.Add(Player);
					if(HitTargets.Contains(Player))
						continue;
					HitTargets.Add(Player);
					Player.DamagePlayerHealth(0.5);

					USkylineTorHammerEventHandler::Trigger_OnHitGeneral(HoldHammerComp.Hammer, FSkylineTorHammerOnHitEventData(Hit));
					USkylineTorEventHandler::Trigger_OnHammerHitGeneral(Owner, FSkylineTorEventHandlerHitData(HoldHammerComp.Hammer, Hit));

					FStumble Stumble;
					FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
					Stumble.Move = Dir * 500;
					Stumble.Duration = 0.5;
					Player.ApplyStumble(Stumble);
				}
			}
		}

		if(Durations.IsInActionRange(ActiveDuration))
		{
			if(!bAction)
			{
				bAction = true;
				FVector ImpactLocation = HoldHammerComp.Hammer.ImpactLocation.WorldLocation;
				FVector FootLocation = Character.Mesh.GetSocketLocation(n"LeftFoot");
				USkylineTorEventHandler::Trigger_OnSwingAttackImpact(Owner, FSkylineTorEventHandlerOnSwingAttackImpactData(HoldHammerComp.Hammer, ImpactLocation));

				for(AHazePlayerCharacter Player : Game::Players)
				{
					if(HitTargets.Contains(Player))
						continue;

					float FootRadius = 150;
					float Radius = 300;
					if(Player.ActorLocation.Distance(ImpactLocation) < Radius || Player.ActorLocation.Distance(FootLocation) < FootRadius)
					{
						HitTargets.Add(Player);
						Player.DamagePlayerHealth(0.5);

						FStumble Stumble;
						FVector Dir = (Player.ActorLocation - ImpactLocation).GetSafeNormal2D() + FVector::UpVector * 0.25;
						Stumble.Move = Dir * 1000;
						Stumble.Duration = 0.5;
						Player.ApplyStumble(Stumble);
					}
				}
			}
		}
	}
}