class UAdultDragonAcidShootTutorialCapability : UTutorialCapability
{
	// UAdultDragonAcidChargeProjectileComponent ChargeComp;
	// bool bDeactivate;

	// bool bCanRelease;

	// UFUNCTION(BlueprintOverride)
	// void Setup()
	// {
	// 	TListedActors<AAdultDragonAcidTutorialVolume> TutorialVolumes;
	// 	TutorialVolumes[0].Metal.OnHitByAcid.AddUFunction(this, n"OnMetalShieldHitByAcid");
	// }

	// UFUNCTION(BlueprintOverride)
	// void PreTick(float DeltaTime)
	// {
	// 	if (ChargeComp == nullptr)
	// 	{
	// 		ChargeComp = UAdultDragonAcidChargeProjectileComponent::Get(Player);
			
	// 		if (ChargeComp != nullptr)
	// 			ChargeComp.OnAcidProjectileReady.AddUFunction(this, n"OnAcidProjectileReady");	
	// 	}
	// }

	// UFUNCTION()
	// private void OnMetalShieldHitByAcid()
	// {
	// 	bDeactivate = true;
	// }

	// // UFUNCTION()
	// // private void OnStormSiegeMetalDestroyed(AStormSiegeMetalFortification DestroyedMetal)
	// // {
	// // 	bDeactivate = true;
	// // }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if (bDeactivate)
	// 		return false;

	// 	return Super::ShouldActivate();
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if (bDeactivate)
	// 		return true;

	// 	return Super::ShouldDeactivate();
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnActivated()
	// {
	// 	FTutorialPrompt HoldFire;
	// 	HoldFire.DisplayType = ETutorialPromptDisplay::ActionHold;
	// 	HoldFire.Action = ActionNames::PrimaryLevelAbility;
	// 	HoldFire.Text = NSLOCTEXT("AdultDragonTutorial", "ShootAcidHold", "HOLD");

	// 	Player.ShowTutorialPrompt(HoldFire, this);
	// }

	// UFUNCTION(BlueprintOverride)
	// void OnDeactivated()
	// {
	// 	Player.RemoveTutorialPromptByInstigator(this);
	// 	bCanRelease = false;
	// }

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	if (WasActionStopped(ActionNames::PrimaryLevelAbility) && bCanRelease)
	// 		bDeactivate = true;
	// }

	// UFUNCTION()
	// private void OnAcidProjectileReady()
	// {
	// 	if (bDeactivate)
	// 		return;
		
	// 	Player.RemoveTutorialPromptByInstigator(this);
	// 	FTutorialPrompt FirePrompt;
	// 	FirePrompt.DisplayType = ETutorialPromptDisplay::Action;
	// 	FirePrompt.Action = ActionNames::PrimaryLevelAbility;
	// 	FirePrompt.Text = NSLOCTEXT("AdultDragonTutorial", "ShootAcidFire", "FIRE");

	// 	Player.ShowTutorialPrompt(FirePrompt, this);	

	// 	bCanRelease = true;
	// }
}