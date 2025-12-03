UCLASS(Abstract)
class ASkylineBossFocusBeamHit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent TrailComp;

	/**
	 * How long the spline points should damage the player.
	 * Should basically match when the VFX starts fading away.
	 */
	UPROPERTY(EditDefaultsOnly)
	float DamageLifetime = 3;

	/**
	 * How long to wait after we are deactivating before we destroy ourselves.
	 */
	UPROPERTY(EditDefaultsOnly)
	float DestroyDelay = 5;

	UPROPERTY(EditDefaultsOnly)
	float Damage = 0.4;

	UPROPERTY(EditDefaultsOnly)
	float DamageRadius = 400;

	UPROPERTY(EditDefaultsOnly)
	float DamageInterval = 1;

	TPerPlayer<float> LastDamageTime;
	default LastDamageTime[0] = -1; 
	default LastDamageTime[1] = -1; 

	FHazeRuntimeSpline Spline;
	TArray<float> SplinePointTimes;
	float DeactivateTime = -1;

	/**
	 * Audio
	 */

	private int BeamPoolIndex = -1;

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(EndPlayReason == EEndPlayReason::Destroyed)
		{
			if(BeamPoolIndex >= 0)
			{
				SkylineBossFocusBeam::GetManager().RemoveFromPool(BeamPoolIndex);
				BeamPoolIndex = -1;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(int i = 0; i < SplinePointTimes.Num(); i++)
		{
			if(Time::GetGameTimeSince(SplinePointTimes[0]) > DamageLifetime)
			{
				Spline.RemovePoint(i);
				SplinePointTimes.RemoveAt(i);
				if(i > 0)
					SkylineBossFocusBeam::GetManager().RemoveFromPool(BeamPoolIndex);				
				i--;
			}
			else
			{
				break;
			}
		}

		if(Spline.Points.IsEmpty())
		{
			if(DeactivateTime > 0 && Time::GetGameTimeSince(DeactivateTime) > DestroyDelay)
				DestroyActor();

			return;
		}

		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if(!Player.HasControl())
				continue;

			if(!ShouldDamage(Player))
				continue;

			DealDamage(Player);
		}

#if EDITOR
		//DebugDraw();
#endif
	}

	void AddImpactPoint()
	{
		if (Spline.Points.Num() > 1 && ActorLocation.Distance(Spline.GetLocation(1.0)) < DamageRadius)
			return;

		Spline.AddPointWithUpDirection(ActorLocation, ActorUpVector);
		SplinePointTimes.Add(Time::GameTimeSeconds);

		BeamPoolIndex = SkylineBossFocusBeam::GetManager().AddLocationToPool(ActorLocation);
	}

	void Deactivate()
	{
		DeactivateTime = Time::GameTimeSeconds;
		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() {}

	private bool ShouldDamage(AHazePlayerCharacter Player) const
	{
		if(LastDamageTime[Player] > 0 && Time::GetGameTimeSince(LastDamageTime[Player]) < DamageInterval)
			return false;

		const FVector CenterLocation = Player.ActorCenterLocation;
		FVector ClosestPoint = Spline.GetClosestLocationToLocation(CenterLocation);
		return (ClosestPoint.Distance(CenterLocation) < DamageRadius);
	}

	private void DealDamage(AHazePlayerCharacter Player)
	{
		auto Boss = TListedActors<ASkylineBoss>().Single;
		FPlayerDeathDamageParams Params;
		Params.ImpactDirection = -GravityBikeFree::GetGravityBike(Player).ActorVelocity.SafeNormal;	
		Player.DamagePlayerHealth(Damage, DamageEffect = Boss.DeathDamageComp.FireSoftDamageEffect, DeathEffect = Boss.DeathDamageComp.FireSoftDeathEffect, DeathParams = Params);

		LastDamageTime[Player] = Time::GameTimeSeconds;
	}

#if EDITOR
	private void DebugDraw()
	{
		Spline.DrawDebugSpline();

		if(Spline.Points.IsEmpty())
		{
			Debug::DrawDebugSphere(ActorLocation, DamageRadius, LineColor = FLinearColor::Red);
		}
		else
		{
			for(const FVector& Point : Spline.Points)
			{
				Debug::DrawDebugSphere(Point, DamageRadius, LineColor = FLinearColor::Red);
			}
		}
	}
#endif
};