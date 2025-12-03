
event void FBasicAIOnUnspawn();
event void FBasicAIOnEnabled(AHazeActor Actor);
event void FBasicAIOnDisabled(AHazeActor Actor);

class UBasicBehaviourComponent : UActorComponent
{
	// Triggers when we won't be entering play again and can be respawned
	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIOnUnspawn OnUnspawn;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIOnEnabled OnEnabled;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIOnDisabled OnDisabled;

	// Default settings applied when spawning
	UPROPERTY(Category = "Behaviour")
	UBasicAISettings DefaultSettings = nullptr;

	// Name of team we join when spawning
	UPROPERTY(Category = "Behaviour")
	FName TeamName = AITeams::Default;

	// Class of team we join when spawning, if any
	UPROPERTY(Category = "Behaviour")
	TSubclassOf<UHazeTeam> TeamClass = UHazeTeam;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
	UBasicAISettings Settings;

	UPROPERTY(BlueprintReadOnly, NotVisible, Transient)
    UHazeTeam Team = nullptr;

    AHazeActor HazeOwner = nullptr;

	UBasicAIHealthComponent HealthComp;

	TArray<FBasicBehaviourClaimedRequirements> ClaimedRequirements;
	
	TArray<UObject> ActiveBehaviours;
	float InactiveBehaviourTime = BIG_NUMBER;

	int WantedGentlemanScore = 0; // DEPRECATED
	bool bHasTelegraphedAttack = false;
	int RegisteredBehaviours = 0;

	bool bIsSpawned = true;

	float LastEnabledTime;
	
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		HazeOwner = Cast<AHazeActor>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		if (TeamClass.IsValid())  
        	Team = HazeOwner.JoinTeam(TeamName, TeamClass);
		else 
			Team = HazeOwner.JoinTeam(TeamName);

	 	bIsSpawned = true;

		// Set up default settings
		Settings = UBasicAISettings::GetSettings(HazeOwner);
		if (DefaultSettings != nullptr)
			HazeOwner.ApplyDefaultSettings(DefaultSettings);

		LastEnabledTime = Time::GameTimeSeconds;
#if TEST
		DevMenu::RequestTransientDevMenu(n"AI","?", UAIDevMenu);
#endif
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		if (bIsSpawned)
			OnUnspawn.Broadcast();
		bIsSpawned = false;
        HazeOwner.LeaveTeam(TeamName);
    }

	void ClaimRequirements(int32 RequirementsFlags, int Priority, FInstigator Instigator)
	{
		FBasicBehaviourClaimedRequirements NewRequirements;
		NewRequirements.Priority = Priority;
		NewRequirements.Instigator = Instigator;
		NewRequirements.RequirementsFlags = RequirementsFlags;

	 	ReleaseRequirements(Instigator);

		// Insert sorted
		int i = ClaimedRequirements.Num() - 1;
		for (; i >= 0; i--)
		{
			if (ClaimedRequirements[i].Priority >= Priority)
				break;
		}
		ClaimedRequirements.Insert(NewRequirements, i + 1);
	}

	void ReleaseRequirements(FInstigator Instigator)
	{
		for (int i = ClaimedRequirements.Num() - 1; i >= 0; i--)
		{
			if (ClaimedRequirements[i].Instigator == Instigator)
			{
				ClaimedRequirements.RemoveAt(i);
				break; // Only one slot per instigator
			}
		}
	}

	void ClaimSingleRequirement(EBasicBehaviourRequirement Requirement, int Priority, FInstigator Instigator)
	{
		int RequirementFlag = (1 << uint(Requirement));
		for (FBasicBehaviourClaimedRequirements& ClaimedRequirement : ClaimedRequirements)
		{
			if (ClaimedRequirement.Instigator == Instigator) 
			{
				// We should never have more than one claim per instigator, so priority should match!
				check(ClaimedRequirement.Priority == Priority);
				ClaimedRequirement.RequirementsFlags |= RequirementFlag;
				return;				
			}
		}		
		// No matching already claimed requirements, make a new claim
		ClaimRequirements(RequirementFlag, Priority, Instigator);
	}

	void ReleaseSingleRequirement(EBasicBehaviourRequirement Requirement, FInstigator Instigator)
	{
		int RequirementFlag = (1 << uint(Requirement));
		for (int i = ClaimedRequirements.Num() - 1; i >= 0; i--)
		{
			if (ClaimedRequirements[i].Instigator == Instigator) 
			{
				if (ClaimedRequirements[i].RequirementsFlags == RequirementFlag)
					ClaimedRequirements.RemoveAt(i);
				else
					ClaimedRequirements[i].RequirementsFlags = ClaimedRequirements[i].RequirementsFlags & ~RequirementFlag;
				break; // Only one claim per instigator
			}
		}
	}

	bool HasClaimedRequirement(EBasicBehaviourRequirement Requirement, FInstigator Instigator) const
	{
		int RequirementFlag = (1 << uint(Requirement));
		for (FBasicBehaviourClaimedRequirements Claims : ClaimedRequirements)
		{
			if (Claims.Instigator != Instigator)
				continue;
			if ((Claims.RequirementsFlags & RequirementFlag) != 0)
				return true;
		}
		return false;
	}

	bool CanClaimRequirement(EBasicBehaviourRequirement Requirement, int Priority, FInstigator Instigator) const
	{
		return CanClaimRequirements((1 << uint(Requirement)), Priority, Instigator);
	}

	bool CanClaimRequirements(int32 RequirementsFlags, int Priority, FInstigator Instigator) const
	{
		if (RequirementsFlags == 0)
			return true; // No requirements

		// Claimed requirements are sorted in descending prio order
		for (FBasicBehaviourClaimedRequirements ClaimedReqs : ClaimedRequirements)
		{
			if (ClaimedReqs.Instigator == Instigator)
				return true; // We can keep claim
			if (ClaimedReqs.Priority < Priority)
				return true; // We got prio
			if ((ClaimedReqs.RequirementsFlags & RequirementsFlags) != 0)
				return false; // Something higher prio or with same but earlier claim has snatched what we need
		}
		// Nothing claiming what we need, we can claim!
		return true;
	}

	bool IsRequirementClaimed(EBasicBehaviourRequirement Requirement) const
	{
		int32 RequirementFlag = (1 << uint(Requirement)); 
		if (RequirementFlag == 0)
			return false; // No requirements
		for (FBasicBehaviourClaimedRequirements ClaimedReqs : ClaimedRequirements)
		{
			if ((ClaimedReqs.RequirementsFlags & RequirementFlag) != 0)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		// TODO: Find a better place for this than here. Quite convenient though, since all AIs have this component...
		// Currently this is bound (in BasicAIUpdateCapability) to trigger respawnable comp UnSpawn.
 		if ((HealthComp != nullptr) && HealthComp.IsDead())
			Unspawn();
		else 
			Log("AI " + Owner.Name + " was disabled without being dead! Note that this will not count towards spawn depletion etc. Time since enable: " + Time::GetGameTimeSince(LastEnabledTime));

		// End all behaviour when disabled
        HazeOwner.BlockCapabilities(BasicAITags::Behaviour, this);
        HazeOwner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);

		OnDisabled.Broadcast(HazeOwner);
	}

	void Unspawn()
	{
		if (!bIsSpawned)
			return;
		OnUnspawn.Broadcast();
		bIsSpawned = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
        HazeOwner.UnblockCapabilities(BasicAITags::Behaviour, this);
		HazeOwner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		bIsSpawned = true;
		OnEnabled.Broadcast(HazeOwner);
		LastEnabledTime = Time::GameTimeSeconds;
	}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		bHasTelegraphedAttack = false;
	}

	void ReportActiveBehaviour(UObject Behaviour)
	{
		ActiveBehaviours.AddUnique(Behaviour);
		InactiveBehaviourTime = BIG_NUMBER;
	}

	void ClearActiveBehaviour(UObject Behaviour)
	{
		ActiveBehaviours.Remove(Behaviour);
		if (ActiveBehaviours.Num() == 0)
			InactiveBehaviourTime = Time::GameTimeSeconds;
	}

	void RegisterBehaviour()
	{
		RegisteredBehaviours++;
	}	

	int GetNumRegisteredBehaviours() const property 
	{
		return RegisteredBehaviours;
	}
}


