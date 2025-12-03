
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_WalkerBoss_Movement_Actions_PipeTumble_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnEndFinalSplineRunToDestruction(){}

	UFUNCTION(BlueprintEvent)
	void OnCancelFinalSplineRunToDestruction(){}

	UFUNCTION(BlueprintEvent)
	void OnStartFinalSplineRunToDestruction(){}

	/* END OF AUTO-GENERATED CODE */

	AIslandWalkerArenaLimits Arena;

	UPROPERTY(BlueprintReadOnly)
	float SplineAlpha;

	UFUNCTION(BlueprintOverride)
    void ParentSetup()
    {
        Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		AIslandWalkerEscapeSpline EscapeSpline = Arena.EscapeOrder[0];

		float HeadDistanceOnSpline = EscapeSpline.Spline.GetClosestSplineDistanceToWorldLocation(HazeOwner.ActorLocation);

		SplineAlpha = HeadDistanceOnSpline / EscapeSpline.Spline.SplineLength;
	}

}