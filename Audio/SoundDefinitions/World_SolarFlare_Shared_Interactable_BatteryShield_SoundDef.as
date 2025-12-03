
UCLASS(Abstract)
class UWorld_SolarFlare_Shared_Interactable_BatteryShield_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, Category = "Battery Perches")
	float BatteryPerchAttenuationLength = 4000;

	UPROPERTY(Category = "Battery Indicators")
	float BatteryIndicatorsAttenuationLength = 4000;

	UPROPERTY(Category = "Battery Indicators")
	UHazeAudioEmitter BatteryIndicatorsActivatedMultiEmitter;

	ASolarFlareBatteryShield BatteryShield;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BatteryShield = Cast<ASolarFlareBatteryShield>(HazeOwner);	
		SetBatteryMultiplePositions();
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetScriptImplementedTriggerEffectEvents(
												 UHazeEffectEventHandlerComponent& EventHandlerComponent,
												 TMap<FName,TSubclassOf<UHazeEffectEventHandler>>& EventClassAndFunctionNames) const
	{
		EventHandlerComponent = UHazeEffectEventHandlerComponent::Get(HazeOwner);
		EventClassAndFunctionNames.Add(n"ShieldOn", USolarFlareBatteryShieldEffectHandler);
		EventClassAndFunctionNames.Add(n"ShieldImpact", USolarFlareBatteryShieldEffectHandler);
		return true;
	}

	UFUNCTION(BlueprintEvent)
	void OnBatteryPerchActivated(FVector BatteryLocation, FVector IndicatorLocation) {}
	UFUNCTION()
	void BatteryOn(FSolarFlareBatteryPerchEffectHandlerParams Params)
	{
		SetBatteryMultiplePositions();
		OnBatteryPerchActivated(Params.Location, Params.IndicatorLocation);
	}

	UFUNCTION(BlueprintEvent)
	void OnBatteryPerchDeactivated(FVector BatteryLocation, FVector IndicatorLocation) {}
	UFUNCTION()
	void BatteryOff(FSolarFlareBatteryPerchEffectHandlerParams Params)
	{
		SetBatteryMultiplePositions();
		OnBatteryPerchDeactivated(Params.Location, Params.IndicatorLocation);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Shield Activated")
	void ShieldOn(FSolarFlareBatteryShieldEffectHandlerParams Params) {}

	UFUNCTION(BlueprintEvent, DisplayName = "Shield Break")
	void ShieldImpact(FSolarFlareBatteryShieldEffectHandlerParams Params) {}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Number of Active Batteries"))
	int GetNumActiveBatteries()
	{
		int Count = 0;
		for(auto& Battery : BatteryShield.BatteryPerchs)
		{
			if(Battery.bIsOn)
				++Count;
		}

		return Count;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Was First Battery Activation"))
	bool WasFirstBatteryActivated()
	{
		int ActivationCount = 0;
		for(auto& Battery : BatteryShield.BatteryPerchs)
		{
			if(Battery.bIsOn)
			{
				++ActivationCount;
				if(ActivationCount > 1)
					return false;
			}
		}

		return ActivationCount == 1;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Any Batteries Active"))
	bool IsAnyBatteriesActive()
	{
		for(auto& Battery : BatteryShield.BatteryPerchs)
		{
			if(Battery.bIsOn)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Time to Flare Impact"))
	float GetTimeToSolarFlareImpact()
	{
		auto Sun = TListedActors<ASolarFlareSun>().GetSingle();
		float WaveTelegraphTime = 0.0;

		// If no donut, or current one has already passed players, add some padding to our prediction time to account for the fact that it has to recharge for a new flare
		if(Sun.CurrentFireDonut == nullptr || (Sun.CurrentFireDonut.bCheckedPlayerCanKill[Game::Mio] && Sun.CurrentFireDonut.bCheckedPlayerCanKill[Game::Zoe]))
			WaveTelegraphTime = SolarFlareSun::GetTimeToWaveImpact() + 1.5;

		float DeltaSeconds = Time::GetActorDeltaSeconds(HazeOwner);
		const float TimeToPlayers = SolarFlareSun::GetSecondsTillHit(DeltaSeconds);

		float TimeToSubtract = 0;
		if(Sun.CurrentFireDonut != nullptr)
		{
			// Subtract slightly from the time since it's going to hit the shield before the players
			const float Speed = (Sun.CurrentFireDonut.DonutScale * Sun.CurrentFireDonut.RadiusAmountPerUnit) / Sun.CurrentFireDonut.ScaleSpeed * DeltaSeconds;
			const float AvgDistToPlayers = (HazeOwner.ActorLocation - ((Game::Mio.ActorLocation - Game::Zoe.ActorLocation) / 2)).Size();
			TimeToSubtract = Speed / AvgDistToPlayers;
		}

		return (WaveTelegraphTime + TimeToPlayers) - TimeToSubtract;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(DefaultEmitter.IsPlaying())
		{
			UPrimitiveComponent ShieldCollider = Cast<UPrimitiveComponent>(DefaultEmitter.AudioComponent.AttachParent);
			TArray<FAkSoundPosition> ShieldSoundPositions;

			for(auto Player : Game::Players)
			{
				FVector ClosestPlayerPos;
				ShieldCollider.GetClosestPointOnCollision(Player.ActorCenterLocation, ClosestPlayerPos);

				ShieldSoundPositions.Add(FAkSoundPosition(ClosestPlayerPos));
			}

			DefaultEmitter.AudioComponent.SetMultipleSoundPositions(ShieldSoundPositions);
		}
	}

	private void SetBatteryMultiplePositions()
	{	
		TArray<FAkSoundPosition> ActivatedIndicatorSoundPositions;

		for(auto& BatteryPerch : BatteryShield.BatteryPerchs)
		{
			if(BatteryPerch.bIsOn)
			{	
				ActivatedIndicatorSoundPositions.Add(FAkSoundPosition(BatteryPerch.Indicator.ActorLocation));
			}		
		}

		if(ActivatedIndicatorSoundPositions.Num() == 0)
			ActivatedIndicatorSoundPositions.Add(FAkSoundPosition(DefaultEmitter.AudioComponent.GetWorldLocation()));

		BatteryIndicatorsActivatedMultiEmitter.AudioComponent.SetMultipleSoundPositions(ActivatedIndicatorSoundPositions);
	}
}