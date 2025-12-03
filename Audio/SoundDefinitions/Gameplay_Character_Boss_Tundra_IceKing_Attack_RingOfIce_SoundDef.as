
UCLASS(Abstract)
class UGameplay_Character_Boss_Tundra_IceKing_Attack_RingOfIce_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void JumpedToNextLocation(){}

	UFUNCTION(BlueprintEvent)
	void RingOfIceAttackStoppedAfterCharge(){}

	UFUNCTION(BlueprintEvent)
	void RingOfIceAttackStartedAfterCharge(){}

	UFUNCTION(BlueprintEvent)
	void RingOfIceAttackStoppedDuringCharge(){}

	UFUNCTION(BlueprintEvent)
	void RingOfIceAttackStartedCharging(){}

	UFUNCTION(BlueprintEvent)
	void RingOfIceAttackStarted(){}

	UFUNCTION(BlueprintEvent)
	void Spawned(FTundraBossIceRingEventData Data){}

	/* END OF AUTO-GENERATED CODE */

	ATundraBossRingOfIceSpikesActor IceRing;

	UPROPERTY()
	UHazeAudioEmitter IceRingMultiEmitter;
	private TArray<FAkSoundPosition> IceRingSoundPositions;
	default IceRingSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
    void ParentSetup()
    {
        IceRing = Cast<ATundraBossRingOfIceSpikesActor>(HazeOwner);
    }

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"IceRingMultiEmitter")
			bUseAttach = false;

		TargetActor = HazeOwner;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(IceRing != nullptr)
		{
			for(auto Player : Game::GetPlayers())
			{
				const FVector PlayerPos = Player.ActorLocation;
				const FVector IceRingProjectedPlayerPos = IceRing.ActorTransform.InverseTransformPositionNoScale(PlayerPos);
				const FVector IceRingEdgeProjectedPlayerPos = IceRingProjectedPlayerPos.GetSafeNormal() * IceRing.Scale * 125;
				const FVector IceRingClosestPlayerWorldPos = IceRing.ActorTransform.TransformPositionNoScale(IceRingEdgeProjectedPlayerPos);

				IceRingSoundPositions[int(Player.Player)].SetPosition(IceRingClosestPlayerWorldPos);

				//Debug::DrawDebugPoint(IceRingClosestPlayerWorldPos, 50, FLinearColor::Black, 0, true);
			}

			IceRingMultiEmitter.SetMultiplePositions(IceRingSoundPositions);

			//Debug::DrawDebugPoint(IceRing.ActorLocation, 50);
		}
	}

}