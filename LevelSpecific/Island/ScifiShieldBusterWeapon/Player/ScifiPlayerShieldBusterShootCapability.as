
class UScifiPlayerShieldBusterShootCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShieldBuster");
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default DebugCategory = n"ShieldBuster";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UScifiPlayerShieldBusterManagerComponent Manager;
	UPlayerMovementComponent MoveComp;
	UPlayerAimingComponent AimingComp;
	UScifiPlayerShieldBusterSettings Settings;
	float LastActiveDeltaTime = 0;
	float DeactivationDuration = 0;
	AScifiPlayerShieldBusterWeaponProjectile PendingProjectile;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerShieldBusterManagerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		Settings = Manager.Settings;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FShieldBusterShootActivationParams& ActivationParam) const
	{
		if(!Manager.bHasEquipedWeapons)
			return false;

		//if(!WasActionStartedDuringTime(ActionNames::SecondaryLevelAbility, LastActiveDeltaTime))
		//	return false;

		if(!WasActionStopped(ActionNames::SecondaryLevelAbility))
			return false;

		if(Manager.CurrentShotBullets >= Settings.MagCapacity && Settings.MagCapacity >= 0)
			return false;

		if(Manager.bIsReloading)
			return false;

		if(Settings.MaxActiveProjectiles >= 0 && Manager.ActiveProjectiles.Num() >= Settings.MaxActiveProjectiles)
			return false;

		if(!Settings.bUseLeftHand && !Settings.bUseRightHand)
			return false;

		ActivationParam.Projectile = Manager.GetOrCreateControlSideProjectile();
		ActivationParam.Target = Manager.CurrentTarget;

		if(Settings.bUseLeftHand && Settings.bUseRightHand)
			ActivationParam.ThrowHand = Manager.LastThrowHand == EScifiPlayerShieldBusterHand::Left ? EScifiPlayerShieldBusterHand::Right : EScifiPlayerShieldBusterHand::Left;
		else if(Settings.bUseLeftHand)
			ActivationParam.ThrowHand = EScifiPlayerShieldBusterHand::Left;
		else if(Settings.bUseRightHand)
			ActivationParam.ThrowHand = EScifiPlayerShieldBusterHand::Right;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Manager.bHasEquipedWeapons)
			return true;

		if(ActiveDuration >= DeactivationDuration)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FShieldBusterShootActivationParams ActivationParam)
	{
		PendingProjectile = ActivationParam.Projectile;
		Manager.LastThrowHand = ActivationParam.ThrowHand;

		AimingComp.StartAiming(this, Manager.AimSettings);
		
		FVector ThrowLocation = Manager.Weapons[Manager.LastThrowHand].GetActorLocation() + Player.ViewRotation.UpVector * 30.0;
		PendingProjectile.SetActorLocation(ThrowLocation);
		
		// A temp bonus pitch to have the projectiles not be destroyed when they hit the ground
		// when aiming down a lot. This is a TEMP fix. We need to make some nice
		// tracing to have the buster projectile follow the ground a bit.
		
		// FRotator ViewRotation = Player.GetViewRotation();
		// float BonusPitch = Math::Max(-ViewRotation.ForwardVector.DotProduct(MoveComp.WorldUp), 0);
		// BonusPitch = Math::Min(BonusPitch, 0.5) / 0.5;
		// ViewRotation += FRotator(Math::Lerp(9, 25, BonusPitch), 0.0, 0.0); // Offset the shoot direction a bit

		// Trace for impacts from camera to crosshair location 
		// Set direction of projectiles to from hands to impact location of line trace
		FHazeTraceSettings TraceProfile = Trace::InitChannel(ETraceTypeQuery::WeaponTraceZoe); //ETraceTypeQuery::   PlayerAiming WeaponTraceZoe
		TraceProfile.UseLine();
		TraceProfile.IgnoreActor(Game::Zoe);
		FRotator HudRotation = Player.GetViewRotation() + FRotator(6.5, 0.0, 0.0);
		FHitResult HitLocation = TraceProfile.QueryTraceSingle(Player.GetViewLocation() + HudRotation.ForwardVector*50.0, Player.GetViewLocation() + HudRotation.ForwardVector*3000.0);
		
		FVector ProjectileDirection(0.0, 0.0, 0.0);

		if(HitLocation.bBlockingHit)
			ProjectileDirection = (HitLocation.ImpactPoint - ThrowLocation).GetSafeNormal();

		else
			ProjectileDirection = ((Player.GetViewLocation() + HudRotation.ForwardVector*3000.0) - ThrowLocation).GetSafeNormal();

		PendingProjectile.MoveDirection = ProjectileDirection;
		PendingProjectile.LaunchTarget = ActivationParam.Target;
		PendingProjectile.CurrentMovementSpeed = Settings.InitialSpeed;

		// Trigger shoot event
		FScifiPlayerShieldBusterOnShootEventData ShootData;
		ShootData.Projectile = PendingProjectile;
		ShootData.HandLocation = ThrowLocation;
		ShootData.ShootDirection = PendingProjectile.GetWantedMovementDirection();
		UScifiPlayerShieldBusterEventHandler::Trigger_OnShoot(Player, ShootData);

		Manager.LastThrownDirection = PendingProjectile.GetWantedMovementDirection();
		Manager.LastShotGameTime = Time::GetGameTimeSeconds();

		Manager.CurrentShotBullets += 1;

		DeactivationDuration = Settings.CooldownBetweenProjectile + Settings.ReleaseProjectileDelay;
		if(Settings.MagCapacity < 0)
		{
			// Infinite ammo
			Manager.CurrentShotBullets = 0;
		}
		else if(Manager.CurrentShotBullets >= Settings.MagCapacity)
		{
			Manager.bIsReloading = true;
			Manager.ReloadFinishTime = Time::GetGameTimeSeconds() + Settings.ReloadTime;	
		}		

		Player.Mesh.RequestOverrideFeature(n"ShieldBuster", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// We need to wait a little bit for the throw animation
		if(PendingProjectile != nullptr)
		{
			Manager.ActivateProjectile(PendingProjectile);

			// Offset slightly up to match with hand location
			FVector ThrowLocation = Manager.Weapons[Manager.LastThrowHand].GetActorLocation() + Player.ViewRotation.UpVector * 30.0; 
			PendingProjectile.SetActorLocationAndRotation(ThrowLocation, PendingProjectile.GetWantedMovementDirection().ToOrientationQuat());
		}

		if(Manager.bIsReloading)
		{
			Manager.bIsReloading = false;
			Manager.CurrentShotBullets = 0;
		}

		AimingComp.StopAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LastActiveDeltaTime = DeltaTime;
	}
};

struct FShieldBusterShootActivationParams
{
	AScifiPlayerShieldBusterWeaponProjectile Projectile;
	EScifiPlayerShieldBusterHand ThrowHand = EScifiPlayerShieldBusterHand::MAX;
	UScifiShieldBusterTargetableComponent Target;
}