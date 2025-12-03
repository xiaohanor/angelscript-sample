class UIslandWalkerHeadHatchRoot : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	TArray<UPerchPointComponent> Perches;
	TArray<UIslandWalkerHeadHatchInteractionComponent> HatchInteractComps;

	FRotator BaseRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BaseRot = RelativeRotation;		

		Owner.GetComponentsByClass(Perches);
		DisablePerches();

		Owner.GetComponentsByClass(HatchInteractComps);
		DisableInteracts();
	}

	UFUNCTION(DevFunction)
	void EnablePerches()
	{
		for (UPerchPointComponent Perch : Perches)
		{
			Perch.Enable(this);
		}
	}

	UFUNCTION(DevFunction)
	void DisablePerches()
	{
		for (UPerchPointComponent Perch : Perches)
		{
			Perch.Disable(this);
		}
	}

	UFUNCTION(DevFunction)
	void EnableInteracts()
	{
		for (UIslandWalkerHeadHatchInteractionComponent Comp : HatchInteractComps)
		{
			Comp.Enable(this);
		}
	}

	UFUNCTION(DevFunction)
	void DisableInteracts()
	{
		for (UIslandWalkerHeadHatchInteractionComponent Comp : HatchInteractComps)
		{
			Comp.Disable(this);
		}
	}
}

