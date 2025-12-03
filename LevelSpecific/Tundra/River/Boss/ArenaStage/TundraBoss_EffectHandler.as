UCLASS(Abstract)
class UTundraBoss_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeDamageGroundSlam()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeDamageHitByBall()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChestBeltActivating(FTundraBossChestBeltData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChestBeltDeactivating(FTundraBossChestBeltData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChestBeltGrabbed(FTundraBossChestBeltData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMonkeyPunchStarted()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMonkeyPunch()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMonkeyPunchFinal()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClawAttackStarted()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClawAttackRight()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClawAttackLeft()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClawAttackEnded()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreakFreeFromStruggle()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreakFreeAfterDamage()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreakFreeNoDamage()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFloored()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindStart()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindStop(FTudnraBossWhirlwindStopData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawnRedIceAttack(FTundraBossRedIceAttackData Data)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrackingIceCracked()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrackingIceExploded()
	{
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrackingIceFrozen()
	{
	}

	//If the attack is the last one in the queue for this phase, the NextAttack will be "None". If the length of the current attack isn't determined by time (Other factors pushing the queue forward), CurrentAttackDuration will be -1. 
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttack(FTundraBossAttackData Data)
	{
	}
};

struct FTundraBossChargeIceBeamData
{
	UPROPERTY()
	float Duration;

	UPROPERTY()
	USceneComponent ChargeLocation;
}

struct FTundraBossChestBeltData
{
	UPROPERTY()
	USceneComponent Scene;
}

struct FTundraBossAttackData
{
	UPROPERTY()
	ETundraBossStates CurrentAttack;
	UPROPERTY()
	float CurrentAttackDuration;
	UPROPERTY()
	ETundraBossStates NextAttack;
}

struct FTundraBossRedIceAttackData
{
	UPROPERTY()
	FVector Location;

	FTundraBossRedIceAttackData(FVector InLocation)
	{
		Location = InLocation;
	}
}

struct FTudnraBossWhirlwindStopData
{
	UPROPERTY(BlueprintReadOnly)
	bool bShouldPlaySphereHint;
}