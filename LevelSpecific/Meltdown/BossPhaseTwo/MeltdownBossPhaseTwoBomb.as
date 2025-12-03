UCLASS(Abstract)
class AMeltdownBossPhaseTwoBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TelegraphRoot;
	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UTelegraphDecalComponent TelegraphDecal;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDamageEffect> BombEffect;

	float ExplodeDelay = 2.0;
	float ExplodeRadius = 650.0;

	float Gravity = 20000.0;
	float HorizontalSpeed = 6000.0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> MissileLandingShake;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> MissileExplodingShake;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent MissileLandingFF;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent MissileExplodingFF;

	FVector FiredLocation;
	FVector TargetLocation;

	Trajectory::FOutCalculateVelocity Trajectory;
	float Timer = 0.0;

	bool bHasHit = false;
	AMeltdownBossPhaseTwo Rader;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Launch(FVector StartLocation, FVector EndLocation)
	{
		FiredLocation = StartLocation;
		TargetLocation = EndLocation;

		ActorLocation = StartLocation;

		Trajectory = Trajectory::CalculateParamsForPathWithHorizontalSpeed(
			StartLocation, TargetLocation, Gravity, HorizontalSpeed
		);

		UMeltdownBossPhaseTwoBombEffectHandler::Trigger_BombLaunch(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Rader != nullptr && Rader.IsDead())
		{
			AddActorDisable(n"RaderDead");
			return;
		}

		Timer += DeltaSeconds;
		if (Timer < Trajectory.Time)
		{
			FVector NewLocation = FiredLocation + Trajectory.Velocity * Timer + FVector(0, 0, -Gravity) * Math::Square(Timer) * 0.5;
			FVector NewVelocity = Trajectory.Velocity + FVector(0, 0, -Gravity) * Timer;

			FQuat NewRotation = FQuat::MakeFromX(NewVelocity);
			if (Timer > Trajectory.Time - 0.5)
			{
				NewRotation = FQuat::Slerp(NewRotation, FQuat::MakeFromX(FVector::DownVector), 1.0 - (Trajectory.Time - Timer) / 0.5);
			}

			SetActorLocationAndRotation(NewLocation, NewRotation);
		}
		else
		{
			SetActorLocationAndRotation(TargetLocation, FQuat::MakeFromX(FVector::DownVector));
			TelegraphDecal.ShowTelegraph();

			if (!bHasHit)
			{
				UMeltdownBossPhaseTwoBombEffectHandler::Trigger_BombHit(this);
				bHasHit = true;
				MissileLandingFF.Play();
				for (AHazePlayerCharacter Player : Game::Players)
				{
					Player.PlayWorldCameraShake(MissileLandingShake,this, ActorCenterLocation, 1000.0,1600.0,);
				}

			}

			if (Timer > Trajectory.Time + ExplodeDelay)
			{
				for (auto Player : Game::Players)
				{
					if (Player.GetDistanceTo(this) < ExplodeRadius)
					{
						Player.DamagePlayerHealth(0.5, DamageEffect = BombEffect);

						MissileExplodingFF.Play();

						Player.PlayWorldCameraShake(MissileExplodingShake,this, ActorCenterLocation, 1000.0,1600.0);
	
						FKnockdown Knockdown;
						Knockdown.Duration = 1.0;
						Knockdown.Move = (Player.ActorLocation - ActorLocation).GetSafeNormal2D() * 800.0;
						if (Knockdown.Move.IsNearlyZero())
							Knockdown.Move = FVector(800, 0, 0);
						Player.ApplyKnockdown(Knockdown);
					}
				}

				UMeltdownBossPhaseTwoBombEffectHandler::Trigger_BombExplode(this);
				DestroyActor();
			}
		}
	}
};

UCLASS(Abstract)
class UMeltdownBossPhaseTwoBombEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void BombLaunch() {}
	UFUNCTION(BlueprintEvent)
	void BombHit() {}
	UFUNCTION(BlueprintEvent)
	void BombExplode() {}
}