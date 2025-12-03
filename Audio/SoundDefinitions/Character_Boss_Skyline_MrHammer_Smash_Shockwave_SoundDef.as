
UCLASS(Abstract)
class UCharacter_Boss_Skyline_MrHammer_Smash_Shockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnShockwaveStop(){}

	/* END OF AUTO-GENERATED CODE */

	ASkylineTorSmashShockwave Shockwave;
	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UFUNCTION(BlueprintEvent)
	void OnMusicBeat() {}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Shockwave = Cast<ASkylineTorSmashShockwave>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Music::Get().OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Music::Get().OnMainMusicBeat().UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{
			const FVector PlayerLocation = Player.ActorLocation;
			FVector ShockwaveProjectedPlayerPos = Shockwave.ActorTransform.InverseTransformPosition(PlayerLocation);
			FVector ClosestPlayerShockwavePos = ShockwaveProjectedPlayerPos.GetSafeNormal() * Shockwave.GetCurrentRadius();
			FVector PlayerShockwaveWorldPos = Shockwave.ActorTransform.TransformPosition(ClosestPlayerShockwavePos);

			ShockwaveSoundPositions[int(Player.Player)].SetPosition(PlayerShockwaveWorldPos);
		}

		DefaultEmitter.SetMultiplePositions(ShockwaveSoundPositions);
	}
}