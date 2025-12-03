enum EBasicBehaviourPriority
{
	Minimum,
	Low,
	Medium,
	High,
	Maximum,
	NUM,
}

enum EBasicBehaviourRequirement
{
	Movement,
	Focus,
	Animation,
	Weapon,
	Perception,
}

struct FBasicBehaviourClaimedRequirements
{
	int32 RequirementsFlags;
	int Priority;
	FInstigator Instigator;
}

struct FBasicBehaviourRequirements
{
	// If behaviour has any requirements, we will only take behaviour 
	// if no other higher prio behaviour has claimed the requirement
	private int32 RequirementsFlags = 0;

	// If the behaviour has any requirement blocks, these need not be available 
	// to run the behaviour, but will be claimed, blocking any lower prio behaviours
	// from being taken.
	private int32 RequirementsBlocks = 0;

	int Priority = 0;

	void Add(EBasicBehaviourRequirement Requirement)
	{
		RequirementsFlags = RequirementsFlags | (1 << uint(Requirement));
	}

	void Remove(EBasicBehaviourRequirement Requirement)
	{
		RequirementsFlags = RequirementsFlags & ~(1 << uint(Requirement));
	}

	void AddBlock(EBasicBehaviourRequirement Requirement)
	{
		RequirementsBlocks = RequirementsBlocks | (1 << uint(Requirement));
	}

	void Removeblock(EBasicBehaviourRequirement Requirement)
	{
		RequirementsBlocks = RequirementsBlocks & ~(1 << uint(Requirement));
	}

	bool CanClaim(UBasicBehaviourComponent BehaviourComp, FInstigator Instigator) const
	{
		return BehaviourComp.CanClaimRequirements(RequirementsFlags, Priority, Instigator);
	}

	void Claim(UBasicBehaviourComponent BehaviourComp, FInstigator Instigator)
	{
		BehaviourComp.ClaimRequirements(RequirementsFlags | RequirementsBlocks, Priority, Instigator);
	}

	void Release(UBasicBehaviourComponent BehaviourComp, FInstigator Instigator)
	{
		BehaviourComp.ReleaseRequirements(Instigator); 
	}

	// Block an additional requirement. This can be released by Unblock or Release.
	void BlockAdditional(EBasicBehaviourRequirement Requirement, UBasicBehaviourComponent BehaviourComp, FInstigator Instigator)
	{
		BehaviourComp.ClaimSingleRequirement(Requirement, Priority, Instigator);		
	}

	// Unblock a requirement that was previously blocked. You cannot unblock requirements that 
	void UnblockAdditional(EBasicBehaviourRequirement Requirement, UBasicBehaviourComponent BehaviourComp, FInstigator Instigator)
	{
		if (((RequirementsFlags | RequirementsBlocks) & (1 << uint(Requirement))) != 0)
			return; // Can't unblock regular requirement
		BehaviourComp.ReleaseSingleRequirement(Requirement, Instigator);
	}
}
