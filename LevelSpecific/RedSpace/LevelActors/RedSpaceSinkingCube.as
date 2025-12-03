UCLASS(Abstract)
class ARedSpaceSinkingCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CubeRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	TArray<AHazePlayerCharacter> PlayersOnCube;

	FHazeAcceleratedFloat AccSinkSpeed;
	float SinkSpeedPerPlayer = 400.0;

	float CurrentOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		PlayersOnCube.AddUnique(Player);
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		PlayersOnCube.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayersOnCube.Num() == 0.0)
		{
			if (Math::IsNearlyEqual(CubeRoot.RelativeLocation.Z, 0.0, 5.0))
				AccSinkSpeed.SnapTo(0.0);
			else
				AccSinkSpeed.AccelerateTo(-800.0, 2.0, DeltaTime);
		}
		else
			AccSinkSpeed.AccelerateTo(PlayersOnCube.Num() * SinkSpeedPerPlayer, 2.0, DeltaTime);

		CurrentOffset = Math::Clamp(CurrentOffset - (AccSinkSpeed.Value * DeltaTime), -5000.0, 0.0);
		CubeRoot.SetRelativeLocation(FVector(0.0, 0.0, CurrentOffset));
	}
}