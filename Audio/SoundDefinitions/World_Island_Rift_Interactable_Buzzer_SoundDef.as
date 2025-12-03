
UCLASS(Abstract)
class UWorld_Island_Rift_Interactable_Buzzer_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStoppedLaser(){}

	UFUNCTION(BlueprintEvent)
	void OnStartedLaser(FIslandBuzzerAimingEventData Data){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	UHazeAudioEmitter LaserEmitter;

	TArray<FAkSoundPosition> LaserSoundPositions;
	default LaserSoundPositions.SetNum(2);

	UPROPERTY(BlueprintReadWrite)
	bool bLaserActive = false;

	UIslandBuzzerLaserAimingComponent LaserAimingComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LaserAimingComp = UIslandBuzzerLaserAimingComponent::Get(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(bLaserActive)
		{
			for(auto Player : Game::GetPlayers())
			{
				const FVector PlayerLaserPos = Math::ClosestPointOnLine(LaserAimingComp.AimingLocation.StartLocation,
																		LaserAimingComp.AimingLocation.EndLocation,
																		Player.ActorLocation);

				LaserSoundPositions[Player.Player].SetPosition(PlayerLaserPos);
			}

			LaserEmitter.AudioComponent.SetMultipleSoundPositions(LaserSoundPositions);
		}
	}

}