
UCLASS(Abstract)
class UVO_Skyline_SideContent_WaterSlide_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartSliding(){}

	UFUNCTION(BlueprintEvent)
	void OnStopSliding(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	APlayerLookAtTrigger LookAtTrigger;

	UPROPERTY(EditInstanceOnly)
	APlayerLookAtTrigger LookAtTrigger2;

	UPlayerSlideComponent SlideComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SlideComp = UPlayerSlideComponent::Get(Game::Mio);
	}

	UFUNCTION(BlueprintPure)
	bool IsMioSliding() const
	{
		if (PlayerOwner.IsMio())
			return SlideComp != nullptr && SlideComp.IsSlideActive();

		return false;
	}
}