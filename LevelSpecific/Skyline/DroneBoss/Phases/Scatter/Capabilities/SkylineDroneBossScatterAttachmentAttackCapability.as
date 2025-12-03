class USkylineDroneBossScatterAttachmentAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossAttack);
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossScatter);

	ASkylineDroneBossScatterAttachment Attachment;
	TArray<ASkylineDroneBossScatterProjectile> Projectiles;
	
	float LastAttackTimestamp;
	float LastFireTimestamp;
	FHazeAcceleratedVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Attachment = Cast<ASkylineDroneBossScatterAttachment>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Attachment.IsActivated())
			return false;

		if (Attachment.State == ESkylineDroneBossScatterAttachmentState::Loose)
			return false;

		float TimeSinceActivation = Time::GetGameTimeSince(Attachment.ActivationTimestamp);
		if (TimeSinceActivation < Attachment.AttackDelay)
			return false;
		
		float TimeSinceAttack = Time::GetGameTimeSince(LastAttackTimestamp);
		if (TimeSinceAttack < Attachment.AttackInterval)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Projectiles.Num() <= 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto ProjectilePivot = Attachment.ProjectilePivot;

		for (int i = 0; i < Attachment.NumProjectiles; ++i)
		{
			float OffsetAngle = Math::RadiansToDegrees(PI / (Attachment.NumProjectiles - 1)) * i;
			FVector OffsetDirection = ProjectilePivot.UpVector.RotateAngleAxis(OffsetAngle - 90, ProjectilePivot.ForwardVector);
			float OffsetDistance = Attachment.ProjectileOffsetDistance;
			FVector OffsetLocation = ProjectilePivot.WorldLocation + (OffsetDirection * OffsetDistance);

			auto Projectile = Cast<ASkylineDroneBossScatterProjectile>(
				SpawnActor(Attachment.ProjectileClass, OffsetLocation)
			);
			Projectile.AttachToComponent(ProjectilePivot, NAME_None, EAttachmentRule::KeepWorld);

			FSkylineDroneBossScatterProjectileSpawnedData SpawnedData;
			SpawnedData.Projectile = Projectile;
			USkylineDroneBossScatterEventHandler::Trigger_ProjectileSpawned(Attachment, SpawnedData);

			Projectiles.Add(Projectile);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (int i = 0; i < Projectiles.Num(); ++i)
			Projectiles[i].DestroyActor();

		Projectiles.Empty();

		LastAttackTimestamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Boss = Attachment.Boss;
		auto TargetPlayer = Boss.TargetPlayer.Get();

		// Temporary simple dodgable targeting
		TargetLocation.AccelerateTo(TargetPlayer.ActorLocation, 0.3, DeltaTime);

		// Delay before projectiles can be fired
		if (ActiveDuration < Attachment.FireDelay)
			return;

		// Adhere to fire interval
		float TimeSinceFire = Time::GetGameTimeSince(LastFireTimestamp);
		if (TimeSinceFire < Attachment.FireInterval)
			return;

		auto Projectile = Projectiles[0];

		if (IsValid(Projectile))
		{
			FVector TraceDirection = (TargetLocation.Value - Projectile.ActorCenterLocation).GetSafeNormal();
			FVector EndLocation = Projectile.ActorCenterLocation + TraceDirection * 12500.0;

			auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseSphereShape(5.0);
			
			// Ignore attachment and boss while attached to it
			Trace.IgnoreActor(Attachment);
			if (Attachment.AttachParentActor != nullptr)
				Trace.IgnoreActor(Attachment.AttachParentActor);

			// If grabbed, aim with the player
			if (Attachment.WhipResponseComponent.IsGrabbed())
			{
				EndLocation = Attachment.WhipResponseComponent.AimLocation;
			}

			auto HitResult = Trace.QueryTraceSingle(Projectile.ActorCenterLocation, EndLocation);

			if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
			{
				auto HitPlayer = Cast<AHazePlayerCharacter>(HitResult.Actor);
				auto HitBoss = Cast<ASkylineDroneBoss>(HitResult.Actor);

				if (HitPlayer != nullptr)
				{
					HitPlayer.DamagePlayerHealth(Projectile.PlayerDamage);
				}
				else if (HitBoss != nullptr)
				{
					HitBoss.HealthComponent.TakeDamage(Projectile.BossDamage);
				}
				else
				{
					SpawnActor(Attachment.TrailClass, HitResult.ImpactPoint);
				}
			}

			FSkylineDroneBossScatterProjectileFiredData FiredData;
			FiredData.Projectile = Projectile;
			FiredData.HitResult = HitResult;
			USkylineDroneBossScatterEventHandler::Trigger_ProjectileFired(Attachment, FiredData);

			Projectile.SetLifeSpan(0.1);
		}

		Projectiles.RemoveAt(0);

		LastFireTimestamp = Time::GameTimeSeconds;
	}
}