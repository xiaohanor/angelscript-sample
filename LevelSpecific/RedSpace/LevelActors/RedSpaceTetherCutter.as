event void FRedSpaceTetherCutterEvent();

UCLASS(Abstract)
class ARedSpaceTetherCutter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CutterRoot;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float MoveDuration = 12.0;

	float SplineDist = 0.0;
	float MoveSpeed = 1600.0;

	UPROPERTY(NotVisible)
	ARedSpaceTether TetherActor;

	UPROPERTY()
	FRedSpaceTetherCutterEvent OnPlayersKilled;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	TSoftObjectPtr<AOcclusionZone> OcclusionZone;

	FVector CachedSplineLocation;
	bool bActive = false;
	float MoveTimeOffset = 0;

	bool bKilledByCutter = false;
	float RespawnedAtTime = 0.0;

	UPROPERTY(BlueprintReadOnly)
	bool bStartedMovingFX = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TetherActor = TListedActors<ARedSpaceTether>().GetSingle();
	}

	UFUNCTION()
	void Activate()
	{
		if (HasControl())
			NetActivate(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION(NetFunction)
	void NetActivate(float TimeOffset)
	{
		bActive = true;
		MoveTimeOffset = TimeOffset;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartMoving() {}
	UFUNCTION(BlueprintEvent)
	void BP_OnAboutToReachEnd() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// if (SplineActor != nullptr)
		// {
		// 	SplineDist = Math::Wrap(MoveSpeed * Time::PredictedGlobalCrumbTrailTime, 0.0, SplineActor.Spline.SplineLength);

		// 	FVector Loc = SplineActor.Spline.GetWorldLocationAtSplineDistance(SplineDist);
		// 	SetActorLocation(Loc);
		// }

		if (!bActive)
			return;

		float DistToTether = GetDistanceTo(TetherActor);

		if (HasControl())
		{
			if (!Game::Mio.IsPlayerDead()
				&& DistToTether <= 400.0
				&& TetherActor.bTetherEnabled
				&& !bKilledByCutter
				&& (RespawnedAtTime == 0.0 || Time::GetGameTimeSince(RespawnedAtTime) > 2.0))
			{
				bKilledByCutter = true;
				NetCutterKillPlayers();
			}

			if (bKilledByCutter
				&& !Game::Mio.IsPlayerDead()
				&& !Game::Zoe.IsPlayerDead())
			{
				bKilledByCutter = false;
				RespawnedAtTime = Time::GameTimeSeconds;
			}
		}

		float CurTime = Time::PredictedGlobalCrumbTrailTime - MoveTimeOffset;
		float WrappedTime = Math::Wrap(CurTime, 0.0, MoveDuration);

		float Position = Math::Saturate(WrappedTime / MoveDuration);
		FVector Loc = SplineActor.Spline.GetWorldLocationAtSplineFraction(Position);
		SetActorLocation(Loc);

		CachedSplineLocation = Loc;

		// Trigger the start moving and "about to reach end" events so we can play effects
		if (WrappedTime > MoveDuration - 1.0)
		{
			if (bStartedMovingFX)
			{
				bStartedMovingFX = false;
				BP_OnAboutToReachEnd();
			}
		}
		else
		{
			if (!bStartedMovingFX)
			{
				bStartedMovingFX = true;
				BP_OnStartMoving();
			}
		}
	}

	UFUNCTION(BlueprintPure)
	float GetSplinePositionAlpha()
	{
		if(SplineActor == nullptr)
			return 0.0;
		
		return SplineActor.Spline.GetClosestSplineDistanceToWorldLocation(CachedSplineLocation) / SplineActor.Spline.SplineLength;
	}

	UFUNCTION(NetFunction)
	void NetCutterKillPlayers()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FVector DeathDir = (Player.ActorCenterLocation - Player.OtherPlayer.ActorCenterLocation).GetSafeNormal();
			Player.KillPlayer(FPlayerDeathDamageParams(DeathDir, 2.0));
		}

		OnPlayersKilled.Broadcast();
	}
}