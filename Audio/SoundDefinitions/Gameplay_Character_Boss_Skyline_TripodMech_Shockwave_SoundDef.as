
UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_TripodMech_Shockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Shockwave.Scale * 100.0 > (Shockwave.Radius * 0.85);
	}

	ASkylineBossTankMortarBallShockWave Shockwave;

	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ShockwaveDistanceCurve;
	default ShockwaveDistanceCurve.AddDefaultKey(0.0, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(0.1, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(0.25, 0.0);
	default ShockwaveDistanceCurve.AddDefaultKey(1.0, 0.0);
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Shockwave = Cast<ASkylineBossTankMortarBallShockWave>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{
			const FVector PlayerPos = Player.ActorLocation;
			const FVector ShockwaveProjectedPlayerPos = Shockwave.ActorTransform.InverseTransformPosition(PlayerPos);
			const FVector ShockwaveEdgeProjectedPlayerPos = ShockwaveProjectedPlayerPos.GetSafeNormal() * (Shockwave.Scale * 100);
			const FVector ShockwaveClosestPlayerWorldPos = Shockwave.ActorTransform.TransformPosition(ShockwaveEdgeProjectedPlayerPos);

			ShockwaveSoundPositions[int(Player.Player)].SetPosition(ShockwaveClosestPlayerWorldPos);	
		}

		DefaultEmitter.SetMultiplePositions(ShockwaveSoundPositions);
	}	
}