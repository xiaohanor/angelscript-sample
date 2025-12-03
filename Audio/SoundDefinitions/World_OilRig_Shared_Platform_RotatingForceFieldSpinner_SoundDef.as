
UCLASS(Abstract)
class UWorld_OilRig_Shared_Platform_RotatingForceFieldSpinner_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AOilRigForceFieldSpinner Spinner;

	UPROPERTY(VisibleAnywhere)
	UHazeAudioEmitter CloseEmitter;

	TArray<FAkSoundPosition> SoundPositions;
	default SoundPositions.SetNum(4);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{		
		Spinner = Cast<AOilRigForceFieldSpinner>(HazeOwner);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		int PosIndex = 0;		
		for(auto Player : Game::GetPlayers())
		{
			FVector ClosestPos1;
			auto Distance1 = Spinner.AudioPlane1.GetClosestPointOnCollision(Player.ActorLocation, ClosestPos1);
			if(Distance1 < 0)
				ClosestPos1 = Spinner.GetActorLocation();

			FVector ClosestPos2;
			auto Distance2 = Spinner.AudioPlane2.GetClosestPointOnCollision(Player.ActorLocation, ClosestPos2);
			if(Distance2 < 0)
				ClosestPos2 = Spinner.GetActorLocation();

			SoundPositions[PosIndex].SetPosition(ClosestPos1);
			SoundPositions[PosIndex + 1].SetPosition(ClosestPos2);
			PosIndex += 2;
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(SoundPositions);
	}

}