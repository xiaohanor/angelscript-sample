
UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_Spot_Smoke_Lasers_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLaserClusterChange(FMaxSecurityLaserClusterChangeParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	AHazePlayerCharacter Player;

	UPROPERTY()
	ARemoteHackableSmokeRobot SmokeRobot;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Player = Drone::GetSwarmDronePlayer();
		SmokeRobot = Cast<ARemoteHackableSmokeRobot>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (int i=0; i < Emitters.Num(); ++i)
		{
			switch(i)
			{
				case 0:
				OnActivatedLeft(Emitters[i]);
				break;
				case 1:
				OnActivatedRight(Emitters[i]);
				break;
				case 2:
				OnActivatedBackLeft(Emitters[i]);
				break;
				case 3:
				OnActivatedBackRight(Emitters[i]);
				break;
				default:
				break;
			}
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivatedLeft(UHazeAudioEmitter Emitter) { }
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivatedRight(UHazeAudioEmitter Emitter) { }
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivatedBackLeft(UHazeAudioEmitter Emitter) { }
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivatedBackRight(UHazeAudioEmitter Emitter) { }

	// Left, Right, LeftBack, RightBack.
	UFUNCTION(BlueprintPure)
	UHazeAudioEmitter EmitterByID(int32 ClusterID)
	{
		if (!Emitters.IsValidIndex(ClusterID))
			return nullptr;

		return Emitters[ClusterID];
	}

	#if TEST
	TArray<FLinearColor> EmitterColors;
	default EmitterColors.Add(FLinearColor::Green);
	default EmitterColors.Add(FLinearColor::Red);
	default EmitterColors.Add(FLinearColor::Purple);
	default EmitterColors.Add(FLinearColor::Black);
	#endif

	UFUNCTION(Meta = (DevelopmentOnly))
	void PrintChanges(int32 ClusterID, int32 Count)
	{
		#if TEST
		auto Emitter = EmitterByID(ClusterID);
		if (Emitter == nullptr)
			return;

		auto Color = EmitterColors[ClusterID];
		PrintToScreenGraph(Emitter.Name, Count, Color, Duration = 10, Min = 0, Max = 100);
		#endif
	}
}