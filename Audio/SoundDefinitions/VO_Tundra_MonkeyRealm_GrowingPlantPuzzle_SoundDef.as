
UCLASS(Abstract)
class UVO_Tundra_MonkeyRealm_GrowingPlantPuzzle_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TundraRangedLifeGivingActor_OnLifeGivingStopped(){}

	UFUNCTION(BlueprintEvent)
	void TundraRangedLifeGivingActor_OnLifeGivingStarted(){}

	UFUNCTION(BlueprintEvent)
	void TundraRangedLifeGivingActor_OnEnterInteract(FTundraRangedLifeGivingActorOnStartInteractEffectParams TundraRangedLifeGivingActorOnStartInteractEffectParams){}

	UFUNCTION(BlueprintEvent)
	void TundraRangedLifeGivingActor_OnStopLookingAt(){}

	UFUNCTION(BlueprintEvent)
	void TundraRangedLifeGivingActor_OnStartLookingAt(){}

	UFUNCTION(BlueprintEvent)
	void TundraLifeReceiving_OnStopMovingVerticalInput(){}

	UFUNCTION(BlueprintEvent)
	void TundraLifeReceiving_OnStartMovingVerticalInput(){}

	UFUNCTION(BlueprintEvent)
	void TundraLifeReceiving_OnStopMovingHorizontalInput(){}

	UFUNCTION(BlueprintEvent)
	void TundraLifeReceiving_OnStartMovingHorizontalInput(){}

	UFUNCTION(BlueprintEvent)
	void TundraLifeReceiving_OnStopLifeGiving(FTundraLifeReceivingEffectParams TundraLifeReceivingEffectParams){}

	UFUNCTION(BlueprintEvent)
	void TundraLifeReceiving_OnStartLifeGiving(FTundraLifeReceivingEffectParams TundraLifeReceivingEffectParams){}

	UFUNCTION(BlueprintEvent)
	void TundraRiver_SplineGrowingFlower__OnStopMoving(){}

	UFUNCTION(BlueprintEvent)
	void TundraRiver_SplineGrowingFlower__OnStartMoving(){}

	/* END OF AUTO-GENERATED CODE */

	ATundraRiver_SplineGrowingFlower GrowingFlower;
        UFUNCTION(BlueprintOverride)
    void ParentSetup()
    {
    }

	UFUNCTION()
	void SetGrowingFlower(ATundraRiver_SplineGrowingFlower inGrowingFlower)
	{
		GrowingFlower = inGrowingFlower;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentAlpha()
	{
		if (GrowingFlower == nullptr)
			return 0;
		
		return GrowingFlower.CurrentAlpha;
	}
	
	UFUNCTION(BlueprintPure)
	float GetLowestAlpha()
	{
		if (GrowingFlower == nullptr)
			return 0;

		return GrowingFlower.LowestSplineDistance / GrowingFlower.SplineLength;
	}
	UFUNCTION(BlueprintPure)
	bool IsAtTheBottom()
	{
		return (GetCurrentAlpha()-0.001) <= GetLowestAlpha();
	}
}