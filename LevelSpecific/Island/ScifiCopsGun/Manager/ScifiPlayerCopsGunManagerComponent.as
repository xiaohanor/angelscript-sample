
// class ACopsGunRandomSeedGeneration : AHazeActor
// {
// 	UPROPERTY(VisibleAnywhere, Category = "Bullets")
// 	TArray<FVector> RandomBulletDirection;

// 	UFUNCTION(CallInEditor)
// 	void Generation()
// 	{
// 		for(int i = 0; i < 100; ++i)
// 		{
// 			FVector Dir = Math::GetRandomPointOnSphere();
// 			if(Dir.IsNearlyZero())
// 				Dir = FVector::UpVector;
// 			RandomBulletDirection.Add(Dir);
// 		}
// 	}
// }

struct FScifiCopsGunReplicatedImpactResponseData
{
	UScifiCopsGunImpactResponseComponent ResponseComponent;
	FVector RelativeImpactLocation;
}


UCLASS(Abstract, HideCategories="Activation ComponentTick Variable Cooking ComponentReplication AssetUserData Collision")
class UScifiPlayerCopsGunManagerComponent : UActorComponent
{
	// This component should not tick
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Weapon")
	TSubclassOf<AScifiCopsGun> GunClass;
	
	UPROPERTY(Category = "Weapon")
	TSubclassOf<ACopsGunTurret> TurretClass;
	
	UPROPERTY(Category = "Weapon")
	TSubclassOf<AScifiCopsGunBullet> BulletClass;

	UPROPERTY(Category = "Weapon")
	TSubclassOf<UScifiCopsGunHeatWidget> HeatWidgetClass;

	UPROPERTY(Category = "Settings")
	UScifiPlayerCopsGunSettings DefaultSettings;

	UPROPERTY(Category = "Settings")
	TPerPlayer<UHazeLocomotionFeatureBundle> PlayerAnimations;
	
	UPROPERTY(Category = "Aim")
	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.CrosshairLingerDuration = 1;

	UPROPERTY(Category = "Aim")
	UHazeCameraSpringArmSettingsDataAsset AimCameraSettings;

	UPROPERTY(NotEditable, Transient, Category = "Weapon", EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EScifiPlayerCopsGunType"))
 	TArray<AScifiCopsGun> Weapons;
 	default Weapons.SetNumZeroed(EScifiPlayerCopsGunType::MAX);

	UPROPERTY(Category = "Settings")
	TArray<FVector> RandomBulletDirection;

	UPROPERTY(NotEditable, Transient, Category = "Settings")
	TArray<AScifiCopsGunBullet> ActiveBullets;

	UPROPERTY(NotEditable, Transient, Category = "Turret")
	ACopsGunTurret Turret;

	TArray<FName> HandAttachStocket;
	default HandAttachStocket.SetNum(EScifiPlayerCopsGunType::MAX);
	default HandAttachStocket[EScifiPlayerCopsGunType::Left] = n"LeftAttach";
	default HandAttachStocket[EScifiPlayerCopsGunType::Right] = n"RightAttach";

	TArray<FName> ThighAttachStocket;
	default ThighAttachStocket.SetNum(EScifiPlayerCopsGunType::MAX);
	default ThighAttachStocket[EScifiPlayerCopsGunType::Left] = n"LeftUpLegRoll2";
	default ThighAttachStocket[EScifiPlayerCopsGunType::Right] = n"RightUpLegRoll2";

	AHazePlayerCharacter PlayerOwner;
	UScifiPlayerCopsGunSettings Settings;
	UHazeActorLocalSpawnPoolComponent BulletSpawnPool;
	EScifiPlayerCopsGunType LastWeapon = EScifiPlayerCopsGunType::Left;
	TArray<FInstigator> AimDownSightInstigators;
	TArray<FInstigator> WantToShootInstigators;
	
	bool bPlayerWantsToThrowWeapon = false;
	//bool bPlayerWantsToShootWeapon = false;
	bool bPlayerIsShooting = false;
	bool bForceRecal = false;
	bool bTurretIsActive = false;

	private float CurrentHeatInternal = 0;
	private bool bHasTriggeredOverHeatInternal = false;

	EScifiPlayerCopsGunState CurrentWeaponStatus = EScifiPlayerCopsGunState::MAX;
	EScifiPlayerCopsGunWeaponAttachEventType CurrentAttachmentStatus = EScifiPlayerCopsGunWeaponAttachEventType::Unset;
	FInstigator CurrentWeaponStatusInstigator;
	float CurrentWeaponStatusGameTime = 0;

	TArray<FScifiCopsGunReplicatedImpactResponseData> PendingBulletImpactsResponse;
	UScifiCopsGunThrowTargetableComponent CurrentThrowTargetPoint;
	UScifiCopsGunShootTargetableComponent CurrentShootAtTarget;
	UScifiCopsGunInternalEnvironmentThrowTargetableComponent InternalEnvironmentTarget;

	int RandomBulletDirectonIndex = 0;
	int BulletsLeftToReturn = -1;
	float TimeLeftUntilReturn = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		BulletSpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(BulletClass, PlayerOwner);
		BulletSpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnBulletSpawned");

		PlayerOwner.ApplySettings(DefaultSettings, Instigator = this);
		Settings = UScifiPlayerCopsGunSettings::GetSettings(PlayerOwner);

		SpawnWeapon(EScifiPlayerCopsGunType::Left);
		SpawnWeapon(EScifiPlayerCopsGunType::Right);

		Weapons[EScifiPlayerCopsGunType::Left].OtherWeapon = Weapons[EScifiPlayerCopsGunType::Right];
		Weapons[EScifiPlayerCopsGunType::Right].OtherWeapon = Weapons[EScifiPlayerCopsGunType::Left];

		FinishSpawningActor(Weapons[EScifiPlayerCopsGunType::Left]);
		FinishSpawningActor(Weapons[EScifiPlayerCopsGunType::Right]);

		PlayerOwner.AddLocomotionFeatureBundle(PlayerAnimations[PlayerOwner.Player], this);

		Turret = SpawnActor(TurretClass, Name = n"CopsGunTurret", bDeferredSpawn = true);
		Turret.MakeNetworked(PlayerOwner, this);
		Turret.PlayerOwner = PlayerOwner;
		FinishSpawningActor(Turret);

		bTurretIsActive = false;
		Turret.AddActorDisable(this);

		// Create a targetable component that we place on envirionment to target
		InternalEnvironmentTarget = UScifiCopsGunInternalEnvironmentThrowTargetableComponent::Create(PlayerOwner, n"EnvironmentTarget");
		InternalEnvironmentTarget.bIsAutoAimEnabled = false;
	}


	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		PlayerOwner.RemoveLocomotionFeatureBundle(PlayerAnimations[PlayerOwner.Player], this);
		for(int i = 0; i < int(EScifiPlayerCopsGunType::MAX); ++i)
		{
			if(Weapons[i] != nullptr)
			{
				Weapons[i].DestroyActor();
				Weapons[i] = nullptr;
			}
		}

		Turret.DestroyActor();
		Turret = nullptr;
	}

	void EnsureWeaponSpawn(AHazePlayerCharacter Player, AScifiCopsGun& OutLeftWeapon, AScifiCopsGun& OutRightWeapon)
	{
		EnsureWeaponSpawn(Player, EScifiPlayerCopsGunType::Left, OutLeftWeapon);
		EnsureWeaponSpawn(Player, EScifiPlayerCopsGunType::Right, OutRightWeapon);
	}

	void EnsureWeaponSpawn(AHazePlayerCharacter Player, EScifiPlayerCopsGunType Hand, AScifiCopsGun& OutWeapon)
	{
		OutWeapon = Weapons[Hand];
		devCheck(OutWeapon != nullptr, "Weapon not spawned!");
	}

	private AScifiCopsGun SpawnWeapon(EScifiPlayerCopsGunType Type)
	{
		FName WeaponName = Type == EScifiPlayerCopsGunType::Left ? n"LeftCopsGun" : n"RightCopsGun";
		auto Weapon = SpawnActor(GunClass, Name = WeaponName, bDeferredSpawn = true);
		Weapon.MakeNetworked(PlayerOwner, this, WeaponName);

		Weapons[Type] = Weapon;
		Weapon.AttachType = Type;
		Weapon.CurrentState = EScifiPlayerCopsGunState::UnEquiped;
		Weapon.CurrentStateActivationTime = Time::GetGameTimeSeconds();
		Weapon.AttachSocket = ThighAttachStocket[Type];
		Weapon.PlayerOwner = PlayerOwner;
		Weapon.Settings = Settings;
	//	Weapon.BulletsLeftToReload = Settings.MagCapacity;
		return Weapon;
	}


	UFUNCTION(NotBlueprintCallable)
	void OnBulletSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		auto Bullet = Cast<AScifiCopsGunBullet>(SpawnedActor);
		Bullet.AddActorDisable(this);
		Bullet.Settings = Settings;
	}

	// AScifiCopsGunBullet GetOrCreateControlSideProjectile()
	// {
	// 	auto Bullet = Cast<AScifiCopsGunBullet>(BulletSpawnPool.SpawnControl(FHazeActorSpawnParameters(this)));	
	// 	Bullet.Reset();
	// 	return Bullet;
	// }

	AScifiCopsGunBullet GetOrCreateLocalProjectile()
	{
		auto Bullet = Cast<AScifiCopsGunBullet>(BulletSpawnPool.Spawn(FHazeActorSpawnParameters(this)));	
		Bullet.Reset();
		return Bullet;
	}

	void ActivateBullet(AScifiCopsGunBullet Bullet)
	{
		Bullet.RemoveActorDisable(this);
		ActiveBullets.Add(Bullet);	
		Bullet.ActivationTime = Time::GetGameTimeSeconds();
		Bullet.SetActorRotation(Bullet.MoveDirection.ToOrientationRotator());
	}

	void DeactiveBulletAtActiveIndex(int Index)
	{
		auto Bullet = ActiveBullets[Index];
		ActiveBullets.RemoveAtSwap(Index);
		Bullet.AddActorDisable(this);
		BulletSpawnPool.UnSpawn(Bullet);
	}

	EScifiPlayerCopsGunType GetOtherHand(EScifiPlayerCopsGunType Hand) const
	{
		if(Hand == EScifiPlayerCopsGunType::Left)
			return EScifiPlayerCopsGunType::Right;
		else
			return EScifiPlayerCopsGunType::Left;
	}

	void AttachWeaponToPlayerHand(AScifiCopsGun Weapon, FInstigator Instigator)
	{
		if(LeftWeapon == nullptr || RightWeapon == nullptr)
			return;
			
		if(CurrentWeaponStatus == EScifiPlayerCopsGunState::AttachToHand)
		{
			CurrentWeaponStatusInstigator = Instigator;
			return;
		}

		Weapon.CurrentState = EScifiPlayerCopsGunState::AttachToHand;
		Weapon.CurrentStateActivationTime = Time::GetGameTimeSeconds();
		Weapon.AttachToComponent(PlayerOwner.Mesh, HandAttachStocket[Weapon.AttachType]);
		Weapon.SetActorRelativeScale3D(Weapon.OriginalScale);
		Weapon.MeshOffset.SetRelativeTransform(FTransform::Identity);
		
		if(Weapon.IsLeftWeapon())
		{
			Weapon.RootComponent.RelativeRotation = FRotator(90, -90, 0);
			Weapon.RootComponent.RelativeLocation = FVector(0, 0, 0);
		}
		else
		{
			Weapon.RootComponent.RelativeRotation = FRotator(90, 90, 0);
			Weapon.RootComponent.RelativeLocation = FVector(0, 0, 0);
		}

		FScifiPlayerCopsGunWeaponAttachEventData AttachEvent;
		AttachEvent.Type = EScifiPlayerCopsGunWeaponAttachEventType::PlayerHand;
		AttachEvent.ImpactLocation = Weapon.GetActorLocation();
		UScifiCopsGunEventHandler::Trigger_OnWeaponAttach(Weapon, AttachEvent);

		if(LeftWeapon.IsWeaponAttachedToPlayerHand() && RightWeapon.IsWeaponAttachedToPlayerHand())
		{
			const EScifiPlayerCopsGunState PrevState = CurrentWeaponStatus;
			CurrentWeaponStatusInstigator = Instigator;
			CurrentWeaponStatus = EScifiPlayerCopsGunState::AttachToHand;
			CurrentAttachmentStatus = AttachEvent.Type;
			CurrentWeaponStatusGameTime = Time::GameTimeSeconds;
			UScifiPlayerCopsGunEventHandler::Trigger_OnWeaponsAttach(PlayerOwner, AttachEvent);
			
			if(PrevState != EScifiPlayerCopsGunState::MAX && PrevState != EScifiPlayerCopsGunState::AttachToThigh)
			{
				// Audio only triggering pre-impact logic for left weapon
				LeftWeapon.bHasTriggeredAudioPreImpact = false;	
			}
		}
	}

	void AttachWeaponToPlayerThigh(AScifiCopsGun Weapon, FInstigator Instigator)
	{	
		if(LeftWeapon == nullptr || RightWeapon == nullptr)
			return;
		
		if(CurrentWeaponStatus == EScifiPlayerCopsGunState::AttachToThigh)
		{
			CurrentWeaponStatusInstigator = Instigator;
			return;
		}
		
		Weapon.CurrentState = EScifiPlayerCopsGunState::AttachToThigh;
		Weapon.CurrentStateActivationTime = Time::GetGameTimeSeconds();
		Weapon.AttachToComponent(PlayerOwner.Mesh, ThighAttachStocket[Weapon.AttachType]);
		Weapon.SetActorRelativeScale3D(Weapon.OriginalScale);
		Weapon.MeshOffset.SetRelativeTransform(FTransform::Identity);
		
		if(Weapon.IsLeftWeapon())
		{
			Weapon.RootComponent.RelativeRotation = FRotator(90, 0, 0);
			Weapon.RootComponent.RelativeLocation = FVector(0, -7, -10);
		}
		else
		{
			Weapon.RootComponent.RelativeRotation = FRotator(90, 0, 0);
			Weapon.RootComponent.RelativeLocation = FVector(0, 7, -10);
		}

		FScifiPlayerCopsGunWeaponAttachEventData AttachEvent;
		AttachEvent.Type = EScifiPlayerCopsGunWeaponAttachEventType::PlayerThigh;
		AttachEvent.ImpactLocation = Weapon.GetActorLocation();
		UScifiCopsGunEventHandler::Trigger_OnWeaponAttach(Weapon, AttachEvent);

		if(LeftWeapon.IsWeaponAttachedToPlayerThigh() && RightWeapon.IsWeaponAttachedToPlayerThigh())
		{
			const EScifiPlayerCopsGunState PrevState = CurrentWeaponStatus;
			CurrentWeaponStatusInstigator = Instigator;
			CurrentWeaponStatus = EScifiPlayerCopsGunState::AttachToThigh;
			CurrentAttachmentStatus = AttachEvent.Type;
			CurrentWeaponStatusGameTime = Time::GameTimeSeconds;
			UScifiPlayerCopsGunEventHandler::Trigger_OnWeaponsAttach(PlayerOwner, AttachEvent);

			// skip the initial attachment
			// when first created, we attach the weapons to the thighs
			if(PrevState != EScifiPlayerCopsGunState::MAX && PrevState != EScifiPlayerCopsGunState::AttachToHand)
			{
				// Make sure we always start fresh when we get the weapons back
				ClearHeat();

				// Audio only triggering pre-impact logic for left weapon
				LeftWeapon.bHasTriggeredAudioPreImpact = false;
			}		
		}
	}

	void DetachWeaponFromPlayer(AScifiCopsGun Weapon, FInstigator Instigator)
	{
		if(LeftWeapon == nullptr || RightWeapon == nullptr)
			return;
		
		if(CurrentWeaponStatus == EScifiPlayerCopsGunState::UnEquiped)
		{
			CurrentWeaponStatusInstigator = Instigator;
			return;
		}
		
		Weapon.CurrentState = EScifiPlayerCopsGunState::UnEquiped;
		Weapon.CurrentStateActivationTime = Time::GetGameTimeSeconds();
		Weapon.RootComponent.RelativeRotation = FRotator::ZeroRotator;
		Weapon.RootComponent.RelativeLocation = FVector::ZeroVector;
		Weapon.DetachRootComponentFromParent();
		Weapon.SyncedMovement.Value = Weapon.ActorLocation;
		Weapon.SyncedMovement.SnapRemote();
		Weapon.SetActorRelativeScale3D(Weapon.OriginalScale);

		FScifiPlayerCopsGunWeaponDetachEventData DetachEvent;
		DetachEvent.AttachedTypeWhenDetached = CurrentAttachmentStatus;
		UScifiCopsGunEventHandler::Trigger_OnWeaponDetach(Weapon, DetachEvent);

		if(!LeftWeapon.IsWeaponAttachedToPlayer() && !RightWeapon.IsWeaponAttachedToPlayer())
		{
			CurrentWeaponStatus = EScifiPlayerCopsGunState::UnEquiped;
			CurrentWeaponStatusInstigator = Instigator;
			CurrentWeaponStatusGameTime = Time::GameTimeSeconds;
			CurrentAttachmentStatus = EScifiPlayerCopsGunWeaponAttachEventType::Unset;
			UScifiPlayerCopsGunEventHandler::Trigger_OnWeaponsDetach(PlayerOwner, DetachEvent);
		}
	}

	void AttachWeaponToThrowAtTarget(FScifiPlayerCopsGunImpact NewImpact, FInstigator Instigator)
	{	
		if(LeftWeapon.IsWeaponAttachedToTarget() && RightWeapon.IsWeaponAttachedToTarget())
		{
			// Make sure we always start fresh when we get the weapons back
			ClearHeat();
			CurrentWeaponStatusInstigator = Instigator;
			CurrentWeaponStatus = EScifiPlayerCopsGunState::AttachedToTarget;
			CurrentWeaponStatusGameTime = Time::GameTimeSeconds;
			BulletsLeftToReturn = Settings.StayAtTargetWhileShootingMaxBulletCount;

			auto WeaponTarget = NewImpact.GetWeaponTarget();
			if(WeaponTarget != nullptr && WeaponTarget.bUseCustomStayAtTargetTime)
				TimeLeftUntilReturn = WeaponTarget.CustomStayAtTargetTime;
			else
				TimeLeftUntilReturn = Settings.StayAtNoneShootingTargetMaxTime;	
		}

		// early out validations
		{
			if(NewImpact.Actor == nullptr)
				return;
			
			auto ResponseComp = UScifiCopsGunImpactResponseComponent::Get(NewImpact.Actor);
			if(ResponseComp == nullptr)
				return;

			ResponseComp.ApplyWeaponImpact(PlayerOwner);
		}
	}

	void DetachWeaponFromThrowAtTarget(AScifiCopsGun Weapon, FInstigator Instigator)
	{
		if(LeftWeapon == nullptr || RightWeapon == nullptr)
			return;
		
		if(CurrentWeaponStatus == EScifiPlayerCopsGunState::UnEquiped)
		{
			CurrentWeaponStatusInstigator = Instigator;
			return;
		}

		if(CurrentWeaponStatus != EScifiPlayerCopsGunState::AttachedToTarget)
			return;

		if(Weapon.IsLeftWeapon())
			DeactivateTurret();

		Weapon.DetachRootComponentFromParent();
		Weapon.CurrentState = EScifiPlayerCopsGunState::UnEquiped;

		FScifiPlayerCopsGunWeaponDetachEventData DetachEvent;
		DetachEvent.Attachment = CurrentThrowTargetPoint;
		DetachEvent.AttachedTypeWhenDetached = CurrentAttachmentStatus;
		UScifiCopsGunEventHandler::Trigger_OnWeaponDetach(Weapon, DetachEvent);

		if(!LeftWeapon.IsWeaponAttachedToTarget() && !RightWeapon.IsWeaponAttachedToTarget())
		{
			CurrentWeaponStatus = EScifiPlayerCopsGunState::UnEquiped;
			CurrentWeaponStatusInstigator = Instigator;
			CurrentAttachmentStatus = EScifiPlayerCopsGunWeaponAttachEventType::Unset;
			CurrentWeaponStatusGameTime = Time::GameTimeSeconds;
			UScifiPlayerCopsGunEventHandler::Trigger_OnWeaponsDetach(Weapon.PlayerOwner, DetachEvent);	
		}
	}

	void ThrowWeapons(FScifiPlayerCopsGunWeaponTarget ActivationParams, FInstigator Instigator)
	{
		if(CurrentWeaponStatus == EScifiPlayerCopsGunState::MovingToTarget)
		{
			CurrentWeaponStatusInstigator = Instigator;
			return;
		}

		DetachWeaponFromPlayer(LeftWeapon, Instigator);
		DetachWeaponFromPlayer(RightWeapon, Instigator);
		LeftWeapon.MoveWeaponToTarget(ActivationParams);
		RightWeapon.MoveWeaponToTarget(ActivationParams);
		CurrentWeaponStatus = EScifiPlayerCopsGunState::MovingToTarget;
		CurrentWeaponStatusInstigator = Instigator;
		CurrentWeaponStatusGameTime = Time::GameTimeSeconds;
	}

	void RecallWeapons(FInstigator Instigator)
	{
		if(WeaponsAreAttachedToPlayer())
			return;
		
		if(CurrentWeaponStatus == EScifiPlayerCopsGunState::Recalled)
		{
			CurrentWeaponStatusInstigator = Instigator;
			return;
		}

		if(WeaponsAreAttachedToTarget())
		{
			DetachWeaponFromThrowAtTarget(LeftWeapon, Instigator);
			DetachWeaponFromThrowAtTarget(RightWeapon, Instigator);
		}

		LeftWeapon.RecallInternal();
		RightWeapon.RecallInternal();
		CurrentWeaponStatus = EScifiPlayerCopsGunState::Recalled;
		CurrentWeaponStatusInstigator = Instigator;
		CurrentWeaponStatusGameTime = Time::GameTimeSeconds;

		UScifiPlayerCopsGunEventHandler::Trigger_OnRecall(PlayerOwner);

		if(CurrentThrowTargetPoint != nullptr)
		{
			auto ResponseComp = UScifiCopsGunImpactResponseComponent::Get(CurrentThrowTargetPoint.Owner);
			if(ResponseComp != nullptr)
			{
				ResponseComp.ApplyWeaponReturningToPlayer(PlayerOwner);
			}
		}

	}
	
	void ApplyBulletImpactEffect(FScifiPlayerCopsGunImpact NewImpact)
	{	
		if(NewImpact.Actor == nullptr)
			return;

		// Trigger shoot event
		FScifiPlayerCopsGunBulletOnImpactEventData BulletImpactData;
		BulletImpactData.ImpactLocation = NewImpact.ImpactLocation;
		BulletImpactData.ImpactNormal = NewImpact.ImpactNormal;
		BulletImpactData.ToBullet = NewImpact.Direction;
		BulletImpactData.BulletTarget = NewImpact.BulletTarget;
		BulletImpactData.PhysMat = NewImpact.PhysMat;
		auto WeaponInstigator = Weapons[NewImpact.Gun];
		UScifiCopsGunEventHandler::Trigger_OnBulletImpact(WeaponInstigator, BulletImpactData);
		
		// auto ResponseComp = UScifiCopsGunImpactResponseComponent::Get(NewImpact.Actor);
		// if(ResponseComp == nullptr)
		// 	return;

		// if(NewImpact.BulletTarget != nullptr)
		// {
		// 	ResponseComp.OnApplyBulletImpact(PlayerOwner, NewImpact.BulletTarget, NewImpact.BulletImpactParams);		
		// }
	}

	void ActivateTurret(UCopsGunAutoAimTargetComponentBase CurrentAttachment)
	{
		if(!bTurretIsActive)
		{
			bTurretIsActive = true;
			Turret.RemoveActorDisable(this);
		}

		BulletsLeftToReturn = Settings.StayAtTargetWhileShootingMaxBulletCount;


		Turret.CurrentAttachment = Cast<UScifiCopsGunThrowTargetableComponent>(CurrentAttachment);
		check(Turret.CurrentAttachment != nullptr);
		Turret.AttachToComponent(CurrentAttachment);
		Turret.SetActorScale3D(FVector::OneVector);

		for(auto Weapon : Weapons)
		{
			Weapon.AddActorVisualsBlock(this);
		}

		BlockWeaponUsage(Turret);
	}

	void DeactivateTurret()
	{
		if(!bTurretIsActive)
			return;
		
		bTurretIsActive = false;
		Turret.AddActorDisable(this);
		for(auto Weapon : Weapons)
		{
			Weapon.RemoveActorVisualsBlock(this);
		}

		UnblockWeaponUsage(Turret);
	}

	void BlockWeaponUsage(FInstigator Instigator)
	{
		for(auto Weapon : Weapons)
		{
			Weapon.UsageBlocked.AddUnique(Instigator);
		}
	}

	void UnblockWeaponUsage(FInstigator Instigator)
	{
		for(auto Weapon : Weapons)
		{
			Weapon.UsageBlocked.RemoveSingleSwap(Instigator);
		}
	}

	FHazeTraceSettings InitCopsGunTrace(FName CustomTraceTag = NAME_None) const
	{
		FHazeTraceSettings Out;
		Out = Trace::InitChannel(Settings.TraceChannel, CustomTraceTag);
		for (auto Player : Game::Players)
	 		Out.IgnoreActor(Player);
		return Out;
	}

	FHitResult QueryTrace(FHazeTraceSettings TraceSettings, FVector From, FVector To) const
	{
		auto Hits = TraceSettings.QueryTraceMulti(From, To);
		FVector LineDelta = To - From;

		for(auto Hit : Hits)
		{
			if(!Hit.bBlockingHit)
				continue;

			auto ShieldWall = Cast<AScifiShieldBusterEnergyWall>(Hit.Actor);
			if(ShieldWall == nullptr)
				return Hit;

			if(ShieldWall.CurrentWallCutter == nullptr)
				return Hit;

			
			bool bIsIntersecting = Overlap::QueryShapeSweep(
				FCollisionShape(), FTransform(From), LineDelta,
				FCollisionShape::MakeSphere(ShieldWall.CurrentWallCutter.CurrentSize), 
				FTransform(ShieldWall.CurrentWallCutter.MovementZone.WorldLocation),
			);

			// if the line is not intersecting the wall cutter, we can't shoot through the hole
			if(!bIsIntersecting)
				return Hit;
		}

		FHitResult Empty;
		Empty.Time = 1.0;
		Empty.Distance = LineDelta.Size();
		Empty.TraceStart = From;
		Empty.TraceEnd = To;
		return Empty;
	}

	bool GetbIsInAimDownSight() const property
	{
		return AimDownSightInstigators.Num() > 0;
	}

	bool GetbPlayerWantsToShootWeapon() const property
	{
		return WantToShootInstigators.Num() > 0;
	}

	bool WeaponsAreAttachedToPlayerHand() const
	{
		return GetLeftWeapon().IsWeaponAttachedToPlayerHand() && GetRightWeapon().IsWeaponAttachedToPlayerHand();
	}

	bool WeaponsAreAttachedToPlayerHand(FInstigator AttachmentInstigator) const
	{
		if(CurrentWeaponStatusInstigator != AttachmentInstigator)
			return false;
		return GetLeftWeapon().IsWeaponAttachedToPlayerHand() && GetRightWeapon().IsWeaponAttachedToPlayerHand();
	}

	bool WeaponsAreAttachedToPlayerThigh() const
	{
		return GetLeftWeapon().IsWeaponAttachedToPlayerThigh() && GetRightWeapon().IsWeaponAttachedToPlayerThigh();
	}

	bool WeaponsAreAttachedToPlayer() const
	{
		return WeaponsAreAttachedToPlayerHand() || WeaponsAreAttachedToPlayerThigh();
	}

	bool WeaponsAreAttachedToTarget() const
	{
		return GetLeftWeapon().IsWeaponAttachedToTarget() && GetRightWeapon().IsWeaponAttachedToTarget();
	}

	FVector GetWeaponsMedianLocation() const
	{
		return (GetLeftWeapon().ActorLocation + GetRightWeapon().ActorLocation) * 0.5;
	}

	FVector GetWeaponsAimDirection() const
	{
		FVector WeaponAimDir = PlayerOwner.GetControlRotation().ForwardVector;
		if(WeaponsAreAttachedToTarget())
		{
			FVector LeftDir = GetLeftWeapon().InternalMoveToTarget.WorldRotation.ForwardVector;
			FVector RightDir = GetRightWeapon().InternalMoveToTarget.WorldRotation.ForwardVector;
			WeaponAimDir = (LeftDir + RightDir).GetSafeNormal();
		}
		
		return WeaponAimDir;
	}			

	AScifiCopsGun GetLeftWeapon() const property
	{
		return Weapons[EScifiPlayerCopsGunType::Left];
	} 

	AScifiCopsGun GetRightWeapon() const property
	{
		return Weapons[EScifiPlayerCopsGunType::Right];
	} 

	float GetCurrentHeat() const property
	{
		return CurrentHeatInternal;
	}

	bool HasTriggeredOverheat() const
	{
		return bHasTriggeredOverHeatInternal;
	}

	void TriggerOverheat()
	{
		bHasTriggeredOverHeatInternal = true;
		CurrentHeatInternal = Settings.MaxHeat;
	}

	void IncreaseHeat(float Multiplier = 1)
	{
		if(Settings.HeatIncreasePerBullet < KINDA_SMALL_NUMBER)
			return;

		CurrentHeatInternal += Settings.HeatIncreasePerBullet * Multiplier;
		CurrentHeatInternal = Math::Min(CurrentHeatInternal, Settings.MaxHeat);
	}

	void SetHeat(float Amount)
	{
		CurrentHeatInternal = Amount;
	}

	void ClearHeat()
	{
		CurrentHeatInternal = 0;
		bHasTriggeredOverHeatInternal = false;
	}

	float GetCooldownBetweenBulletsModifier() const
	{
		float Modifier = 1.0;
		if(CurrentHeat > KINDA_SMALL_NUMBER && Settings.MaxHeat > KINDA_SMALL_NUMBER)
		{
			float HeatAlpha = Math::Clamp(CurrentHeat / Settings.MaxHeat, 0.0, 1.0);
			Modifier *= Settings.HeatCooldownBetweenBulletsModifier.GetFloatValue(HeatAlpha);
		}
		return Modifier;
	}
}


