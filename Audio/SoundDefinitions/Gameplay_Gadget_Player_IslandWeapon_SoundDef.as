
UCLASS(Abstract)
class UGameplay_Gadget_Player_IslandWeapon_SoundDef : USoundDefBase
{

	private UIslandRedBlueOverheatAssaultUserComponent OverheatUserComponent; 
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		OverheatUserComponent = UIslandRedBlueOverheatAssaultUserComponent::GetOrCreate(Cast<AIslandRedBlueWeapon> (HazeOwner).PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//ProxyEmitterSoundDef::LinkToActor(this, Cast<AIslandRedBlueWeapon>(HazeOwner).PlayerOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetOverheatAlpha() const property
	{
		if (OverheatUserComponent == nullptr)
			return 0;

		return OverheatUserComponent.OverheatAlpha;
	}

	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnReloadFinished(){}

	UFUNCTION(BlueprintEvent)
	void OnReloadStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnWeaponAttachToThigh(){}

	UFUNCTION(BlueprintEvent)
	void OnWeaponAttachToHand(){}

	/* END OF AUTO-GENERATED CODE */

}