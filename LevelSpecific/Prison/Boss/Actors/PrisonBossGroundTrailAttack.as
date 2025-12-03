UCLASS(Abstract)
class APrisonBossGroundTrailAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent TrailEffectComp;

	FSplinePosition SplinePos;
	UPROPERTY(BlueprintReadOnly)
	UHazeSplineComponent OriginalSplineComp;
	bool bOnCircleSpline = false;
	float MaxCircleSplineDistance = 600.0;
	float CircleSplineStartDistance = 0.0;
	bool bWrapMaxDistance = false;

	float HighestDistanceReached = 0.0;

	bool bActive = false;
	float MoveSpeed;

	FLinearColor DebugColor;

	bool bReachedEnd = false;

	UPROPERTY(EditAnywhere)
	float DestroyDelay = 1.0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		DebugColor = FLinearColor::MakeRandomColor();
	}

	void ActivateTrail(UHazeSplineComponent SplineComp, bool bForward, float Speed, float MaxSplineDist)
	{
		AttachToComponent(OriginalSplineComp, NAME_None, EAttachmentRule::KeepWorld);
		OriginalSplineComp = SplineComp;
		SplinePos = FSplinePosition(SplineComp, 0.0, bForward);
		MoveSpeed = Speed;
		MaxCircleSplineDistance = MaxSplineDist;

		bActive = true;

		UPrisonBossGroundTrailEffectEventHandler::Trigger_Spawn(this);
	}

	void ActivateTrailAttached(USceneComponent AttachComp, UHazeSplineComponent SplineComp)
	{
		OriginalSplineComp = SplineComp;
		AttachToComponent(AttachComp);

		UPrisonBossGroundTrailEffectEventHandler::Trigger_Spawn(this);
	}

	void Explode(bool bAlternateExplosion)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			bool bKillPlayer = false;
			FVector ClosestLocation = OriginalSplineComp.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
			float Dist = ClosestLocation.Distance(Player.ActorLocation);
			if (Dist <= PrisonBoss::GroundTrailDamageRange)
				bKillPlayer = true;

			if (SplinePos.CurrentSpline != nullptr && SplinePos.CurrentSpline != OriginalSplineComp)
			{
				ClosestLocation = SplinePos.CurrentSpline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
				Dist = ClosestLocation.Distance(Player.ActorLocation);
				if (Dist <= PrisonBoss::GroundTrailDamageRange)
					bKillPlayer = true;
			}

			if (bKillPlayer)
				Player.DamagePlayerHealth(1.0, FPlayerDeathDamageParams(FVector::UpVector), DamageEffect, DeathEffect);
		}

		BP_Explode(bAlternateExplosion);

		Timer::SetTimer(this, n"Destroy", DestroyDelay);

		UPrisonBossGroundTrailEffectEventHandler::Trigger_Explode(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode(bool bAlternateExplosion) {}

	UFUNCTION()
	void Destroy()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
			SetActorLocation(SplinePos.WorldLocation);

			SplinePos.Move(MoveSpeed * DeltaTime);

			if (SplinePos.CurrentSpline == OriginalSplineComp && HighestDistanceReached >= SplinePos.CurrentSplineDistance)
			{
				StopMoving();
				return;
			}

			if (SplinePos.CurrentSpline != OriginalSplineComp)
			{
				if (!bOnCircleSpline)
				{
					bOnCircleSpline = true;
					CircleSplineStartDistance = SplinePos.CurrentSplineDistance;

					if (CircleSplineStartDistance + MaxCircleSplineDistance >= SplinePos.CurrentSpline.SplineLength)
					{
						bWrapMaxDistance = true;
						CircleSplineStartDistance = Math::Wrap(CircleSplineStartDistance + MaxCircleSplineDistance, 0.0, SplinePos.CurrentSpline.SplineLength);
					}
				}

				if (bWrapMaxDistance)
				{
					if (SplinePos.CurrentSplineDistance < SplinePos.CurrentSpline.SplineLength/2.0 && SplinePos.CurrentSplineDistance >= CircleSplineStartDistance)
						StopMoving();
				}
				else if (SplinePos.CurrentSplineDistance >= CircleSplineStartDistance + MaxCircleSplineDistance)
					StopMoving();
			}
			
			HighestDistanceReached = SplinePos.CurrentSplineDistance;
		}
	}

	void StopMoving()
	{
		bActive = false;
		SetActorTickEnabled(false);
		bReachedEnd = true;
	}

	UFUNCTION()
	void UpdateExplodeAlpha(float Alpha)
	{
		BP_UpdateExplodeAlpha(Alpha);
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateExplodeAlpha(float Alpha) {}
}