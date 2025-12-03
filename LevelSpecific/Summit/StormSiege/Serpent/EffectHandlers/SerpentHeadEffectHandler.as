struct FSerpentHeadLightningBeamParams
{
	UPROPERTY()
	FVector Start;

	UPROPERTY()
	FVector End;

	FSerpentHeadLightningBeamParams(FVector NewStart, FVector NewEnd)
	{
		Start = NewStart;
		End = NewEnd;
	}
}

struct FSerpentHeadCrystalBreathParams
{
	UPROPERTY()
	FVector Start;

	UPROPERTY()
	FVector End;

	UPROPERTY()
	FQuat Orientation;

	UPROPERTY()
	FVector ImpactPoint;

	FSerpentHeadCrystalBreathParams(FVector NewStart, FVector NewEnd, FQuat NewOrientation, FVector NewImpactPoint)
	{
		Start = NewStart;
		End = NewEnd;
		Orientation = NewOrientation;
		ImpactPoint = NewImpactPoint;
	}
}

struct FSerpentHeadSplineParams
{
	UPROPERTY(BlueprintReadOnly)
	int SplineIndex = 0;

	FSerpentHeadSplineParams(int InIndex = 0)
	{
		SplineIndex = InIndex;
	}
}

UCLASS(Abstract)
class USerpentHeadEffectHandler : UHazeEffectEventHandler
{
	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void StartLightningBeamTelegraph(FSerpentHeadLightningBeamParams Params)
	// {
	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void StopLightningBeamTelegraph()
	// {
	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void StartLightningBeamAttack(FSerpentHeadLightningBeamParams Params) {}
	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void StopLightningBeamAttack() {}


	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCrystalBreath(FSerpentHeadCrystalBreathParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartShooting(FSerpentHeadCrystalBreathParams Params){}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateCrystalBreath(FSerpentHeadCrystalBreathParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreathHitRock(FSerpentHeadCrystalBreathParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreathHitWaterfall(FSerpentHeadCrystalBreathParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopCrystalBreath() {}

	UFUNCTION(BlueprintEvent)
	void OnTransitionToNewSpline(FSerpentHeadSplineParams Params) {};
};