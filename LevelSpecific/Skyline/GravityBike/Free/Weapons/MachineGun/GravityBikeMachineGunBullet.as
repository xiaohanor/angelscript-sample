UCLASS(Abstract)
class AGravityBikeMachineGunBullet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditDefaultsOnly)
	float Speed = 50000.0;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetLifeSpan(2.0);

		SetActorEnableCollision(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Velocity = ActorForwardVector * Speed;
		FVector DeltaMove = Velocity * DeltaSeconds;
		Move(DeltaMove);
	}

	void Move(FVector DeltaMove)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (HitResult.bBlockingHit)
			HandleImpact(HitResult);
		else
			ActorLocation += DeltaMove;
	}

	void HandleImpact(FHitResult HitResult)
	{
		if (HitResult.Actor != nullptr)
		{
			auto ResponseComp = UGravityBikeWeaponProjectileResponseComponent::Get(HitResult.Actor);
			if (ResponseComp != nullptr)
			{
				auto ImpactData = FGravityBikeWeaponImpactData(
					HitResult.Component,
					HitResult.ImpactPoint,
					HitResult.ImpactNormal,
					EGravityBikeWeaponType::MachineGun,
					Damage,
					this
				);
				
				ResponseComp.OnImpact.Broadcast(ImpactData);
			}
		}

		FGravityBikeMachineGunBulletImpactEventData ImpactData;
		ImpactData.ImpactPoint = HitResult.ImpactPoint;
		ImpactData.ImpactNormal = HitResult.ImpactNormal;
		UGravityBikeMachineGunBulletEventHandler::Trigger_OnImpact(this, ImpactData);

		BP_OnImpact(HitResult);
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnImpact(FHitResult HitResult)
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPhaseActivate(int Phase)
	{

	}
}