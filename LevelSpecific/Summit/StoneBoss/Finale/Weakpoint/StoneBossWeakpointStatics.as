namespace StoneBossWeakpoint
{
	UFUNCTION()
	void ClearStoneBeastCrystalVeinsEffect()
	{
		auto Weakpoint = TListedActors<AStoneBossWeakpoint>().GetSingle();
		if (Weakpoint != nullptr)
			Weakpoint.ClearVeinEffect();
	}
}