
UCLASS(Abstract)
class USolarFlare_Shared_Event_Sun_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSunTelegraph(FOnSolarFlareSunTelegraph Params){}

	UFUNCTION(BlueprintEvent)
	void OnSunTimingsChanged(FOnSolarFlareSunTimingsChangedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnPhaseChanged(FOnSolarFlareSunPhaseChangedParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION()
	void OnSunExplosion(FOnSolarFlareSunExplosion Params)
	{
		CurrentDonut = Sun.CurrentFireDonut;

		TArray<FAkSoundPosition> TempPos;
		TempPos.Add(FAkSoundPosition(Sun.ActorLocation));
		SolarFlareWaveMultiEmitter.AudioComponent.SetMultipleSoundPositions(TempPos);

		OnExplosion(Params);
	}

	UFUNCTION(BlueprintEvent)
	void OnExplosion(FOnSolarFlareSunExplosion Params){};

	ASolarFlareSun Sun;
	ASolarFlareFireDonutActor CurrentDonut;

	UPROPERTY(BlueprintReadOnly, DisplayName = "Emitter - Solar Flare Wave Multi", Category = "Emitters")
	UHazeAudioEmitter SolarFlareWaveMultiEmitter;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Sun = Cast<ASolarFlareSun>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(CurrentDonut != nullptr)
		{			
			TArray<FAkSoundPosition> SoundPositions;

			for(auto Player : Game::GetPlayers())
			{
				SoundPositions.Add(FAkSoundPosition(CurrentDonut.GetKillLocation(Player)));

				//Debug::DrawDebugPoint(CurrentDonut.GetKillLocation(Player), 50.f, FLinearColor::LucBlue, bRenderInForground = true);

				if(SceneView::IsFullScreen())
					break;
			}	

			SolarFlareWaveMultiEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions, AkMultiPositionType::MultiDirections);
		}
	}

}