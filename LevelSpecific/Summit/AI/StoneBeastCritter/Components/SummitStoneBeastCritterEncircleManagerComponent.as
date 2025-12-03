enum ESummitStoneBeastCritterEncircleRole
{
	Near,
	Middle,
	Far,
	None
}

// Add to each player.
class USummitStoneBeastCritterEncircleManagerComponent : UActorComponent
{
	private TArray<AAISummitStoneBeastCritter> EncirclingCritters;

	private const int MaxNumNear = 6;
	private const int MaxNumMiddle = 12;

	private	bool bIsInitialized = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Init();
	}

	void Init()
	{
		if (bIsInitialized)
			return;
		bIsInitialized = true;

		EncirclingCritters.Reserve(30);
	}

	ESummitStoneBeastCritterEncircleRole GetOrAssignRole(AAISummitStoneBeastCritter Critter)
	{
		// Assign a new role
		if (EncirclingCritters.AddUnique(Critter))
			return GetRoleByIndex(EncirclingCritters.Num() - 1);
		
		// If already has a role, return it
		int Index = EncirclingCritters.FindIndex(Critter);
		ESummitStoneBeastCritterEncircleRole Role = GetRoleByIndex(Index);
		return Role;
	}

	void TryRemoveRole(AAISummitStoneBeastCritter Critter)
	{
		EncirclingCritters.Remove(Critter);
	}

	ESummitStoneBeastCritterEncircleRole GetRoleByIndex(int Index)
	{
		if (Index >= 0 && EncirclingCritters.IsValidIndex(Index))
		{
			if (Index < MaxNumNear)
				return ESummitStoneBeastCritterEncircleRole::Near;
			if (Index < MaxNumNear + MaxNumMiddle)
				return ESummitStoneBeastCritterEncircleRole::Middle;
			
			return ESummitStoneBeastCritterEncircleRole::Far;
		}		

		return ESummitStoneBeastCritterEncircleRole::None;
	}
	
}