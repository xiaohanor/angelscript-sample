
UCLASS(Abstract)
class UGameplay_Vehicle_Player_GravityBike_Free_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnThrottleEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnThrottleStart(){}

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
	void OnWallImpact(FGravityBikeFreeOnWallImpactEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnLeaveGround(){}

	UFUNCTION(BlueprintEvent)
	void OnGroundImpact(FGravityBikeFreeOnGroundImpactEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnDriftStart(){}

	UFUNCTION(BlueprintEvent)
	void OnDriftEnd(){}

	/* END OF AUTO-GENERATED CODE */

	AGravityBikeFree GravityBike;
	UPlayerHealthComponent HealthComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		/* INSTRUCTIONS FOR TESTING OUT SPLITCHAIN COMPRESSOR! 
		
			* First, uncomment this code. The Splitchain Compressor needs to act independandtly on
			* each listener output, so we set each instance of the player bike to only mix to the player listener
			
			auto GravityBike = Cast<AGravityBikeFree>(HazeOwner);
			DefaultEmitter.SetSinglePlayerListener(GravityBike.Driver);

			* Second, un-bypass the effect on the bus. For testing purposes this currently just sits on 
			* Bus_HDR_Vehicle_Bed, but will obviously live on specific buses in the future. 
			* Feel free to test it on this bus, just don't submit it yet!
			
			Play and look at the meters in the plugin UI!
			All levels are relative to the bus input

			Green = No compression applied
			Yellow = within 6dB of the threshold
			Red = Over threshold, pushing the compressor
			Blue = The other instance is pushing the compressor, this instance will be compressed 		
		*/ 

		GravityBike = Cast<AGravityBikeFree>(HazeOwner);
		if (GravityBike.BikeDriver != nullptr)
		{
			HealthComponent = UPlayerHealthComponent::Get(GravityBike.BikeDriver);
		}
	}

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
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, GravityBike.BikeDriver);
	}

	UFUNCTION(BlueprintPure)
	bool IsThrottling()
	{
		return GravityBike.Input.Throttle > 0.0;
	}
}