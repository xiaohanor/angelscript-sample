UCLASS(Abstract)
class USanctuaryBossArenaHydraHeadEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_Idle()
	{
		DevPrintStringEvent("Hydra", "Name", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_RainAttack()
	{
		DevPrintStringEvent("Hydra", "RainAttack", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_WaveAttack()
	{
		DevPrintStringEvent("Hydra", "WaveAttack", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_ProjectileAttack()
	{
		DevPrintStringEvent("Hydra", "ProjectileAttack", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_Submerge()
	{
		DevPrintStringEvent("Hydra", "Submerge", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_Emerge()
	{
		DevPrintStringEvent("Hydra", "Emerge", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_StrangleAttacked()
	{
		DevPrintStringEvent("Hydra", "StrangleAttacked", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_StrangleFreed()
	{
		DevPrintStringEvent("Hydra", "StrangleFreed", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_FriendIsAttacked()
	{
		DevPrintStringEvent("Hydra", "FriendIsAttacked", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void Animation_Death()
	{
		DevPrintStringEvent("Hydra", "Death", 2.0, ColorDebug::Cornflower, 1.5);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode, NoSuperCall))
	void CrunchPlatform()
	{
		DevPrintStringEvent("Hydra", "CrunchPlatform", 2.0, ColorDebug::Cornflower, 1.5);
	}
};