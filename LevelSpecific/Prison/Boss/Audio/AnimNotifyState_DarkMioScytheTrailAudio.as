class UAnimNotifyState_DarkMioScytheTrailAudio : UAnimNotifyState
{	
	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		auto HazeOwner = Cast<AHazeActor>(MeshComp.Owner);
		if(HazeOwner == nullptr)
			return false;

		UPrisonBossEffectEventHandler::Trigger_ScytheTrailActivated(HazeOwner);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto HazeOwner = Cast<AHazeActor>(MeshComp.Owner);
		if(HazeOwner == nullptr)
			return false;

		UPrisonBossEffectEventHandler::Trigger_ScytheTrailDeactivated(HazeOwner);
		return true;
	}
}