class USerpentHomingMissileCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASerpentHomingMissile Missile;
	float Damage = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Missile = Cast<ASerpentHomingMissile>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FSerpentHomingMissileStartParams Params;
		Params.Location = Missile.ActorLocation;
		USerpentHomingMissileEventHandler::Trigger_OnStart(Missile, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetDirection = (Missile.TargetPlayer.ActorLocation - Missile.ActorLocation).GetSafeNormal();
		Missile.Direction = Math::VInterpConstantTo(Missile.Direction, TargetDirection, DeltaTime, 0.45);
		Missile.Direction.Normalize();

		Missile.Speed = Math::FInterpConstantTo(Missile.Speed, Missile.TargetSpeed, DeltaTime, Missile.Acceleration);

		Missile.ActorLocation += Missile.Direction * Missile.Speed * DeltaTime;

		if ((Missile.ActorLocation - Missile.TargetPlayer.ActorLocation).Size() < 2000.0)
		{
			//If VFX need, run trace instead and read from collision
			//USE USerpentHomingMissileEventHandler::Trigger_OnImpact(Missile, Params);

			Missile.TargetPlayer.DamagePlayerHealth(Damage);
			FSerpentHomingMissileEndParams Params;
			Params.Location = Missile.ActorLocation;
			USerpentHomingMissileEventHandler::Trigger_OnEnd(Missile, Params);
			Missile.DestroyActor();
		}

		// Debug::DrawDebugSphere(ActorLocation, 100.0, 20.0, FLinearColor::Red, 50.0);

		if (Time::GameTimeSeconds > Missile.LifeTime)
		{
			FSerpentHomingMissileEndParams Params;
			Params.Location = Missile.ActorLocation;
			USerpentHomingMissileEventHandler::Trigger_OnEnd(Missile, Params);
			Missile.DestroyActor();		
		}
	}
};