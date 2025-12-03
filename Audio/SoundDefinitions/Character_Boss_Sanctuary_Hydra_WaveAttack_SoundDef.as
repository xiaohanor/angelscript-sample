
UCLASS(Abstract)
class UCharacter_Boss_Sanctuary_Hydra_WaveAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartWaveAttack(){}

	UFUNCTION(BlueprintEvent)
	void OnWaveAttackPlayerLaunch(FMedallionHydraPlayerData NewData){}

	UFUNCTION(BlueprintEvent)
	void OnWaveAttackPlatformLaunch(FMedallionHydraWaveAttackPlatformData NewData){}

	/* END OF AUTO-GENERATED CODE */

	AMedallionHydraWaveAttack WaveAttack;
	private TArray<FAkSoundPosition> WaveSoundPositions;
	default WaveSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		WaveAttack = Cast<AMedallionHydraWaveAttack>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!WaveAttack.bWaveActive)
		{
			DefaultEmitter.SetEmitterLocation(Math::Lerp(WaveAttack.Hydra1.ActorLocation, WaveAttack.Hydra2.ActorLocation, 0.5), true);
			return;
		}

		for(auto Player : Game::Players)
		{
			const FVector PlayerPos = Player.ActorLocation;
			FVector PlayerProjectedWavePos = WaveAttack.WaveMeshComp.WorldTransform.InverseTransformPositionNoScale(PlayerPos);
			PlayerProjectedWavePos.Z = 0;
			const FVector PlayerClosestPosOnWave = PlayerProjectedWavePos.GetSafeNormal() * (WaveAttack.XYScale * 440.0);
			const FVector PlayerWaveWorldPos = WaveAttack.WaveMeshComp.WorldTransform.TransformPositionNoScale(PlayerClosestPosOnWave);
			
			WaveSoundPositions[int(Player.Player)].SetPosition(PlayerWaveWorldPos);
		}

		DefaultEmitter.SetMultiplePositions(WaveSoundPositions);
	}

}