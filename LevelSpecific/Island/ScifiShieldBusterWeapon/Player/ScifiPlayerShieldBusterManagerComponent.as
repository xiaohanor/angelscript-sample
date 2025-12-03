
UCLASS(Abstract, HideCategories="Activation ComponentTick Variable Cooking ComponentReplication AssetUserData Collision")
class UScifiPlayerShieldBusterManagerComponent : UActorComponent
{
	// This component should not tick
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TSubclassOf<AScifiPlayerShieldBusterWeapon> SheildBusterWeaponClass;

	UPROPERTY()
	TSubclassOf<AScifiPlayerShieldBusterWeaponProjectile> SheildBusterWeaponProjectileClass;

	UPROPERTY()
	UScifiPlayerShieldBusterSettings DefaultSettings;

	UPROPERTY()
	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;

	UPROPERTY(EditConst, Transient, EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EScifiPlayerShieldBusterHand"))
 	TArray<AScifiPlayerShieldBusterWeapon> Weapons;
 	default Weapons.SetNumZeroed(EScifiPlayerShieldBusterHand::MAX);

	
	UPROPERTY(EditConst, BlueprintReadOnly)
	bool bHasEquipedWeapons = false;

	UPROPERTY(EditConst, Transient)
	TArray<AScifiPlayerShieldBusterWeaponProjectile> ActiveProjectiles;

	UPROPERTY(EditConst, Transient)
	int CurrentShotBullets = 0;

	UPROPERTY(EditConst, Transient)
	bool bIsReloading = false;

	float ReloadFinishTime = 0;

	UPROPERTY(EditConst, BlueprintReadOnly)
	UScifiShieldBusterTargetableComponent CurrentTarget;

	UPROPERTY(EditConst, Transient)
	EScifiPlayerShieldBusterHand LastThrowHand = EScifiPlayerShieldBusterHand::Right;
	FVector LastThrownDirection = FVector::ZeroVector;

	UScifiPlayerShieldBusterSettings Settings;

	private UHazeActorNetworkedSpawnPoolComponent ProjectileSpawnPool;
	private UHazeActorNetworkedSpawnPoolComponent WallCutterSpawnPool;

	float LastShotGameTime = 0;

	TArray<AScifiShieldBusterInternalWallCutter> ActiveWallCutters;
	TArray<FScifiShieldBusterPendingWallImpactData> PendingWallImpacts;

	TArray<UScifiShieldBusterInternalFieldBreaker> ActiveFieldBreakers;
	TArray<FScifiShieldBusterPendingFieldImpactData> PendingFieldImpacts;

	TArray<FScifiPlayerShieldBusterWeaponImpact> PendingTargetGenericImpacts;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		ProjectileSpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(SheildBusterWeaponProjectileClass, Player);
		ProjectileSpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawnedProjectile");

		WallCutterSpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(AScifiShieldBusterInternalWallCutter, Player);
		WallCutterSpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawedWallWallCutter");

		Player.ApplySettings(DefaultSettings, Instigator = this);
		Settings = UScifiPlayerShieldBusterSettings::GetSettings(Player);

		EnsureWeaponSpawn(Player, Weapons[EScifiPlayerShieldBusterHand::Left], Weapons[EScifiPlayerShieldBusterHand::Right]);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(int i = 0; i < int(EScifiPlayerShieldBusterHand::MAX); ++i)
		{
			if(Weapons[i] != nullptr)
			{
				Weapons[i].DestroyActor();
				Weapons[i] = nullptr;
			}
		}
	}

	void EnsureWeaponSpawn(AHazePlayerCharacter WielderPlayer, AScifiPlayerShieldBusterWeapon& OutLeftWeapon, AScifiPlayerShieldBusterWeapon& OutRightWeapon)
	{
		if(Weapons[EScifiPlayerShieldBusterHand::Left] == nullptr)
		{
			OutLeftWeapon = SpawnWeapon(EScifiPlayerShieldBusterHand::Left);
			OutLeftWeapon.AttachToComponent(WielderPlayer.Mesh, n"LeftAttach");
		}
		else
		{
			OutLeftWeapon = Weapons[EScifiPlayerShieldBusterHand::Left];
		}

		if(Weapons[EScifiPlayerShieldBusterHand::Right] == nullptr)
		{
			OutRightWeapon = SpawnWeapon(EScifiPlayerShieldBusterHand::Right);
			OutRightWeapon.AttachToComponent(WielderPlayer.Mesh, n"RightAttach");
		}
		else
		{
			OutRightWeapon = Weapons[EScifiPlayerShieldBusterHand::Right];
		}
	}

	AScifiPlayerShieldBusterWeapon SpawnWeapon(EScifiPlayerShieldBusterHand Type)
	{
		FName WeaponName = Type == EScifiPlayerShieldBusterHand::Left ? n"LeftShieldBusterWeapon" : n"RightShieldBusterWeapon";
		auto Weapon = SpawnActor(SheildBusterWeaponClass, Name = WeaponName);
		Weapons[Type] = Weapon;
		Weapon.AttachType = Type;
		return Weapon;
	}

	bool HasEquipedWeapons() const
	{
		// Add conditions here.
		return true;
	}

	FVector GetLastThrownDirection() const
	{
		return LastThrownDirection;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSpawnedProjectile(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		auto Projectile = Cast<AScifiPlayerShieldBusterWeaponProjectile>(SpawnedActor);
		Projectile.AddActorDisable(this);
		Projectile.Settings = Settings;
	}

	AScifiPlayerShieldBusterWeaponProjectile GetOrCreateControlSideProjectile()
	{
		return Cast<AScifiPlayerShieldBusterWeaponProjectile>(ProjectileSpawnPool.SpawnControl(FHazeActorSpawnParameters(this)));	
	}

	void ActivateProjectile(AScifiPlayerShieldBusterWeaponProjectile Projectile)
	{
		Projectile.RemoveActorDisable(this);
		ActiveProjectiles.Add(Projectile);	
		Projectile.ActivationTime = Time::GetGameTimeSeconds();
	}

	void DeactiveProjectileAtActiveIndex(int Index)
	{
		auto Projectile = ActiveProjectiles[Index];

		// Trigger deactivation event
		FScifiPlayerShieldBusterDeactivatedEventData OnDeactivatedData;
		OnDeactivatedData.Projectile = Projectile;
		UScifiPlayerShieldBusterEventHandler::Trigger_OnProjectileDeactivated(Player, OnDeactivatedData);
	
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

	AScifiShieldBusterInternalWallCutter GetOrCreateControlSideWallCutter()
	{
		return Cast<AScifiShieldBusterInternalWallCutter>(WallCutterSpawnPool.SpawnControl(FHazeActorSpawnParameters(this)));	
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSpawedWallWallCutter(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		auto Cutter = Cast<AScifiShieldBusterInternalWallCutter>(SpawnedActor);
		Cutter.AddActorDisable(this);
	}

	void ActivateWallCutter(AScifiShieldBusterInternalWallCutter Cutter)
	{
		Cutter.RemoveActorDisable(this);
	}

	void DeactiveWallCutter(AScifiShieldBusterInternalWallCutter Cutter)
	{
		Cutter.AddActorDisable(this);
		WallCutterSpawnPool.UnSpawn(Cutter);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeactiveWallCutter(AScifiShieldBusterInternalWallCutter Cutter)
	{
		DeactiveWallCutter(Cutter);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddPendingWallImpact(FScifiShieldBusterPendingWallImpactData Impact)
	{
		PendingWallImpacts.Add(Impact);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddPendingFieldImpact(FScifiShieldBusterPendingFieldImpactData Impact)
	{
		PendingFieldImpacts.Add(Impact);
	}

	UFUNCTION(CrumbFunction)
	void CrumbAddGenericTargetImpact(FScifiPlayerShieldBusterWeaponImpact Impact)
	{
		PendingTargetGenericImpacts.Add(Impact);
	}
}

struct FScifiShieldBusterPendingWallImpactData
{
	AScifiShieldBusterInternalWallCutter WallCutter;
	FScifiPlayerShieldBusterWeaponImpact Impact;	
}

struct FScifiShieldBusterPendingFieldImpactData
{
	FScifiPlayerShieldBusterWeaponImpact Impact;	
}