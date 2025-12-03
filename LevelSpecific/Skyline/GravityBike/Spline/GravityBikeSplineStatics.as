namespace GravityBikeSpline
{
	AHazePlayerCharacter GetDriverPlayer()
	{
		return Game::Mio;
	}

	AHazePlayerCharacter GetPassengerPlayer()
	{
		return Game::Zoe;
	}

	UGravityBikeSplineManager GetManager()
	{
		return UGravityBikeSplineManager::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintPure)
	AGravityBikeSpline GetGravityBike()
	{
		auto DriverComp = UGravityBikeSplineDriverComponent::Get(GravityBikeSpline::GetDriverPlayer());
		if(DriverComp.GravityBike != nullptr)
			return DriverComp.GravityBike;
		
		return DriverComp.SpawnGravityBike();
	}

	/**
	 * To simplify the setup process, we use our own function for teleport to respawn point.
	 * If this is called after the gravity bike has been initialized, we will snap to the new spline.
	 */
	UFUNCTION(BlueprintCallable)
	void TeleportGravityBikeToRespawnPoint(ARespawnPoint RespawnPoint, AGravityBikeSplineActor Spline, FInstigator Instigator, bool bIncludeCamera = true)
	{
		check(RespawnPoint != nullptr);
		check(Spline != nullptr);

		Game::Mio.TeleportToRespawnPoint(RespawnPoint, Instigator, bIncludeCamera);

		GetManager().InitialSpline = Spline;
		auto GravityBike = GetGravityBike();

		GravityBike.SnapToTransform(FTransform(Game::Mio.ActorQuat, Game::Mio.ActorLocation), EGravityBikeSplineSnapToTransformVelocityMode::MaxSpeed);
		
		if(GravityBike.GetActiveSplineActor() != nullptr)
		{
			// If GravityBike already has a spline, that means that it has initialized
			// Snap to the new spline
			GravityBike.SetSpline(Spline, true);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetInitialSpline(AGravityBikeSplineActor InitialSpline)
	{
		check(InitialSpline != nullptr);
		GetManager().InitialSpline = InitialSpline;
	}

	AGravityBikeSplineActor GetGravityBikeSpline()
	{
		auto GravityBike = GetGravityBike();
		if(GravityBike != nullptr && GravityBike.GetActiveSplineActor() != nullptr)
			return GravityBike.GetActiveSplineActor();

		devError("No spline!");
		return nullptr;
	}

	FTransform GetGravityBikeSplineTransform()
	{
		return GetGravityBike().GetSplineTransform();
	}

	FTransform GetGravityBikeSplineTransform(AGravityBikeSplineActor Spline)
	{
		return Spline.SplineComp.GetClosestSplineWorldTransformToWorldLocation(GetGravityBike().ActorLocation);
	}

	FVector GetGlobalUp()
	{
		return GetGravityBike().GetGlobalWorldUp();
	}

	float GetGravityBikeDistanceAlongSpline()
	{
		return GetGravityBikeSpline().SplineComp.GetClosestSplineDistanceToWorldLocation(GetGravityBike().ActorLocation);
	}

	float GetGravityBikeDistanceAlongSpline(AGravityBikeSplineActor Spline)
	{
		return Spline.SplineComp.GetClosestSplineDistanceToWorldLocation(GetGravityBike().ActorLocation);
	}

	UFUNCTION(BlueprintCallable)
	AGravityBikeSplineActor GetClosestGravityBikeSplineActor(FVector Location, FTransform&out OutClosestTransform)
	{
		TListedActors<AGravityBikeSplineActor> Splines;
		if(Splines.Num() == 0)
			return nullptr;

		AGravityBikeSplineActor ClosestSpline = Splines[0];
		FTransform SplineClosestLocation = ClosestSpline.SplineComp.GetClosestSplineWorldTransformToWorldLocation(Location);
		float ClosestDistance = Location.DistSquared(SplineClosestLocation.Location);
		OutClosestTransform = SplineClosestLocation;

		for(int i = 1; i < Splines.Num(); i++)
		{
			SplineClosestLocation = Splines[i].SplineComp.GetClosestSplineWorldTransformToWorldLocation(Location);
			float Distance = Location.DistSquared(SplineClosestLocation.Location);
			if(Distance < ClosestDistance)
			{
				ClosestSpline = Splines[i];
				ClosestDistance = Distance;
				OutClosestTransform = SplineClosestLocation;
			}
		}

		return ClosestSpline;
	}

	bool TryDamagePlayerHitResult(FHitResult HitResult, float PlayerDamage)
	{
		return TryDamagePlayerThroughActor(HitResult.Actor, PlayerDamage);
	}

	bool TryDamagePlayerThroughActor(AActor Actor, float PlayerDamage)
	{
		auto GravityBike = Cast<AGravityBikeSpline>(Actor);
		if(GravityBike != nullptr)
			return DamagePlayer(PlayerDamage);
		
		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player != nullptr)
			return DamagePlayer(PlayerDamage);

		return false;
	}

	bool DamagePlayer(float PlayerDamage)
	{
		GetDriverPlayer().DamagePlayerHealth(PlayerDamage);

		for (auto It : Game::Players)
		{
			It.PlayForceFeedback(GravityBikeSpline::GetGravityBike().ForceFeedbackEffect, false, false, GravityBikeSpline::GetGravityBike());
		}
		
		return true;
	}

	float GetGravityBikeHealth()
	{
		auto HealthComp = UPlayerHealthComponent::Get(Game::Mio);
		return HealthComp.Health.CurrentHealth;
	}
}

class UGravityBikeSplineManager : UActorComponent
{
	AGravityBikeSplineActor InitialSpline;
};