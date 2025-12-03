class ULightProjectileUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly, Category = "Aiming")
	TSubclassOf<UTargetableWidget> TargetableWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Light")
	TSubclassOf<ALightProjectileActor> ProjectileClass;

	UPROPERTY(EditDefaultsOnly, Category = "Light")
	UAnimSequence FireSequence;

	bool bIsCharging;
	TArray<ALightProjectileActor> ChargedProjectiles;
	float CooldownEnd;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;
	private int ProjectileIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	ALightProjectileActor SpawnProjectile(const FVector& Location = FVector::ZeroVector,
		const FRotator& Rotation = FRotator::ZeroRotator)
	{
		if (!devEnsure(ProjectileClass.IsValid(), "ProjectileClass must be set in order to spawn."))
			return nullptr;

		auto Projectile = Cast<ALightProjectileActor>(
			SpawnActor(ProjectileClass.Get(), 
				Location,
				Rotation,
				bDeferredSpawn = true)
		);
		// Projectile.MakeNetworked(Player, n"LightProjectile", FNetworkIdentifierPart(ProjectileIndex++));
		FinishSpawningActor(Projectile);

		return Projectile;
	}

	FLightProjectileTargetData GetAimTargetData() const
	{
		auto AimResult = AimComp.GetAimingTarget(this);

		const FVector TraceStart = Math::ClosestPointOnInfiniteLine(
			AimResult.AimOrigin,
			AimResult.AimOrigin + (AimResult.AimDirection * LightProjectile::AimRange),
			Player.ActorCenterLocation
		);
		const FVector TraceEnd = TraceStart + (AimResult.AimDirection * LightProjectile::AimRange);

		auto Trace = Trace::InitChannel(ETraceTypeQuery::PlayerAiming);
		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		if (HitResult.bBlockingHit && HitResult.Component != nullptr)
		{
			return FLightProjectileTargetData(HitResult.Component,
				HitResult.ImpactPoint,
				HitResult.BoneName);
		}

		return FLightProjectileTargetData(nullptr,
			HitResult.TraceEnd);
	}

	UFUNCTION(BlueprintPure)
	FTransform GetSpineTransform() const
	{
		return Player.Mesh.GetSocketTransform(LightProjectile::SpineSocketName);
	}

	UFUNCTION(BlueprintPure)
	FVector GetWingDirection(int Index) const
	{
		const FQuat SpineRotation = GetSpineTransform().Rotation;
		const FVector UpVector = -SpineRotation.UpVector;
		const float PairedIndex = Math::IntegerDivisionTrunc(Index, 2);

		float Angle = LightProjectile::Wings::AngularOffset;
		Angle += (LightProjectile::Wings::AngularStep * PairedIndex);
		Angle += GetDriftAngle(Index);

		if (Index % 2 == 1)
			Angle *= -1.0;

		return UpVector.RotateAngleAxis(Angle, SpineRotation.ForwardVector);
	}

	UFUNCTION(BlueprintPure)
	float GetWingLength(int Index) const
	{
		const float PairedIndex = Math::IntegerDivisionTrunc(Index, 2);
		return LightProjectile::Wings::Length + (LightProjectile::Wings::LengthStep * PairedIndex);
	}

	UFUNCTION(BlueprintPure)
	float GetDriftAngle(int Index) const
	{
		const float PairedIndex = Math::IntegerDivisionTrunc(Index, 2);
		const float StepSize = PI / LightProjectile::NumProjectiles;
		const float Alpha = Math::Sin(Time::GameTimeSeconds * LightProjectile::Wings::DriftFrequency + (StepSize * PairedIndex)) / 2.0;

		return Alpha * LightProjectile::Wings::DriftMagnitude;
	}

	UFUNCTION(BlueprintPure)
	bool IsFullyCharged() const
	{
		return (ChargedProjectiles.Num() >= LightProjectile::NumProjectiles);
	}
}