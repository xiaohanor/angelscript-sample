asset SlidingDiscPlayerMioRemoteBoatFakeoutSnapCapabilitySheet of UHazeCapabilitySheet
{
	Capabilities.Add(USlidingDiscPlayerMioRemoteBoatFakeoutSnapCapability);
}

class USlidingDiscPlayerMioRemoteBoatFakeoutSnapCapability : UHazePlayerCapability
{ 
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	// before air motion :glare: bc airmotion acts on local remote and unfollows the flipping disc >_>
	default TickGroupOrder = 159; 

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	USlidingDiscPlayerComponent DiscComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		DiscComp = USlidingDiscPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsMio())
			return false;

		if (HasControl()) // WHAT only remote?? :smirk:
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!DiscComp.bInWaterSwitchSegment)
			return false;

		if (Player.AttachParentActor != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.AttachParentActor != nullptr)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!DiscComp.bInWaterSwitchSegment)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.FindGround(100);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			MoveComp.FindGround(100);
			Movement.AddDelta(FVector());
			MoveComp.ApplyMove(Movement);
		}
	}
};