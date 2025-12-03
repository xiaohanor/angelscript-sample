
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_ChargeLaser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineBallBossChargeLaser ChargeLaser;
	UButtonMashComponent ButtonMashComp;
	float PreviousButtonMashProgress = 0.0;

	UFUNCTION(BlueprintEvent)
	void OnTornOff() {}

	float GetButtonMashProgress() const property
	{
		return ButtonMashComp.GetButtonMashProgress(n"SkylineBallBossChargeLaserButtonMashExtrudePlayerCapability");
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ChargeLaser = Cast<ASkylineBallBossChargeLaser>(HazeOwner);
		ButtonMashComp = UButtonMashComponent::Get(Game::GetMio());
		ChargeLaser.OnTornOff.AddUFunction(this, n"OnTornOff");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return ChargeLaser.bMioIsInteracting;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !ChargeLaser.bMioIsInteracting;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Button Mash Progress"))
	float GetCurrentButtonMashProgress()
	{
		return ButtonMashProgress;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Button Mash Delta"))
	float GetButtonMashDelta()
	{
		const float CurrProgress = ButtonMashProgress;
		const float Delta = CurrProgress - PreviousButtonMashProgress;
		PreviousButtonMashProgress = CurrProgress;

		return Delta;
	}
}