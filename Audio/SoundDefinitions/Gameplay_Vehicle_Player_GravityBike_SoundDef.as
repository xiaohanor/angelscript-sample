
UCLASS(Abstract)
class UGameplay_Vehicle_Player_GravityBike_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnThrottleEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnThrottleStart(){}

	UFUNCTION(BlueprintEvent)
	void OnWaterTrailEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnWaterTrailStart(){}

	UFUNCTION(BlueprintEvent)
	void OnWallImpact(FGravityBikeSplineOnWallImpactEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnGroundImpact(FGravityBikeSplineOnGroundImpactEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnBoostEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnBoostStart(){}

	UFUNCTION(BlueprintEvent)
	void OnForwardEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnForwardStart(){}

	UFUNCTION(BlueprintEvent)
	void OnMount(){}

	UFUNCTION(BlueprintEvent)
	void OnLeaveGround(){}

	UFUNCTION(BlueprintEvent)
	void OnGravityChangeStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnExplode(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UAudioReflectionComponent ReflectionComponent;

	AGravityBikeSpline GravityBike;
	UPlayerHealthComponent HealthComponent;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HazeOwner.bIsControlledByCutscene)
			return false;

		if (Game::IsInLoadingScreen())
			return false;
		
		if (IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HazeOwner.bIsControlledByCutscene)
			return true;

		if (Game::IsInLoadingScreen())
			return true;

		if (IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerDead() const
	{
		if (HealthComponent != nullptr)
			return HealthComponent.bIsDead;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		GravityBike = Cast<AGravityBikeSpline>(HazeOwner);
		if (GravityBike != nullptr)
		{
			//DefaultEmitter.AudioComponent.SetRelativeRotation(FRotator(90,0,0));
			
			ReflectionComponent = UAudioReflectionComponent::Get(Game::GetMio());
			if (GravityBike.GetDriver() != nullptr)
			{
				HealthComponent = UPlayerHealthComponent::Get(GravityBike.GetDriver());
				HealthComponent.OnDeathTriggered.AddUFunction(this, n"OnPlayerDeath");
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	private void OnPlayerDeath()
	{
	}

	UFUNCTION(BlueprintPure)
	bool IsThrottling()
	{
		return GravityBike.Input.GetImmediateThrottle() > 0.5;
	}

}