
UCLASS(Abstract)
class UCharacter_Boss_Summit_RubyKnight_SpinningSlashShockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASummitKnightSpinningSlashShockwave Shockwave;
	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Shockwave = Cast<ASummitKnightSpinningSlashShockwave>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			const FVector PlayerPos = Player.ActorLocation;
			FVector PlayerProjectedShockwavePos = Shockwave.ActorTransform.InverseTransformPosition(PlayerPos);
			PlayerProjectedShockwavePos.Z = 0.0;
			
			const FVector PlayerProjectedPositionOnShockwave = PlayerProjectedShockwavePos.GetSafeNormal() * Shockwave.Radius;	
			const FVector PlayerClosestShockwaveWorldPos = Shockwave.ActorTransform.TransformPosition(PlayerProjectedPositionOnShockwave);

			ShockwaveSoundPositions[int(Player.Player)].SetPosition(PlayerClosestShockwaveWorldPos);
		}

		DefaultEmitter.SetMultiplePositions(ShockwaveSoundPositions);
	}

}