
UCLASS(Abstract)
class UCharacter_Boss_MeltdownBoss_PhaseThreeIceKing_ClawAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnKnockDown(){}

	UFUNCTION(BlueprintEvent)
	void OnSpawned(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownPhaseThreeIceKingClawAttack ClawAttack;

	UPROPERTY()
	UHazeAudioEmitter ClawAttackMultiEmitter;
	private TArray<FAkSoundPosition> ClawAttackSoundPositions;
	default ClawAttackSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
    void ParentSetup()
    {
        ClawAttack = Cast<AMeltdownPhaseThreeIceKingClawAttack>(HazeOwner);
    }

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"ClawAttackMultiEmitter")
			bUseAttach = false;

		TargetActor = HazeOwner;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ClawAttack != nullptr)
		{
			auto Players = Game::Players;
			TArray<float> ClosestPlayerPositions;
			ClosestPlayerPositions.SetNum(2);
			ClosestPlayerPositions[0] = MAX_flt;
			ClosestPlayerPositions[1] = MAX_flt;

			for(int i = 0; i < ClawAttack.MeshRoots.Num(); i++)
			{
				FVector NewLocation = ClawAttack.MeshRoots[i].WorldLocation;

				for (int j=0; j < 2; ++j)
				{
					auto SqrDistance = Players[j].ActorLocation.DistSquared(NewLocation);

					if (SqrDistance < ClosestPlayerPositions[j])
					{
						ClawAttackSoundPositions[j].SetPosition(NewLocation);

						ClosestPlayerPositions[j]=SqrDistance;

						//Debug::DrawDebugPoint(NewLocation, 50, FLinearColor::Black, 0, true);
					}
				}
			}

			ClawAttackMultiEmitter.SetMultiplePositions(ClawAttackSoundPositions);

		}
	}

}