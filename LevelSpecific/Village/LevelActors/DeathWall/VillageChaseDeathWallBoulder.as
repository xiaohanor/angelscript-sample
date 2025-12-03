event void FVillageChaseDeathWallBoulderImpactEvent(AVillageChaseDeathWallBoulder Boulder);

UCLASS(Abstract)
class AVillageChaseDeathWallBoulder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BoulderRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FVillageChaseDeathWallBoulderImpactEvent OnImpact;

	bool bThrown = false;
	FVector StartLocation;
	AHazePlayerCharacter TargetPlayer;

	float ThrowAlpha = 0.0;
	float ThrowSpeed = 0.75;
	float ThrowHeight = 800.0;
	
	bool bReachedTarget = false;

	float MaxLifeTime = 5.0;
	float CurrentLifeTime = 0.0;

	FVector FreeFlyDirection;

	void ThrowBoulder(AHazePlayerCharacter Player, float Speed = 0.75, float Height = 800.0)
	{
		TargetPlayer = Player;
		StartLocation = ActorLocation;
		ThrowSpeed = Speed;
		ThrowHeight = Height;
		bThrown = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bThrown)
			return;

		if (!bReachedTarget)
		{
			ThrowAlpha = Math::Clamp(ThrowAlpha + ThrowSpeed * DeltaTime, 0.0, 1.0);

			FHazeRuntimeSpline RuntimeSpline;
			RuntimeSpline.AddPoint(StartLocation);

			FVector DirToTarget = (TargetPlayer.ActorCenterLocation - StartLocation).GetSafeNormal();
			FVector MidPoint = StartLocation + (DirToTarget * StartLocation.Dist2D(TargetPlayer.ActorCenterLocation)/2);
			MidPoint.Z = MidPoint.Z + ThrowHeight;
			RuntimeSpline.AddPoint(MidPoint);

			RuntimeSpline.AddPoint(TargetPlayer.ActorCenterLocation);
			RuntimeSpline.SetCustomCurvature(1.0);

			SetActorLocation(RuntimeSpline.GetLocation(ThrowAlpha));
			AddActorLocalRotation(FRotator(45.0, 60.0, 75.0) * 5.0 * DeltaTime);

			if (ThrowAlpha >= 1.0)
			{
				FreeFlyDirection = RuntimeSpline.GetDirectionAtDistance(RuntimeSpline.Length);
				HitPlayer();
			}
		}
		else
		{
			CurrentLifeTime += DeltaTime;
			if (CurrentLifeTime >= MaxLifeTime)
				TriggerImpact();

			FVector DeltaMove = FreeFlyDirection * 1200 * DeltaTime;
			AddActorWorldOffset(DeltaMove);
			AddActorLocalRotation(FRotator(45.0, 60.0, 75.0) * 5.0 * DeltaTime);

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(this);
			Trace.IgnorePlayers();
			Trace.UseSphereShape(30.0);

			FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + FVector::UpVector);
			if (Hit.bBlockingHit)
			{
				TriggerImpact();
			}
		}
	}

	void HitPlayer()
	{
		bReachedTarget = true;
		TargetPlayer.KillPlayer(FPlayerDeathDamageParams(FreeFlyDirection), DeathEffect);
	}

	void TriggerImpact()
	{
		BP_Impact();
		
		OnImpact.Broadcast(this);
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact() {}
}