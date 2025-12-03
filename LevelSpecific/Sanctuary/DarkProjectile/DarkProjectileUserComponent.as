class UDarkProjectileUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditDefaultsOnly, Category = "Aiming")
	TSubclassOf<UTargetableWidget> TargetableWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Dark")
	TSubclassOf<ADarkProjectileActor> ProjectileClass;

	UPROPERTY(EditDefaultsOnly, Category = "Dark")
	FName OriginSocket = n"Spine2";

	UPROPERTY(EditDefaultsOnly, Category = "Dark")
	UAnimSequence FireSequence;

	TArray<ADarkProjectileActor> ChargedProjectiles;

	private AHazePlayerCharacter Player;
	private UPlayerAimingComponent AimComp;
	private int ProjectileIndex;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	ADarkProjectileActor SpawnProjectile(const FVector& Location = FVector::ZeroVector,
		const FRotator& Rotation = FRotator::ZeroRotator)
	{
		if (!devEnsure(ProjectileClass.IsValid(), "ProjectileClass must be set in order to spawn."))
			return nullptr;

		auto Projectile = Cast<ADarkProjectileActor>(
			SpawnActor(ProjectileClass.Get(),
				Location,
				Rotation, 
				bDeferredSpawn = true)
		);
		// Projectile.MakeNetworked(Player, n"DarkProjectile", FNetworkIdentifierPart(ProjectileIndex++));
		FinishSpawningActor(Projectile);
		
		return Projectile;
	}

	FDarkProjectileTargetData GetAimTargetData() const
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
			return FDarkProjectileTargetData(HitResult.Component,
				HitResult.ImpactPoint,
				HitResult.BoneName);
		}

		return FDarkProjectileTargetData(nullptr,
			HitResult.TraceEnd);
	}

	UFUNCTION(BlueprintPure)
	FTransform GetSocketTransform() const
	{
		return Player.Mesh.GetSocketTransform(OriginSocket);
	}
}