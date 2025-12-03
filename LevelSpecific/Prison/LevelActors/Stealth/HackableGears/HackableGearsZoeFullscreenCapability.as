/**
 * While Mio hacks and Zoe is in the ZoeTrigger:
 * - Make Zoes view Fullscreen
 * - Show tutorial prompt for Mio on Zoes screen
 */
class UHackableGearsZoeFullscreenCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AHackableGearsManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AHackableGearsManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Manager.HackableWaterGear.HijackTargetableComp.IsHijacked())
			return false;

		if(!Manager.bSideScrollerActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Manager.HackableWaterGear.HijackTargetableComp.IsHijacked())
			return true;

		if(!Manager.bSideScrollerActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal, EHazeViewPointPriority::High);
		Manager.AddTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::Zoe.ClearViewSizeOverride(this);
		Game::Zoe.RemoveTutorialPromptByInstigator(Manager);
	}
};