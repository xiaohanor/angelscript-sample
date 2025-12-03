event void FGravityBikeSplineBikeEnemyDriverPistolOnFire(UGravityBikeSplineBikeEnemyDriverPistolComponent PistolComponent, FVector Location, FVector tDirection, FHitResult HitResult);

class UGravityBikeSplineBikeEnemyDriverPistolComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Pistol Component|Fire")
	private int MagazineCapacity = 10;

	UPROPERTY(EditAnywhere, Category = "Pistol Component|Fire")
	private float ReloadTime = 1;

	// Bullets per second
	UPROPERTY(EditDefaultsOnly, Category = "Pistol Component|Fire")
	private float FireRate = 20;
	private float FireInterval;

	UPROPERTY(EditDefaultsOnly, Category = "Pistol Component|Fire")
	bool bFireIfPlayerTooSlow = true;

	// How far to trace
	UPROPERTY(EditAnywhere, Category = "Pistol Component|Targeting")
	float Range = 10000;

	UPROPERTY(EditDefaultsOnly, Category = "Pistol Component|Targeting")
	private float PistolPlayerHitRadius = 400;

	UPROPERTY(EditDefaultsOnly, Category = "Pistol Component|Targeting")
	float PistolAimAheadTime = 0.2;

	UPROPERTY(EditDefaultsOnly, Category = "Pistol Component|Targeting")
	private float PistolHitFraction = 0.1;

	UPROPERTY(EditAnywhere, Category = "Pistol Component|Hit")
	private float Damage = 0.1;

	UPROPERTY(EditAnywhere, Category = "Pistol Component|Hit")
	private bool bDamageIsFraction = false;

	UPROPERTY(EditAnywhere, Category = "Pistol Component|Hit Player")
	private float PlayerDamage = 0.1;

	// Broadcast every time we fire, can be broadcast multiple times per frame!
	UPROPERTY(Category = "Pistol Component")
	private FGravityBikeSplineBikeEnemyDriverPistolOnFire OnFire;

	private AGravityBikeSplineBikeEnemyDriver Driver;
	TSet<UGravityBikeSplineEnemyFireTriggerComponent> FireInstigators;

	// Set this to prevent multiple Pistol components on the same actor from firing together
	private int CurrentAmmo = 0;
	private float StartReloadTime = -1;
	FHazeAcceleratedVector AccAimAheadAmount;
	private float LastFireTime;

	bool bIsFiring = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(Owner);
		FireInterval = 1.0 / FireRate;
		CurrentAmmo = MagazineCapacity;
	}

	bool IsGrabbed() const
	{
		if(Driver.GrabTargetComp == nullptr)
			return false;

		return Driver.GrabTargetComp.IsGrabbed();
	}

	FVector GetTargetLocation() const
	{
		return GravityBikeSpline::GetDriverPlayer().ActorLocation;
	}

	FVector GetRecoilOffset() const
	{
		return Math::GetRandomPointInSphere() * 100;
	}

	bool IsPlayerTooSlow() const
	{
		if(bFireIfPlayerTooSlow)
		{
			auto GravityBike = GravityBikeSpline::GetGravityBike();
			if(GravityBike == nullptr)
				return false;

			if(!GravityBike.BlockEnemySlowRifleFire.IsEmpty())
				return false;
			
			const float SpeedAlpha = GravityBike.GetSpeedAlpha(GravityBike.GetForwardSpeed());
			if(SpeedAlpha < GravityBikeSpline::BikeEnemyDriver::Pistol::FireIfUnderSpeedAlpha)
				return true;
		}

		return false;
	}

	void TryFire()
	{
		if(IsReloading())
		{
			if(HasFinishedReloading())
				FinishReload();
			else
				return;	// We are reloading!
		}

		if(TimeSinceLastFire() > FireInterval)
		{
			const FVector Start = Driver.GetPistolMuzzleLocation();
			FVector TargetLocation = GetTargetLocation();

			if(GravityBikeSpline::GetGravityBikeHealth() > GravityBikeSpline::BikeEnemyDriver::Pistol::MinimumHealthToFireAccurately)
			{
				const float AimAheadRand = Math::RandRange(0.0, 1.0);
				const float AimAheadAmount = AimAheadRand < PistolHitFraction ? 0 : 1;
				
				TargetLocation += AccAimAheadAmount.Value * AimAheadAmount;
			}
			else
			{
				TargetLocation += AccAimAheadAmount.Value;
			}

			FVector Recoil = GetRecoilOffset();

			if(IsPlayerTooSlow())
				Recoil *= GravityBikeSpline::BikeEnemyDriver::Pistol::IfUnderSpeedRecoilMultiplier;

			TargetLocation += Recoil;

			const FVector FireDirection = (TargetLocation - Start).GetSafeNormal();

			Fire(Start, FireDirection);
		}
	}

	private void Fire(FVector Start, FVector Direction)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnoreActor(Owner);
		Trace.UseLine();

		FVector End = Start + Direction * Range;

		FHitResult HitResult = Trace.QueryTraceSingle(Start, End);

		if(HitResult.bBlockingHit)
		{
			float DealtDamage = PlayerDamage;
			if(IsPlayerTooSlow())
				DealtDamage *= GravityBikeSpline::BikeEnemyDriver::Pistol::IfUnderSpeedDamageMultiplier;

			GravityBikeSpline::TryDamagePlayerHitResult(HitResult, DealtDamage);
		}

		LastFireTime = Time::GameTimeSeconds;

		ConsumeBullet();

		if(IsMagazineEmpty())
			StartReload();

		OnFire.Broadcast(this, Start, Direction, HitResult);

		FGravityBikeSplineBikeEnemyDriverPistolFireEventData EventData;
		EventData.PistolComponent = this;
		EventData.HitResult = HitResult;
		EventData.StartLocation = Start;
		EventData.StartDirection = Direction;
		UGravityBikeSplineBikeEnemyDriverPistolEventHandler::Trigger_OnPistolFire(Driver, EventData);

		if(HitResult.bBlockingHit)
			UGravityBikeSplineBikeEnemyDriverPistolEventHandler::Trigger_OnPistolFireTraceImpact(Driver, EventData);
	}

	private void ConsumeBullet()
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

	private void FinishReload()
	{
		CurrentAmmo = MagazineCapacity;
		StartReloadTime = -1;
	}

	private bool HasFinishedReloading() const
	{
		if(Time::GetGameTimeSince(StartReloadTime) > ReloadTime)
			return true;

		return false;
	}

	private float TimeSinceLastFire() const
	{
		return Time::GetGameTimeSince(LastFireTime);
	}
};