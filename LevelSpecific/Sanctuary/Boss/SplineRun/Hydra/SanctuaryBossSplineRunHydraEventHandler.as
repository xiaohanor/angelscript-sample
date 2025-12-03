UCLASS(Abstract)
class USanctuaryBossSplineRunHydraEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void AnimateStart_Idle()
	{
		DevPrintStringEvent("Hydra", "Idle", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void AnimateStart_GhostBall()
	{
		DevPrintStringEvent("Hydra", "GhostBall", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void AnimateStart_Wave()
	{
		DevPrintStringEvent("Hydra", "Wave", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void AnimateStart_Dive()
	{
		DevPrintStringEvent("Hydra", "Dive", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void AnimateStart_ReactToPlayersEngagedCrossbow()
	{
		DevPrintStringEvent("Hydra", "ReactToPlayersEngagedCrossbow", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void AnimateStart_HitByArrow()
	{
		DevPrintStringEvent("Hydra", "HitByArrow", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void SpawnedGhostBall()
	{
		DevPrintStringEvent("Hydra", "SpawnedGhostBall", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void FriendGotHit()
	{
		DevPrintStringEvent("Hydra", "FriendGotHit", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Start_GlowThroat()
	{
		DevPrintStringEvent("Hydra", "Start_GlowThroat", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Stop_GlowThroat()
	{
		DevPrintStringEvent("Hydra", "Stop_GlowThroat", 2.0, ColorDebug::Cornflower, 1.5);
	}
};