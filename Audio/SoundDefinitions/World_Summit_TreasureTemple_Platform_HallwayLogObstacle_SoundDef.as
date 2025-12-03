
UCLASS(Abstract)
class UWorld_Summit_TreasureTemple_Platform_HallwayLogObstacle_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> Obstacles;

	TArray<FAkSoundPosition> LogSoundPositions;
	default LogSoundPositions.SetNum(2);		

	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEmitter AddMaterialEmitter;

	UPROPERTY(BlueprintReadOnly)
	bool bIsMetal = false;

	private int AddMaterialIndex = -1;
	private bool bAddMaterialDestroyed = false;

	UPROPERTY(BlueprintReadWrite)
	float AttenuationScaling = 10000;

	private bool WasAddMaterialDestroyed()
	{
		ASummitRollingMetalLog MetalLog = Cast<ASummitRollingMetalLog>(Obstacles[AddMaterialIndex]);
		if(MetalLog != nullptr)
		{
			return MetalLog.bMelted;
		}
		else
		{
			ASummitRollingGemLog GemLog = Cast<ASummitRollingGemLog>(Obstacles[AddMaterialIndex]);
			return GemLog.bCrystalDestroyed;
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnAddMaterialObstacleDestroyed() {};

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		for(auto Obstacle : Obstacles)
		{
			if(Obstacle != nullptr && !Obstacle.IsActorDisabled() && !Obstacle.IsActorBeingDestroyed())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(int i = 0; i <= Obstacles.Num(); ++i)
		{
			ASummitRollingGoldenLog GoldLog = Cast<ASummitRollingGoldenLog>(Obstacles[i]);
			if(GoldLog == nullptr)
			{
				AddMaterialIndex = i;

				bIsMetal = Cast<ASummitRollingMetalLog>(Obstacles[i]) != nullptr;

				FName AddMaterialEmitterName = NAME_None;
				#if TEST
					AddMaterialEmitterName = FName(f"SummitRollingLogObstacle_{bIsMetal ? 'Metal' : 'Crystal'}_Emitter");
				#endif

				FHazeAudioEmitterAttachmentParams Params;
				Params.Attachment = Obstacles[i].RootComponent;
				Params.Owner = this;		
				Params.Instigator = this;
				Params.EmitterName = AddMaterialEmitterName;

				AddMaterialEmitter = Audio::GetPooledEmitter(Params);
				AddMaterialEmitter.SetAttenuationScaling(AttenuationScaling);
				break;				
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector LogStartPos;		
		FVector LogEndPos;

		for(int i = 0; i < Obstacles.Num(); ++i)
		{
			if(Obstacles[i] != nullptr && !Obstacles[i].IsActorDisabled())
			{
				LogStartPos = Obstacles[i].ActorLocation;
				break;
			}
		}

		for(int i = Obstacles.Num() - 1; i >= 0; --i)
		{
			if(Obstacles[i] != nullptr && !Obstacles[i].IsActorDisabled())
			{
				LogEndPos = Obstacles[i].ActorLocation;
				break;
			}
		}

		LogStartPos.X -= 100;		
		LogEndPos.X += 100;

		for(auto Player : Game::GetPlayers())
		{
			FVector ClosestLogPos = Math::ClosestPointOnLine(LogStartPos, LogEndPos, Player.ActorLocation);
			LogSoundPositions[int(Player.Player)] = FAkSoundPosition(ClosestLogPos);
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(LogSoundPositions);

		// Check if add material has been destroyed
		if(!bAddMaterialDestroyed && WasAddMaterialDestroyed())
		{
			bAddMaterialDestroyed = true;
			OnAddMaterialObstacleDestroyed();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Audio::ReturnPooledEmitter(this, AddMaterialEmitter);
	}
}
