
UCLASS(Abstract)
class UPlayer_Movement_Addative_SandFootsteps_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Right(FPlayerFootstepParams FootstepParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Left(FPlayerFootstepParams FootstepParams){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioMaterialReferenceAsset SandMaterialReferenceAsset;

	private UPlayerAudioMaterialComponent PlayerMaterialComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		PlayerMaterialComp = UPlayerAudioMaterialComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintPure)
	bool GetSandFootstepEvent(const FName& InMovementType, const EFootType InFoot, UHazeAudioEvent&out FootstepEvent)
	{
		if(PlayerMaterialComp.GetMaterialEvent(SandMaterialReferenceAsset.MaterialName, InMovementType, InFoot, InFoot, FootstepEvent))
			return FootstepEvent != nullptr;

		return false;		
	}

}