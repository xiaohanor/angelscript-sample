
UCLASS(Abstract)
class UWorld_Prison_Maintenance_Platform_JumpPad_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "Emitters")
	UHazeAudioEmitter TripodEmitter;

	UPROPERTY(EditInstanceOnly)
	TArray<UStaticMeshComponent> MultiPositionMeshes;

	TArray<FAkSoundPosition> MeshMultiPositions;	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		int NumMultiPositions = 0;

		for(auto MeshComp : MultiPositionMeshes)
		{
			if(MeshComp != nullptr)
				++NumMultiPositions;
		}

		MeshMultiPositions.SetNum(NumMultiPositions);		
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"TripodEmitter")
		{
			bUseAttach = false;
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(MeshMultiPositions.Num() != 0)
		{
			const int NumPositions = MeshMultiPositions.Num();

			for(int i = 0; i < NumPositions; ++i)
			{
				MeshMultiPositions[i].SetPosition(MultiPositionMeshes[i].WorldLocation);
			} 

			TripodEmitter.AudioComponent.SetMultipleSoundPositions(MeshMultiPositions);
		}
	}
}