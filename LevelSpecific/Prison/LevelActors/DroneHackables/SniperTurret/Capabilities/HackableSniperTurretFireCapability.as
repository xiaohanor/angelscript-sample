struct FHackableSniperTurretFireActivateParams
{
	UPROPERTY()
	bool bHit;
	
	UPROPERTY()
	FSniperTurretOnHitParams HitParams;
}

/**
 * Handles firing the sniper turret
 */
class UHackableSniperTurretFireCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneHijackCapability);
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 130;

	AHackableSniperTurret SniperTurret;
	AHazePlayerCharacter Player;
	UPlayerAimingComponent AimingComp;
	UHazeInputComponent InputComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SniperTurret = Cast<AHackableSniperTurret>(Owner);
		Player = Drone::GetSwarmDronePlayer();
		AimingComp = UPlayerAimingComponent::Get(Player);
		InputComp = UHazeInputComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHackableSniperTurretFireActivateParams& Params) const
	{
		if (!SniperTurret.HijackTargetableComp.IsHijacked())
			return false;

		if(SniperTurret.HackedDuration < SniperTurret.FOV_BLENDTIME)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		
		if(!SniperTurret.bHasZoomed)
			return false;

		const FHitResult Hit = SniperTurret.Trace();

		if(Hit.bBlockingHit && Hit.Actor != nullptr && Hit.Component != nullptr)
		{
			Params.bHit = true;
			Params.HitParams = FSniperTurretOnHitParams(Hit, SniperTurret.GetTraceSettings(), SniperTurret.MuzzleComp.GetForwardVector());
		}
		else
		{
			Params.bHit = false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > SniperTurret.ReloadTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHackableSniperTurretFireActivateParams Params)
	{
		FSniperTurretOnFireParams OnFireParams;
		OnFireParams.MuzzleLocation = SniperTurret.MuzzleComp.GetWorldLocation();
		OnFireParams.MuzzleRotation = FRotator::MakeFromZ(SniperTurret.MuzzleComp.GetForwardVector());
		UHackableSniperTurretEventHandler::Trigger_OnFire(SniperTurret, OnFireParams);

		if(Params.bHit)
			OnHit(Params.HitParams);
		else
			OnMiss();

		SniperTurret.FiredFrame = Time::FrameNumber;
		SniperTurret.bIsReloading = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SniperTurret.bIsReloading = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	void OnHit(FSniperTurretOnHitParams OnHitParams)
	{
		AActor HitActor = OnHitParams.Component.GetOwner();

		if(HitActor == nullptr)
			return;

		AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(HitActor);
		if(HitPlayer != nullptr)
			HitPlayer.KillPlayer(FPlayerDeathDamageParams(),SniperTurret.KillZoeDeathEffect);

		UHackableSniperTurretEventHandler::Trigger_OnHit(SniperTurret, OnHitParams);

		UHackableSniperTurretResponseComponent ResponseComp = UHackableSniperTurretResponseComponent::Get(HitActor);
		if (ResponseComp != nullptr)
		{
			FHackableSniperTurretHitEventData HitEventData;
			HitEventData.TraceDirection = OnHitParams.TraceDirection;
			HitEventData.ImpactNormal = OnHitParams.GetImpactNormal();
			HitEventData.ImpactPoint = OnHitParams.GetImpactPoint();
			ResponseComp.OnHackableSniperTurretHit.Broadcast(HitEventData);
		}

		FHackableSniperTurretFireEventData EventData;
		EventData.bHit = true;
		SniperTurret.OnSniperTurretFire.Broadcast(EventData);

		ShootProjectile(OnHitParams.Component.WorldTransform.TransformPosition(OnHitParams.RelativeHitImpactPoint));

		if(SniperTurret.DEBUG_DRAW)
			Debug::DrawDebugLine(SniperTurret.MuzzleComp.GetWorldLocation(), OnHitParams.GetImpactPoint(), FLinearColor::Yellow, 5.0, 2.0);
	}

	void OnMiss()
	{
		FHackableSniperTurretFireEventData EventData;
		EventData.bHit = false;
		SniperTurret.OnSniperTurretFire.Broadcast(EventData);

		FVector TargetLoc = SniperTurret.MuzzleComp.WorldLocation + Player.ViewRotation.ForwardVector * 20000.0;
		FTransform TargetTransform;
		TargetTransform.Translation = TargetLoc;
		ShootProjectile(TargetTransform.TransformPosition(FVector::ZeroVector));

		if(SniperTurret.DEBUG_DRAW)
		{
			const FAimingResult AimResult = AimingComp.GetAimingTarget(SniperTurret);
			const FVector TraceEnd = AimResult.AimOrigin + AimResult.AimDirection * SniperTurret.Range;
			Debug::DrawDebugLine(SniperTurret.MuzzleComp.GetWorldLocation(), TraceEnd, FLinearColor::Red, 5.0, 2.0);
		}
	}

	void ShootProjectile(FVector TargetLoc)
	{
		FVector SpawnLoc = SniperTurret.MuzzleComp.WorldLocation;
		if (SniperTurret.CurrentProjectile != nullptr)
			SniperTurret.CurrentProjectile.SetActorLocationAndRotation(SpawnLoc, SniperTurret.MuzzleComp.ForwardVector.Rotation());
		else
			SniperTurret.CurrentProjectile = SpawnActor(SniperTurret.ProjectileClass, SpawnLoc, SniperTurret.MuzzleComp.ForwardVector.Rotation());

		SniperTurret.CurrentProjectile.Shoot(TargetLoc);
	}
}