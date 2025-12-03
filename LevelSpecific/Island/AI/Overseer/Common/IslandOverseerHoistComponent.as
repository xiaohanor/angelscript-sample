class UIslandOverseerHoistComponent : UActorComponent
{
	bool bHoisted;
	bool bHoistUp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UIslandOverseerPhaseComponent::GetOrCreate(Owner).OnPhaseChange.AddUFunction(this, n"PhaseChange");
	}

	UFUNCTION()
	private void PhaseChange(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase)
	{
		if(NewPhase != EIslandOverseerPhase::PovCombat)
			return;
			
		HoistUp();
	}

	void Hoist()
	{
		bHoisted = true;
	}

	void HoistUp()
	{
		bHoisted = true;
		bHoistUp = true;
	}

	void Drop()
	{
		bHoisted = false;
		bHoistUp = false;
	}
}