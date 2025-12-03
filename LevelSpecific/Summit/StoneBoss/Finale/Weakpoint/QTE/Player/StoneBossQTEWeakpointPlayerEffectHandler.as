struct FStoneBeastWeakpointPlayerStabParams
{
	UPROPERTY()
	FVector PlayerStabLocation;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBeastWeakpointPlayerChargeParams
{
	UPROPERTY()
	FVector SwordLocation;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBeastWeakpointPlayerReleaseParams
{
	UPROPERTY()
	FVector SwordLocation;
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBeastWeakpointFirstMashStartedParams
{
	UPROPERTY()
	FVector SwordLocation;
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBeastWeakpointSecondMashStartedParams
{
	UPROPERTY()
	FVector SwordLocation;
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBeastWeakpointFirstMashCompletedParams
{
	UPROPERTY()
	FVector SwordLocation;
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBeastWeakpointSecondMashCompletedParams
{
	UPROPERTY()
	FVector SwordLocation;
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBeastWeakpointSwordRetractParams
{
	UPROPERTY()
	FVector SwordLocation;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS()
class UStoneBossQTEWeakpointPlayerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeakpointStabSuccess(FStoneBeastWeakpointPlayerStabParams StabParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeakpointStabFail(FStoneBeastWeakpointPlayerStabParams StabParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeakpointCharge(FStoneBeastWeakpointPlayerChargeParams ChargeParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeakpointRelease(FStoneBeastWeakpointPlayerReleaseParams ReleaseParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeakpointSwordRetract(FStoneBeastWeakpointSwordRetractParams RetractParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalWeakpointStabSuccess(FStoneBeastWeakpointPlayerStabParams StabParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalWeakpointStabFail(FStoneBeastWeakpointPlayerStabParams StabParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalWeakpointFirstMashStarted(FStoneBeastWeakpointFirstMashStartedParams FirstMashParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalWeakpointFirstMashCompleted(FStoneBeastWeakpointFirstMashCompletedParams FirstMashParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalWeakpointSecondMashStarted(FStoneBeastWeakpointSecondMashStartedParams SecondMashParams)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalWeakpointSecondMashCompleted(FStoneBeastWeakpointSecondMashCompletedParams SecondMashParams)
	{
	}
};