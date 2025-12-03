
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_ChargeLaser_Core_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void MioBladeHit(){}

	/* END OF AUTO-GENERATED CODE */

	ASkylineBallBoss BallBoss;
	bool bMioIsInside = false;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve DistanceCurve; 

	UFUNCTION(BlueprintEvent)
	void OnCoreExposed() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BallBoss = TListedActors<ASkylineBallBoss>().GetSingle();
		BallBoss.OnPhaseChanged.AddUFunction(this, n"OnBallBossPhaseChanged");
	}

	UFUNCTION()
	void OnBallBossPhaseChanged(ESkylineBallBossPhase NewPhase)
	{
		if(NewPhase == ESkylineBallBossPhase::TopMioIn)
			bMioIsInside = true;
		else
			bMioIsInside = false;		

		if(ActivationState == ESoundDefActivationState::Active && NewPhase == ESkylineBallBossPhase::TopMioInKillWeakpoint)
			OnCoreExposed();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return bMioIsInside;
	}
}