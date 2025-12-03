class UEvergreenBarrelPlayerComponent : UActorComponent
{
	AEvergreenBarrel CurrentBarrel;
	AEvergreenBarrel BarrelToBlock;
	bool bLaunchMonkey = false;

	void StartEnterBarrel(AEvergreenBarrel Barrel)
	{
		CurrentBarrel = Barrel;
		CurrentBarrel.AnimData.bPlayerInBarrel = true;
	}

	void FullyEnterBarrel()
	{
		devCheck(CurrentBarrel != nullptr, "Tried to fully enter barrel when we haven't started entering it!");
		CurrentBarrel.bMonkeyInBarrel = true;
	}

	void ExitBarrel()
	{
		if(CurrentBarrel == nullptr)
			return;

		CurrentBarrel.AnimData.bPlayerInBarrel = false;
		CurrentBarrel.bMonkeyInBarrel = false;
		CurrentBarrel = nullptr;
	}
}