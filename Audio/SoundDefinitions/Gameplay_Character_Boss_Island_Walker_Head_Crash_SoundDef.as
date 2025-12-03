
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Head_Crash_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartCrashing(){}

	UFUNCTION(BlueprintEvent)
	void OnCrashLanding(){}

	UFUNCTION(BlueprintEvent)
	void OnStartRecoveringFromCrash(){}

	UFUNCTION(BlueprintEvent)
	void OnStartedFlying(){}

	UFUNCTION(BlueprintEvent)
	void OnHeadShockwave(){}

	/* END OF AUTO-GENERATED CODE */

	AIslandWalkerHead Head;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter ShockwaveMultiEmitter;
	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ShockwaveDistanceCurve;
	default ShockwaveDistanceCurve.AddDefaultKey(0.0, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(0.1, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(1.0, 0.0);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Head = Cast<AIslandWalkerHead>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return (Head.HeadComp.State == EIslandWalkerHeadState::Detached || Head.HeadComp.State == EIslandWalkerHeadState::Swimming);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto& Shockwave : Head.HeadComp.ShockWaves)
		{
			if(!Shockwave.Effect.IsActive())
				continue;

			for(auto Player : Game::GetPlayers())
			{
				const FVector PlayerPos = Player.ActorLocation;
				FVector ShockwaveProjectedPlayerPos = Shockwave.ActorTransform.InverseTransformPositionNoScale(PlayerPos);
				ShockwaveProjectedPlayerPos.Z = 0.0;
				const FVector ShockwaveEdgeProjectedPlayerPos = ShockwaveProjectedPlayerPos.GetSafeNormal() * Shockwave.Radius;
				const FVector ShockwaveClosestPlayerWorldPos = Shockwave.ActorTransform.TransformPositionNoScale(ShockwaveEdgeProjectedPlayerPos);

				ShockwaveSoundPositions[int(Player.Player)].SetPosition(ShockwaveClosestPlayerWorldPos);
			}

			ShockwaveMultiEmitter.SetMultiplePositions(ShockwaveSoundPositions);
		}
	}
}