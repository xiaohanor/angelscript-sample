
struct FSkylineSmallBossShootMissilesEventHandlerParams
{
	UPROPERTY()
	FVector TargetLocation;
}

class USkylineSmallBossMiscVOEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioTryHitShieldedSmallBoss() 
	{
		DevPrintStringEvent("SmallBossVO", "MioTryHitShieldedSmallBoss");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioTryHitNakedSpeedySmallBoss() 
	{
		DevPrintStringEvent("SmallBossVO", "MioTryHitNakedSpeedySmallBoss");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioHitSmallBoss() 
	{
		DevPrintStringEvent("SmallBossVO", "MioHitSmallBoss");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZoeWhipBreakOffPlate() 
	{
		DevPrintStringEvent("SmallBossVO", "ZoeWhipBreakOffPlate");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZoeWhipHoldNakedSmallBossStart() 
	{
		DevPrintStringEvent("SmallBossVO", "ZoeWhipHoldNakedSmallBossStart");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZoeWhipHoldNakedSmallBossEnd() 
	{
		DevPrintStringEvent("SmallBossVO", "ZoeWhipHoldNakedSmallBossEnd");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmallBossJump() 
	{
		DevPrintStringEvent("SmallBossVO", "SmallBossJump");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmallBossSmash() 
	{
		DevPrintStringEvent("SmallBossVO", "SmallBossSmash");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SmallBossShootMissile(FSkylineSmallBossShootMissilesEventHandlerParams Params) 
	{
		DevPrintStringEvent("SmallBossVO", "SmallBossShootMissile");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DelayedStartAfterShieldSegmentsAttached() 
	{
		DevPrintStringEvent("SmallBossVO", "SmallBossStart");
	}
};