
UCLASS(Abstract)
class UGameplay_Character_Creature_Sanctuary_Companion_DarkPortal_Vocalizations_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Recalled(FDarkPortalRecallEventData Params){}

	UFUNCTION(BlueprintEvent)
	void CompanionLaunchStarted(){}

	UFUNCTION(BlueprintEvent)
	void Settled(FDarkPortalSettledEventData Params){}

	/* END OF AUTO-GENERATED CODE */

	UDarkPortalUserComponent DarkPortalUser;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		auto DarkPortal = Cast<AAISanctuaryDarkPortalCompanion>(HazeOwner);
		DarkPortalUser = UDarkPortalUserComponent::Get( DarkPortal.CompanionComp.Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, Game::GetZoe());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DarkPortalUser.bCompanionEnabled)
			return false;

		if (DarkPortalUser.bIsIntroducing)
			return false;

		if(DarkPortalUser.Portal.IsSettled())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DarkPortalUser.bCompanionEnabled)
			return true;

		if (DarkPortalUser.bIsIntroducing)
			return true;

		if(DarkPortalUser.Portal.IsSettled())
			return true;

		return false;
	}

}