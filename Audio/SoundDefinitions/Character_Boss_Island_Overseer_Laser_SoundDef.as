
UCLASS(Abstract)
class UCharacter_Boss_Island_Overseer_Laser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLaserAttackStop(FIslandOverseerLaserAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnLaserAttackStart(FIslandOverseerLaserAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnLaserBombAttackStop(FIslandOverseerLaserAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void OnLaserBombAttackStart(FIslandOverseerLaserAttackData Data){}

	/* END OF AUTO-GENERATED CODE */

	TArray<FAkSoundPosition> LaserPositions;
	default LaserPositions.SetNum(4);

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly)
	UHazeAudioEmitter LaserImpactEmitter;

	UPROPERTY(BlueprintReadWrite)
	TArray<UIslandOverseerLaserAttackEmitter> LaserAttackVFXEmitters;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{		
		if(!LaserAttackVFXEmitters.IsEmpty())
		{
			auto Players = Game::GetPlayers();
			int LaserPositionIndex = 0;

			for(int i = 0; i < Players.Num(); ++i)
			{
				auto Player = Players[i];
				
				for(const UIslandOverseerLaserAttackEmitter LaserVFXEmitter : LaserAttackVFXEmitters)
				{
					const FVector ClosestPlayerPos = Math::ClosestPointOnLine(LaserVFXEmitter.TrailStart, LaserVFXEmitter.TrailEnd, Player.ActorLocation);
					LaserPositions[LaserPositionIndex].SetPosition(ClosestPlayerPos);
					++LaserPositionIndex;
				}
			}

			LaserImpactEmitter.SetMultiplePositions(LaserPositions);
		}
	}
}