class UIslandWalkerThrusterAssembly : UActorComponent
{
	TArray<UIslandWalkerHeadThruster> Thrusters;

	FIslandRedBlueImpactResponseSignature OnBulletImpact;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Owner.GetComponentsByClass(Thrusters);
		for (UIslandWalkerHeadThruster Thruster : Thrusters)
		{
			Thruster.GetChildComponentByClass(UIslandWalkerHeadThrusterImpactResponseComponent).OnImpactEvent.AddUFunction(this, n"OnHitByBullet");
		}
	}

	UFUNCTION()
	private void OnHitByBullet(FIslandRedBlueImpactResponseParams Data)
	{
		OnBulletImpact.Broadcast(Data);
	}

	void SetVulnerable()
	{
		for (UIslandWalkerHeadThruster Thruster : Thrusters)
		{
			if (Thruster.bIgnited)
				Thruster.SetVulnerable();
		}
	}

	void SetInvulnerable()
	{
		for (UIslandWalkerHeadThruster Thruster : Thrusters)
		{
			Thruster.SetInvulnerable();
		}
	}

	void ExtinguishThrusterAt(FVector Location)
	{
		float ClosestDistSqr = BIG_NUMBER;
		UIslandWalkerHeadThruster ClosestThruster = nullptr;
		for (UIslandWalkerHeadThruster Thruster : Thrusters)
		{
			if (!Thruster.bIgnited)
				continue;
			float DistSqr = Thruster.WorldLocation.DistSquared(Location);
			if (DistSqr > ClosestDistSqr)
				continue;
			ClosestDistSqr = DistSqr;
			ClosestThruster = Thruster;
		}

		if (ClosestThruster != nullptr)
			ClosestThruster.Extinguish();
	}

	void IgniteThrusters()
	{
		for (UIslandWalkerHeadThruster Thruster : Thrusters)
		{
			Thruster.Ignite();
		}
	}
}
