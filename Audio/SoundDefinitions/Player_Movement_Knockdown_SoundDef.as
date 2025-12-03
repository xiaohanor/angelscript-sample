
UCLASS(Abstract)
class UPlayer_Movement_Knockdown_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPlayerAudioMaterialComponent MaterialAudioComponent; 
	UPlayerKnockdownComponent KnockdownComp;

	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEvent KnockdownFallEvent;

	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEvent KnockdownLandEvent;

	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEvent KnockdownStandupEvent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		KnockdownComp = UPlayerKnockdownComponent::Get(PlayerOwner);
		MaterialAudioComponent = UPlayerAudioMaterialComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Get armswing events for player variant
		UPlayerVariantComponent VariantComp = UPlayerVariantComponent::Get(PlayerOwner);
		FHazeArmswingAudioEvents ArmswingEvents = VariantComp.GetPlayerVariantArmswingEvents(PlayerOwner);
		KnockdownFallEvent = ArmswingEvents.RollHighIntEvent;
		KnockdownStandupEvent = ArmswingEvents.CrouchToStandEvent;

		// Get landing impact material event
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(PlayerOwner);
		FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(PlayerOwner);
		UPhysicalMaterial PhysMat = AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.ConvertToHitResult(), TraceSettings);
		if(PhysMat != nullptr)
		{
			const FName MaterialTag = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset).FootstepData.FootstepTag;
			MaterialAudioComponent.GetMaterialEvent(MaterialTag, n"Land_BothLegs_HighInt", EFootType::Left, EFootType::Left, KnockdownLandEvent);
		}
	}	

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerOwner.IsPlayerDead())
			return true;

		if(KnockdownComp.AnimData.bStandUp == true)
			return true;

		if(KnockdownComp.IsPlayerKnockedDown() == false)
			return true;

		return false;
	}
}