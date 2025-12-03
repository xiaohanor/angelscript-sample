
UCLASS(Abstract, HideCategories="Activation ComponentTick Variable Cooking ComponentReplication AssetUserData Collision")
class UScifiPlayerGravityGrenadeManagerComponent : UActorComponent
{
	// This component should not tick
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TSubclassOf<AScifiPlayerGravityGrenadeWeapon> GravityGrenadeWeaponClass;

	UPROPERTY()
	UScifiPlayerGravityGrenadeSettings DefaultSettings;

	UPROPERTY()
	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;

	UPROPERTY(EditConst, Transient, EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EScifiPlayerGravityGrenadeHand"))
 	AScifiPlayerGravityGrenadeWeapon Weapon;

	
	UPROPERTY(EditConst, BlueprintReadOnly)
	bool bHasEquipedWeapons = false;

	UPROPERTY(EditConst, Transient)
	TArray<AScifiPlayerGravityGrenadeWeaponProjectile> ActiveProjectiles;

	UPROPERTY(EditConst, BlueprintReadOnly)
	UScifiGravityGrenadeTargetableComponent CurrentTarget;

	FVector LastThrownDirection = FVector::ZeroVector;

	UScifiPlayerGravityGrenadeSettings Settings;

	private UHazeActorNetworkedSpawnPoolComponent ProjectileSpawnPool;
	private UHazeActorNetworkedSpawnPoolComponent WallCutterSpawnPool;

	float LastShotGameTime = 0;

	TArray<FScifiPlayerGravityGrenadeWeaponImpact> PendingTargetGenericImpacts;
	TArray<FScifiGravityGrenadePendingGravityObjectImpactData> PendingGravityObjectImpacts;

	AHazePlayerCharacter Player;

	UPROPERTY()
	TSubclassOf<AScifiPlayerGravityGrenadeWeaponProjectile> GravityGrenadeWeaponProjectileClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		ProjectileSpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(GravityGrenadeWeaponProjectileClass, Player);
		ProjectileSpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawnedProjectile");

		Player.ApplySettings(DefaultSettings, Instigator = this);
		Settings = UScifiPlayerGravityGrenadeSettings::GetSettings(Player);

		EnsureWeaponSpawn(Player, Weapon);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(Weapon != nullptr)
			Weapon.DestroyActor();
	}

	void EnsureWeaponSpawn(AHazePlayerCharacter WielderPlayer, AScifiPlayerGravityGrenadeWeapon& OutWeapon)
	{
		if(Weapon == nullptr)
		{
			OutWeapon = SpawnWeapon();
			OutWeapon.AttachToComponent(WielderPlayer.Mesh, n"RightAttach");
		}

		else
		{
			OutWeapon = Weapon;
		}

		
	}

	AScifiPlayerGravityGrenadeWeapon SpawnWeapon()
	{
		auto FuncWeapon = SpawnActor(GravityGrenadeWeaponClass);
		return FuncWeapon;
	}

	FVector GetLastThrownDirection() const
	{
		return LastThrownDirection;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSpawnedProjectile(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		auto Projectile = Cast<AScifiPlayerGravityGrenadeWeaponProjectile>(SpawnedActor);
		Projectile.AddActorDisable(this);
		Projectile.Settings = Settings;
	}

	AScifiPlayerGravityGrenadeWeaponProjectile GetOrCreateControlSideProjectile()
	{
		return Cast<AScifiPlayerGravityGrenadeWeaponProjectile>(ProjectileSpawnPool.SpawnControl(FHazeActorSpawnParameters(this)));	
	}

	void ActivateProjectile(AScifiPlayerGravityGrenadeWeaponProjectile Projectile)
	{
		Projectile.RemoveActorDisable(this);
		ActiveProjectiles.Add(Projectile);	
		Projectile.ActivationTime = Time::GetGameTimeSeconds();
		Projectile.CalculateUpSpeed();
	}

	void DeactiveProjectileAtActiveIndex(int Index)
	{
		auto Projectile = ActiveProjectiles[Index];

		// Trigger deactivation event
		FScifiPlayerGravityGrenadeDeactivatedEventData OnDeactivatedData;
		OnDeactivatedData.Projectile = Projectile;
		UScifiPlayerGravityGrenadeEventHandler::Trigger_OnProjectileDeactivated(Player, OnDeactivatedData);
	
		ActiveProjectiles.RemoveAtSwap(Index);
		Projectile.AddActorDisable(this);
		ProjectileSpawnPool.UnSpawn(Projectile);
	}

	void DeactivateAllProjectiles()
	{
		for(auto Projectile : ActiveProjectiles)
		{
			Projectile.AddActorDisable(this);
			ProjectileSpawnPool.UnSpawn(Projectile);
		}
		ActiveProjectiles.Reset();
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddGenericTargetImpact(FScifiPlayerGravityGrenadeWeaponImpact Impact)
	{
		PendingTargetGenericImpacts.Add(Impact);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddGravityObjectImpact(FScifiGravityGrenadePendingGravityObjectImpactData Impact)
	{
		PendingGravityObjectImpacts.Add(Impact);
	}
}

struct FScifiGravityGrenadePendingGravityObjectImpactData
{
	FScifiPlayerGravityGrenadeWeaponImpact Impact;	
}
