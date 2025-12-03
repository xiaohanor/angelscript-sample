UCLASS(Abstract)
class ASkylineBossFootStompImpact : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;

	UPROPERTY(EditDefaultsOnly)
	float ExpireTime = 2.0; // 8.0

	bool bExpired = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionEnabled = ECollisionEnabled::NoCollision;
//	default Collision.CollisionProfileName = n"OverlapAllDynamic";

	TArray<AGravityBikeFree> BikesInsideFootStomp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timer::SetTimer(this, n"Expire", ExpireTime);

		OnActorBeginOverlap.AddUFunction(this, n"HandleActorBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"HandleActorEndOverlap");
//		Collision.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
	
//		Bikes.Add(GravityBikeFree::GetGravityBike(Game::Mio));
//		Bikes.Add(GravityBikeFree::GetGravityBike(Game::Zoe));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Bike : BikesInsideFootStomp)
		{
			if (bExpired)
				continue;

			if (Bike.MoveComp.HasGroundContact())
			{
				if (Bike.GetDriver().IsPlayerInvulnerable())
					continue;

				auto Boss = TListedActors<ASkylineBoss>().Single;
				FPlayerDeathDamageParams Params;
				Params.ImpactDirection = (Bike.ActorLocation - ActorLocation).SafeNormal;
				Bike.GetDriver().DamagePlayerHealth(0.5, DamageEffect = Boss.DeathDamageComp.FireSoftDamageEffect, DeathEffect = Boss.DeathDamageComp.FireSoftDeathEffect, DeathParams = Params);
			}
/*
			if (Bike.MoveComp.HasGroundContact())
			{
				FVector ToBike = Bike.ActorLocation - ActorLocation;
				float Distance = ToBike.Size();
				if (Distance < Collision.SphereRadius)
					Bike.GetDriver().DamagePlayerHealth(0.5);
			}
*/
		}
	}

	UFUNCTION()
	private void HandleActorBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		if(!OtherActor.HasControl())
			return;

		auto GravityBikeFree = Cast<AGravityBikeFree>(OtherActor);
		if (GravityBikeFree == nullptr)
			return;

		BikesInsideFootStomp.AddUnique(GravityBikeFree);
//		GravityBikeFree.GetDriver().DamagePlayerHealth(0.5);
	}

	UFUNCTION()
	private void HandleActorEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		if(!OtherActor.HasControl())
			return;
		

		auto GravityBikeFree = Cast<AGravityBikeFree>(OtherActor);
		if (GravityBikeFree == nullptr)
			return;

		BikesInsideFootStomp.Remove(GravityBikeFree);
//		GravityBikeFree.GetDriver().DamagePlayerHealth(0.5);
	}

	UFUNCTION()
	private void HandleOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if(!OtherActor.HasControl())
			return;

		auto GravityBikeFree = Cast<AGravityBikeFree>(OtherActor);
		if (GravityBikeFree == nullptr)
			return;

		GravityBikeFree.GetDriver().DamagePlayerHealth(0.5);
	}

	UFUNCTION()
	void Expire()
	{
		bExpired = true;
		Timer::SetTimer(this, n"Remove", 1.0);
	}

	UFUNCTION()
	void Remove()
	{
		DestroyActor();
	}
};