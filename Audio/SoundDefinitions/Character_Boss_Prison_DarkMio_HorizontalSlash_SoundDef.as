
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_HorizontalSlash_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void HorizontalSlashAttackSpawned(){}

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss DarkMio;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter WavesMultiEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMio.CurrentAttackType == EPrisonBossAttackType::HorizontalSlash;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DarkMio.CurrentAttackType != EPrisonBossAttackType::HorizontalSlash;
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = DarkMio;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		TArray<APrisonBossHorizontalSlashActor> Waves = TListedActors<APrisonBossHorizontalSlashActor>().GetArray();
		const int WaveCount = Waves.Num();
		if(WaveCount == 0)
			return;

		TArray<FAkSoundPosition> WavesSoundPositions;
		WavesSoundPositions.SetNum(WaveCount);

		const FVector ZoeLocation = Game::GetZoe().ActorLocation;

		for(int i = 0; i < WaveCount; ++i)
		{		
			APrisonBossHorizontalSlashActor Wave = Waves[i];
			const FVector WaveMiddle = Wave.SlashRoot.WorldLocation;
			FVector WaveLineBegin = WaveMiddle;
			WaveLineBegin.Y -= 2000;
			FVector WaveLineEnd = WaveMiddle;
			WaveLineEnd.Y += 2000;
			
			const FVector ClosestPlayerPosition = Math::ClosestPointOnLine(WaveLineBegin, WaveLineEnd, ZoeLocation);
			WavesSoundPositions[i].SetPosition(ClosestPlayerPosition);			
		}

		WavesMultiEmitter.SetMultiplePositions(WavesSoundPositions);
	}
}