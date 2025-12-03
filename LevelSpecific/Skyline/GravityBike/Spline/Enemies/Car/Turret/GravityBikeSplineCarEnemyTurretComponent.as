UCLASS(NotBlueprintable, NotPlaceable)
class UGravityBikeSplineCarEnemyTurretComponent : USceneComponent
{
	access Internal = private, UGravityBikeSplineEnemyRifleComponentVisualizer;

	UPROPERTY(EditAnywhere, Category = "Turret Component|Fire")
	int MagazineCapacity = 30;

	UPROPERTY(EditAnywhere, Category = "Turret Component|Fire")
	float ReloadTime = 1;

	// Bullets per second
	UPROPERTY(EditDefaultsOnly, Category = "Turret Component|Fire")
	private float FireRate = 70;
	float FireInterval;

	UPROPERTY(EditDefaultsOnly, Category = "Turret Component|Fire")
	bool bFireIfPlayerTooSlow = true;

	// How far to trace
	UPROPERTY(EditAnywhere, Category = "Turret Component|Targeting")
	float Range = 10000;

	UPROPERTY(EditDefaultsOnly, Category = "Turret Component|Targeting")
	float RiflePlayerHitRadius = 400;

	UPROPERTY(EditDefaultsOnly, Category = "Turret Component|Targeting")
	float RifleAimAheadTime = 0.2;

	UPROPERTY(EditDefaultsOnly, Category = "Turret Component|Targeting")
	float RifleHitFraction = 0.1;

	UPROPERTY(EditAnywhere, Category = "Turret Component|Hit")
	float Damage = 0.1;

	UPROPERTY(EditAnywhere, Category = "Turret Component|Hit")
	bool bDamageIsFraction = false;

	UPROPERTY(EditAnywhere, Category = "Turret Component|Hit Player")
	float PlayerDamage = 0.1;

	private AGravityBikeSplineCarEnemy CarEnemy;
	TArray<UGravityBikeSplineCarEnemyTurretMuzzleComponent> MuzzleComponents;
	TSet<UGravityBikeSplineEnemyFireTriggerComponent> FireInstigators;

	int CurrentMuzzleIndex;

	private int CurrentAmmo = 0;
	private float StartReloadTime = -1;
	FHazeAcceleratedVector AccAimAheadAmount;
	float LastFireTime;

	bool bIsFiring = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CarEnemy = Cast<AGravityBikeSplineCarEnemy>(Owner);
		CarEnemy.GetComponentsByClass(MuzzleComponents);
		check(!MuzzleComponents.IsEmpty());

		FireInterval = 1.0 / FireRate;
		CurrentAmmo = MagazineCapacity;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this).Section("Fire", 1)
			.Value("FireInstigators", FireInstigators.Num())
			.Value("LastFireTime", LastFireTime)
			.Value("TimeSinceLastFire", TimeSinceLastFire())
			.Value("bIsFiring", bIsFiring)
		;

		TEMPORAL_LOG(this).Section("Aim", 2)
			.DirectionalArrow("AccAimAheadAmount", WorldLocation, AccAimAheadAmount.Value)
			.Point("TargetLocation", GetTargetLocation())
		;

		TEMPORAL_LOG(this).Section("Muzzle", 3)
			.Value("CurrentMuzzleIndex", CurrentMuzzleIndex)
			.Value("CurrentMuzzle", GetCurrentMuzzle())
		;

		TEMPORAL_LOG(this).Section("Ammo", 4)
			.Value("CurrentAmmo", CurrentAmmo)
			.Value("StartReloadTime", StartReloadTime)
			.Value("IsMagazineEmpty", IsMagazineEmpty())
			.Value("IsReloading", IsReloading())
			.Value("IsMagazineFull", IsMagazineFull())
			.Value("HasFinishedReloading", HasFinishedReloading())
		;
	}
#endif

	FVector GetTargetLocation() const
	{
		FVector TargetLocation = GravityBikeSpline::GetDriverPlayer().ActorLocation;

		if(GravityBikeSpline::GetGravityBikeHealth() > GravityBikeSpline::CarEnemy::Turret::MinimumHealthToFireAccurately)
		{
			const float AimAheadRand = Math::RandRange(0.0, 1.0);
			const float AimAheadAmount = AimAheadRand < RifleHitFraction ? 0 : 1;
			
			TargetLocation += AccAimAheadAmount.Value * AimAheadAmount;
		}
		else
		{
			TargetLocation += AccAimAheadAmount.Value;
		}

		return TargetLocation;
	}

	FVector GetRecoilOffset() const
	{
		return Math::GetRandomPointInSphere() * 100;
	}

	int GetMuzzleCount() const
	{
		return MuzzleComponents.Num();
	}

	UGravityBikeSplineCarEnemyTurretMuzzleComponent GetCurrentMuzzle() const
	{
		return MuzzleComponents[CurrentMuzzleIndex];
	}

	FVector GetCurrentMuzzleLocation() const
	{
		return GetMuzzleLocation(CurrentMuzzleIndex);
	}

	FVector GetMuzzleLocation(int Index) const
	{
		return MuzzleComponents[Index].WorldLocation;
	}

	void ConsumeBullet()
	{
		CurrentAmmo--;
	}

	bool IsMagazineEmpty() const
	{
		return CurrentAmmo <= 0;
	}

	bool IsReloading() const
	{
		if(!IsMagazineEmpty())
			return false;
		
		return StartReloadTime > 0;
	}

	bool IsMagazineFull() const
	{
		return CurrentAmmo == MagazineCapacity;
	}

	void StartReload()
	{
		StartReloadTime = Time::GameTimeSeconds;
	}

	void FinishReload()
	{
		CurrentAmmo = MagazineCapacity;
		StartReloadTime = -1;
	}

	bool HasFinishedReloading() const
	{
		if(Time::GetGameTimeSince(StartReloadTime) > ReloadTime)
			return true;

		return false;
	}

	float TimeSinceLastFire() const
	{
		return Time::GetGameTimeSince(LastFireTime);
	}
};