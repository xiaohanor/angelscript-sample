class UForgedWeaponCanonCapability : UInteractionCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;


	UPlayerAcidTeenDragonComponent AcidDragonComp;

	//ATeenDragon TeenDragon;
	UHazeMovementComponent MoveComp;
	AForgedWeapon ForgedWeapon;

	TArray<AForgedWeaponProjectile> ProjectilePool;

	float MaxAcidValue = 1.0;
	float AcidValue;
	float ExplosionRadius = 300.0;
	
	
	//Projectile Firing Values
	float HorizontalSpeed = 6200.0;
	float Gravity = 5200.0;
	float Distance = 12000.0;


	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		AcidDragonComp = UPlayerAcidTeenDragonComponent::Get(Owner);
		ForgedWeapon = Cast<AForgedWeapon>(Params.Interaction.Owner);

		//TeenDragon = AcidDragonComp.TeenDragon;


		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.SmoothTeleportActor(Params.Interaction.WorldLocation, Params.Interaction.WorldRotation, this, 0.8);

		Player.AttachToComponent(Params.Interaction, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!AcidDragonComp.bIsFiringAcid)
			return;

		AcidValue += DeltaTime;
		if(AcidValue < MaxAcidValue)
			return;	
		
		AcidValue = 0;
		FireProjectile();
	}

	void ActivateProjectile(AForgedWeaponProjectile Projectile)
	{
		Projectile.ActorLocation = ForgedWeapon.ProjectileSpawnLocation.WorldLocation;

		Projectile.Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ForgedWeapon.ProjectileSpawnLocation.WorldLocation, ForgedWeapon.Root.WorldLocation + ForgedWeapon.ActorForwardVector * Distance, Gravity, HorizontalSpeed);	
		Projectile.Gravity = Gravity;
		Projectile.MeshComp.SetHiddenInGame(false);
		Projectile.RemoveActorDisable(this);
	}

	private void FireProjectile()
	{
		if(ProjectilePool.Num() > 0)
		{
			for(AForgedWeaponProjectile Projectile : ProjectilePool)
			{
				if(Projectile.IsActorDisabled())
				{
					ActivateProjectile(Projectile);
					return;
				}
			}
		}
		AForgedWeaponProjectile SpawnedProjectile = SpawnActor(ForgedWeapon.Projectile, ForgedWeapon.ProjectileSpawnLocation.WorldLocation, ForgedWeapon.ProjectileSpawnLocation.WorldRotation, bDeferredSpawn = true);
		SpawnedProjectile.OurSpawner = ForgedWeapon;
		ProjectilePool.Add(SpawnedProjectile);
		ActivateProjectile(SpawnedProjectile);
		FinishSpawningActor(SpawnedProjectile);

		SpawnedProjectile.OnProjectileDestroyed.AddUFunction(this, n"OnProjectileDestroyed");

		Debug::DrawDebugSphere(ForgedWeapon.Root.WorldLocation + ForgedWeapon.ActorForwardVector * Distance, 800.0, 12, FLinearColor::Red, 14.0, 10.0);
	}


	
	UFUNCTION()
	private void OnProjectileDestroyed(AForgedWeaponProjectile Projectile)
	{
		Projectile.AddActorDisable(this);
	}


}