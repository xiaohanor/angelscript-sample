
UCLASS(Abstract)
class UCharacter_Boss_Summit_RubyKnight_TorusShockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASummitKnightTorusShockwave Shockwave;
	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Shockwave = Cast<ASummitKnightTorusShockwave>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Shockwave.Effect.IsActive() == true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Shockwave.Effect.IsActive() == false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!Shockwave.bWasStarted)
			return;

		for(auto Player : Game::Players)
		{
			const FVector PlayerPos = Player.ActorLocation;
			FVector PlayerProjectedShockwavePos = Shockwave.ActorTransform.InverseTransformPositionNoScale(PlayerPos);
			PlayerProjectedShockwavePos.Z = 0.0;
			const FVector PlayerProjectedPositionOnShockwave = PlayerProjectedShockwavePos.GetSafeNormal() * (Shockwave.Radius);
			const FVector PlayerClosestShockwaveWorldPos = Shockwave.ActorTransform.TransformPositionNoScale(PlayerProjectedPositionOnShockwave);

			ShockwaveSoundPositions[int(Player.Player)].SetPosition(PlayerClosestShockwaveWorldPos);
		}

		DefaultEmitter.SetMultiplePositions(ShockwaveSoundPositions);
	}
}