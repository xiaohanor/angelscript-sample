enum ESkylineTorDealDamageDirection
{
	Away,
	Side
}

class USkylineTorDealDamageComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UDamageEffect> BodyDamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> BodyDeathEffect;

	UPROPERTY()
	TSubclassOf<UDamageEffect> HammerDamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> HammerDeathEffect;

	private AHazeCharacter Character;
	private FVector PreviousBodyDamageLocation;
	private FVector PreviousHammerDamageLocation;
	TArray<AHazeActor> HitTargets;
	private USkylineTorHoldHammerComponent HoldHammerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Character = Cast<AHazeCharacter>(Owner);
		HoldHammerComp = USkylineTorHoldHammerComponent::Get(Owner);
	}
	
	void ResetDamage()
	{
		PreviousBodyDamageLocation = FVector::ZeroVector;
		PreviousHammerDamageLocation = FVector::ZeroVector;
		HitTargets.Empty();
	}

	void ResetHits()
	{
		HitTargets.Empty();
	}

	TArray<FHitResult> DealHammerDamage(float Damage, ESkylineTorDealDamageDirection Direction)
	{
		USkylineTorDamageCapsuleComponent DamageCapsule = HoldHammerComp.Hammer.DamageCapsule;

		if(PreviousHammerDamageLocation == FVector::ZeroVector)
			PreviousHammerDamageLocation = DamageCapsule.WorldLocation;
		FVector Delta = PreviousHammerDamageLocation - DamageCapsule.WorldLocation;
		if(Delta.Size() < 0.1)
			return TArray<FHitResult>();

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseCapsuleShape(DamageCapsule);
		Trace.IgnoreActors(HitTargets);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(HoldHammerComp.Hammer);
		FHitResultArray Hits = Trace.QueryTraceMulti(PreviousHammerDamageLocation, DamageCapsule.WorldLocation);
		PreviousHammerDamageLocation = DamageCapsule.WorldLocation;

		TArray<FHitResult> SuccessfulHits;
		for(auto Hit : Hits)
		{
			if(Hit.bBlockingHit && Hit.Actor.IsA(AHazePlayerCharacter))
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(HitTargets.Contains(Player))
					continue;
				HitTargets.Add(Player);
				Player.DamagePlayerHealth(Damage, DamageEffect = HammerDamageEffect, DeathEffect = HammerDeathEffect);
				SuccessfulHits.Add(Hit);

				USkylineTorHammerEventHandler::Trigger_OnHitGeneral(HoldHammerComp.Hammer, FSkylineTorHammerOnHitEventData(Hit));
				USkylineTorEventHandler::Trigger_OnHammerHitGeneral(Character, FSkylineTorEventHandlerHitData(HoldHammerComp.Hammer, Hit));

				FKnockdown Kb;

				FVector Dir;
				if(Direction == ESkylineTorDealDamageDirection::Away)
					Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
				if(Direction == ESkylineTorDealDamageDirection::Side)
				{
					if(Owner.ActorRightVector.DotProduct(Player.ActorLocation - Owner.ActorLocation) > 0)
						Dir = Owner.ActorRightVector;
					else
						Dir = -Owner.ActorRightVector;
				}

				Kb.Move = Dir * 650;
				Kb.Duration = 0.8;
				Player.ApplyKnockdown(Kb);
			}
		}
		return SuccessfulHits;
	}
	
	TArray<FHitResult> DealBodyDamage(float Damage, ESkylineTorDealDamageDirection Direction)
	{
		FVector DamageLocation = Character.Mesh.GetSocketLocation(n"Hips");
		FRotator BodyDirection = (Character.Mesh.GetSocketLocation(n"Head") - DamageLocation).Rotation();

		if(PreviousBodyDamageLocation == FVector::ZeroVector)
			PreviousBodyDamageLocation = DamageLocation;
		FVector Delta = PreviousBodyDamageLocation - DamageLocation;
		if(Delta.Size() < 0.1)
			return TArray<FHitResult>();

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseCapsuleShape(Character.CapsuleComponent.CapsuleRadius, Character.CapsuleComponent.CapsuleHalfHeight, BodyDirection.UpVector.ToOrientationQuat());
		Trace.IgnoreActors(HitTargets);
		Trace.IgnoreActor(Owner);
		Trace.IgnoreActor(HoldHammerComp.Hammer);
		FHitResultArray Hits = Trace.QueryTraceMulti(PreviousBodyDamageLocation, DamageLocation);
		PreviousBodyDamageLocation = DamageLocation;

		TArray<FHitResult> SuccessfulHits;
		for(auto Hit : Hits)
		{
			if(Hit.bBlockingHit && Hit.Actor.IsA(AHazePlayerCharacter))
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if(HitTargets.Contains(Player))
					continue;
				HitTargets.Add(Player);
				Player.DamagePlayerHealth(Damage, DamageEffect = BodyDamageEffect, DeathEffect = BodyDeathEffect);

				FKnockdown Kb;

				FVector Dir;
				if(Direction == ESkylineTorDealDamageDirection::Away)
					Dir = (Player.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
				if(Direction == ESkylineTorDealDamageDirection::Side)
				{
					if(Owner.ActorRightVector.DotProduct(Player.ActorLocation - Owner.ActorLocation) > 0)
						Dir = Owner.ActorRightVector;
					else
						Dir = -Owner.ActorRightVector;
				}
				
				Kb.Move = Dir * 650;
				Kb.Duration = 0.8;
				Player.ApplyKnockdown(Kb);
			}
		}
		return SuccessfulHits;
	}
}