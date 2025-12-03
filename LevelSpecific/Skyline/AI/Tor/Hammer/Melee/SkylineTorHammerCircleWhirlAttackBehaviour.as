
class USkylineTorHammerCircleWhirlAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorHammerMeleeComponent MeleeComp;
	USkylineTorDamageCapsuleComponent DamageCapsule;
	USkylineTorSettings Settings;
	USkylineTorCooldownComponent CooldownComp;

	ASplineActor SplineActor;
	FVector PreviousDamageLocation;
	float PreviousDamageTime;
	TArray<AHazeActor> HitTargets;
	float ClearTargetsTime;
	FHazeAcceleratedFloat AccPlayRate;
	bool bTelegraphing;
	AHazeActor Target;
	float TelegraphDuration = 0.4;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		MeleeComp = USkylineTorHammerMeleeComponent::GetOrCreate(Owner);
		DamageCapsule = USkylineTorDamageCapsuleComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		CooldownComp = USkylineTorCooldownComponent::GetOrCreate(Owner);	
		SplineActor = TListedActors<ASkylineTorReferenceManager>().Single.CircleMovementSplineActor;
		MeleeComp.OnDealDamage.AddUFunction(this, n"DealDamage");
	}

	UFUNCTION()
	private void DealDamage()
	{
		if(!IsActive())
			return;

		if(ActiveDuration < TelegraphDuration)
			return;

		if (HammerComp.HoldHammerComp == nullptr)
			return;		

		if(PreviousDamageLocation == FVector::ZeroVector)
			PreviousDamageLocation = DamageCapsule.WorldLocation;
		FVector Delta = PreviousDamageLocation - DamageCapsule.WorldLocation;
		if(Delta.Size() < 0.1)
			return;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseCapsuleShape(DamageCapsule);
		Trace.IgnoreActors(HitTargets);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(HammerComp.HoldHammerComp.Owner);
		FHitResultArray Hits = Trace.QueryTraceMulti(PreviousDamageLocation, DamageCapsule.WorldLocation);
		PreviousDamageLocation = DamageCapsule.WorldLocation;

		for(auto Hit : Hits)
		{
			if(Hit.bBlockingHit && Hit.Actor.IsA(AHazePlayerCharacter))
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(HitTargets.Contains(Player))
					continue;
				HitTargets.Add(Player);
				Player.DamagePlayerHealth(0.25, DamageEffect = HammerComp.DamageEffect, DeathEffect = HammerComp.DeathEffect);

				USkylineTorHammerEventHandler::Trigger_OnHitGeneral(Owner, FSkylineTorHammerOnHitEventData(Hit));

				FStumble Stumble;
				FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				Stumble.Move = Dir * 250;
				Stumble.Duration = 0.25;
				Player.ApplyStumble(Stumble);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		// if(MeleeComp.Mode != ESkylineTorHammerMeleeMode::Whirl)
		// 	return false;
		if(!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 6)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		HitTargets.Empty();
		PreviousDamageLocation = FVector::ZeroVector;

		USkylineTorHammerEventHandler::Trigger_OnWhirlAttackTelegraphStart(Owner);
		bTelegraphing = true;

		Target = TargetComp.Target;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USkylineTorHammerEventHandler::Trigger_OnWhirlAttackTelegraphStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Distance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
		float TargetDistance = SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(TargetComp.Target.ActorLocation);

		bool bForward = TargetDistance > Distance;
		if(Math::Abs(Distance - TargetDistance) > SplineActor.Spline.SplineLength * 0.5)
			bForward = !bForward;

		if(bTelegraphing && ActiveDuration > TelegraphDuration)
		{
			bTelegraphing = false; 
			USkylineTorHammerEventHandler::Trigger_OnWhirlAttackTelegraphStop(Owner);
		}

		if(bTelegraphing)
		{
			if(Owner.ActorLocation.Dist2D(Target.ActorLocation) < 1000)
			{
				// FVector Dir = (Owner.ActorLocation - Target.ActorLocation).GetSafeNormal2D();
				// FVector TargetLocation = Owner.ActorLocation + Dir * 100;
				// DestinationComp.MoveTowards(TargetLocation, 1500);

				DestinationComp.MoveAlongSpline(SplineActor.Spline, 1500, !bForward);
			}
			return;
		}

		AccPlayRate.AccelerateTo(5, 0.5, DeltaTime);

		if (!Owner.ActorLocation.IsWithinDist(Target.ActorLocation, 50))
			DestinationComp.MoveAlongSpline(SplineActor.Spline, 500, bForward);
			// DestinationComp.MoveTowards(Target.ActorLocation, 500);

		if(Time::GetGameTimeSince(ClearTargetsTime) < 0.5)
			return;
		ClearTargetsTime = Time::GameTimeSeconds;
		HitTargets.Empty();
	}
}