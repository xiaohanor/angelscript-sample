
UCLASS(Abstract)
class UGameplay_Character_Boss_Tundra_IceKing_TundraBossWhirlwind_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnWhirlwindStopped(){}

	UFUNCTION(BlueprintEvent)
	void OnWhirlwindStarted(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter PassbysMultiEmitter;
	private TArray<FAkSoundPosition> SmallWhirlwindSoundPositions;

	ATundraBossWhirlwindActor Whirlwind;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Whirlwind = Cast<ATundraBossWhirlwindActor>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SmallWhirlwindSoundPositions.SetNum(Whirlwind.SmallWhirlwinds.Num());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{		
		for(int i = 0; i < SmallWhirlwindSoundPositions.Num(); ++i)
		{
			auto SmallWhirlwind = Whirlwind.SmallWhirlwinds[i];
			if(SmallWhirlwind.bShouldDamagePlayer)
				SmallWhirlwindSoundPositions[i].SetPosition(SmallWhirlwind.ActorLocation);
			else if(SmallWhirlwind.HitPlayerTimeStamp > 0.0) // Despawns immediately when it has hit player, keep lerping position away for a while to avoid ugly volume dip
			{
				float DeactivationTimeAlpha = Math::Saturate((Time::GetGameTimeSeconds() - SmallWhirlwind.HitPlayerTimeStamp) / 2);
				SmallWhirlwindSoundPositions[i].SetPosition(Math::Lerp(SmallWhirlwind.ActorLocation, SmallWhirlwind.ActorLocation + (SmallWhirlwind.ActorForwardVector * (2000)), DeactivationTimeAlpha));
			}
			else // Has been despawned fully, just reset to origo
				SmallWhirlwindSoundPositions[i].SetPosition(FVector());
		}

		PassbysMultiEmitter.SetMultiplePositions(SmallWhirlwindSoundPositions, AkMultiPositionType::MultiSources);
	}
}