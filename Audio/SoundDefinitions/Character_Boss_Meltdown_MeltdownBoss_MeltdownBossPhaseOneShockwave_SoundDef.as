
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_MeltdownBossPhaseOneShockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBossPhaseOneShockwave Shockwave;
	TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Shockwave = Cast<AMeltdownBossPhaseOneShockwave>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{
			const FVector PlayerPosition = Player.ActorLocation;
			FVector ShockwaveProjectedPlayerPos = Shockwave.ActorTransform.InverseTransformPositionNoScale(PlayerPosition);
			ShockwaveProjectedPlayerPos.Z = 0.0;
			const FVector ClosestPlayerPositionOnShockwaveEdge = ShockwaveProjectedPlayerPos.GetSafeNormal() * Shockwave.DisplacementComp.CircleRadius;
			const FVector PlayerShockwaveWorldPos = Shockwave.ActorTransform.TransformPositionNoScale(ClosestPlayerPositionOnShockwaveEdge);

			ShockwaveSoundPositions[int(Player.Player)].SetPosition(PlayerShockwaveWorldPos);
		}

		DefaultEmitter.SetMultiplePositions(ShockwaveSoundPositions);
	}
}