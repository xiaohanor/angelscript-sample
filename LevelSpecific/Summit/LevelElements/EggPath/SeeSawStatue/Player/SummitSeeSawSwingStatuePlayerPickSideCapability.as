struct FSummitSeeSawSwingStatuePlayerPickSideActivationParams
{
	ASummitSeeSawSwingStatue Statue;
	bool bSwingingLeftSide = false;
}

class USummitSeeSawSwingStatuePlayerPickSideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitSeeSawSwingStatuePlayerComponent StatueComp;
	USwingPointComponent SwingPointBlocked;
	ASummitSeeSawSwingStatue CurrentStatue;

	UPlayerMovementComponent MoveComp;

	bool bSwingingLeftSide = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StatueComp = USummitSeeSawSwingStatuePlayerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitSeeSawSwingStatuePlayerPickSideActivationParams& Params) const
	{
		if(!StatueComp.Statue.IsSet())
			return false;

		ASummitSeeSawSwingStatue Statue = StatueComp.Statue.Value;
		if(Statue.PlayerSwingingFromLeft == Player)
		{
			Params.Statue = Statue;
			Params.bSwingingLeftSide = true;
			return true;
		}
		if(Statue.PlayerSwingingFromRight == Player)
		{
			Params.Statue = Statue;
			Params.bSwingingLeftSide = false;
			return true;
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitSeeSawSwingStatuePlayerPickSideActivationParams Params)
	{
		CurrentStatue = Params.Statue;
		USwingPointComponent SwingPointToBlock = Params.bSwingingLeftSide ? 
			CurrentStatue.RightSwingPointComp : 
			CurrentStatue.LeftSwingPointComp;
		SwingPointToBlock.DisableForPlayer(Player, this);
		SwingPointBlocked = SwingPointToBlock;

		bSwingingLeftSide = Params.bSwingingLeftSide;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingPointBlocked.EnableForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
};