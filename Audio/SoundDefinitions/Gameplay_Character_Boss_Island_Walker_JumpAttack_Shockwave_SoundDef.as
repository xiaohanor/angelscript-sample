
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_JumpAttack_Shockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnJumpAttackLanded(FIslandWalkerJumpAttackLandedEventData Data){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter ShockwaveMultiEmitter;
	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ShockwaveDistanceCurve;
	default ShockwaveDistanceCurve.AddDefaultKey(0.0, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(0.1, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(1.0, 0.0);

	AAIIslandWalker Walker;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Walker = Cast<AAIIslandWalker>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"ShockwaveMultiEmitter")
			bUseAttach = false;

		TargetActor = HazeOwner;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Walker.WalkerComp.LastAttack == EISlandWalkerAttackType::Jump;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Walker.WalkerComp.LastAttack != EISlandWalkerAttackType::Jump;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto Shockwave = Walker.WalkerComp.ShockWave;
		if(Shockwave != nullptr)
		{
			for(auto Player : Game::GetPlayers())
			{
				const FVector PlayerPos = Player.ActorLocation;
				const FVector ShockwaveProjectedPlayerPos = Shockwave.ActorTransform.InverseTransformPositionNoScale(PlayerPos);
				const FVector ShockwaveEdgeProjectedPlayerPos = ShockwaveProjectedPlayerPos.GetSafeNormal() * Shockwave.Radius;
				const FVector ShockwaveClosestPlayerWorldPos = Shockwave.ActorTransform.TransformPositionNoScale(ShockwaveEdgeProjectedPlayerPos);

				ShockwaveSoundPositions[int(Player.Player)].SetPosition(ShockwaveClosestPlayerWorldPos);
			}

			ShockwaveMultiEmitter.SetMultiplePositions(ShockwaveSoundPositions);
		}
	}
}