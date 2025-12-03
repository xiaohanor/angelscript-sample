class UCoastBossAeronauticPlayerMoveBulletsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Movement;

	UCoastBossAeronauticComponent AeroComp;
	ACoastBoss2DPlane ConstrainPlane;

	ACoastBossActorReferences References;
	TArray<ACoastBossPlayerBullet> Unspawns;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AeroComp = UCoastBossAeronauticComponent::Get(Player);
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
	void TickActive(float DeltaTime)
	{
		if (ConstrainPlane == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			if (Refs.Num() > 0)
			{
				References = Refs.Single;
				ConstrainPlane = References.CoastBossPlane2D;
			}
		}

		if (ConstrainPlane == nullptr)
			return;

		for (int iBullet = 0; iBullet < AeroComp.ActiveBullets.Num(); ++iBullet)
			UpdateBullet(AeroComp.ActiveBullets[iBullet], DeltaTime);

		for (int iUnspawn = 0; iUnspawn < Unspawns.Num(); ++iUnspawn)
		{
			Unspawns[iUnspawn].RespawnComp.UnSpawn();
			Unspawns[iUnspawn].AliveDuration = 0.0;
			Unspawns[iUnspawn].AddActorDisable(Unspawns[iUnspawn]);
		}
		Unspawns.Empty();
	}

	void UpdateBullet(ACoastBossPlayerBullet Bullet, float DeltaSeconds)
	{
		Bullet.AliveDuration += DeltaSeconds;

		if(Bullet.bIsHomingBullet)
		{
			float Size = Bullet.Velocity.Size();
			FVector2D Direction = Bullet.Velocity / Size;
			FVector TargetDirection = References.Boss.ActorLocation - Bullet.ActorLocation;
			FVector2D TargetDirection2D = ConstrainPlane.GetDirectionOnPlane(TargetDirection);
			FQuat Current = FVector(Direction.X, Direction.Y, 0.0).ToOrientationQuat();
			FQuat Target = FVector(TargetDirection2D.X, TargetDirection2D.Y, 0.0).ToOrientationQuat();
			FVector Result = Math::QInterpTo(Current, Target, DeltaSeconds, CoastBossConstants::PowerUp::HomingInterpSpeed).ForwardVector;
			FVector2D Result2D = FVector2D(Result.X, Result.Y);
			Bullet.Velocity = Result2D * Size;
		}

		Bullet.ManualRelativeLocation += Bullet.Velocity * DeltaSeconds;
		FVector WorldLocation = ConstrainPlane.GetLocationInWorld(Bullet.ManualRelativeLocation);
		FRotator BulletRotation = FRotator::MakeFromXZ(ConstrainPlane.GetDirectionInWorld(Bullet.Velocity), ConstrainPlane.ActorUpVector);

		float DeltaScale = Bullet.TargetScale - Bullet.Scale;
		Bullet.Scale += DeltaScale * DeltaSeconds;
		Bullet.Scale = Math::Clamp(Bullet.Scale, 0.01, 1.0);
		Bullet.SetActorScale3D(FVector::OneVector * Bullet.Scale);

		Bullet.SetActorLocationAndRotation(WorldLocation, BulletRotation);

		if (ConstrainPlane.IsOutsideOfPlaneX(Bullet.ManualRelativeLocation))
			Bullet.TargetScale = 0.01;

		if (Bullet.bShouldDespawn || Bullet.Scale < 0.1 || Bullet.AliveDuration > Bullet.MaxAliveTime || ConstrainPlane.IsOutsideOfPlaneY(Bullet.ManualRelativeLocation))
			Unspawns.Add(Bullet);
	}
}