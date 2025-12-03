class APirateWaterSwimmingVolume : ASwimmingVolume
{
	UPROPERTY(EditInstanceOnly)
	EHazePlayer Player;

	AHazePlayerCharacter Player_Internal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player_Internal = Game::GetPlayer(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const FVector PlayerLocation = Player_Internal.ActorCenterLocation;
		OceanWaves::RequestWaveData(this, PlayerLocation);
		float WaveHeight = OceanWaves::GetLatestWaveData(this).PointOnWave.Z;
		WaveHeight -= 110;

		float BoxHeight = Math::Min(PlayerLocation.Z, WaveHeight);

		SetActorLocation(FVector(PlayerLocation.X, PlayerLocation.Y, BoxHeight));
	}
};