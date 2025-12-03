struct FSandSharkPlayerOnSafePointActivateParams
{
	ASandSharkSafePoint InitialSafePoint;
}

class USandSharkPlayerOnSafePointCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;

	USandSharkPlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandSharkPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	/**
	 * A struct reference parameter can be added on ShouldActivate/ShouldDeactivate, and a matching non-reference on OnActivated/OnDeactivated
	 * This allows sending values from ShouldActivate to OnActivated, in this case we want the SafePoint we found to be sent so that we don't need to find it again.
	 * This also serves 2 more purposes:
	 * 1. We may want to know why we activated or deactivated, like some capabilities do in SandShark with a bSuccess or bFinished bool (see AttackFromBelowJump).
	 * If that bool is false, then we were blocked or deactivated unexpectedly, which might need extra handling.
	 * 2. In networked play, the parameter is send with an RPC to the remote player. This allows for syncing the initial state of a capability.
	 * For example, in this capability the ground hit might not be present on the remote since the movement is replicated, not performed locally.
	 * And the GetHitUnderPlayer() might return a different value than on the control side.
	 * Usually we send everything that could vary in the OnActivated/OnDeactivated function in the parameter.
	 */
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSandSharkPlayerOnSafePointActivateParams& Params) const
	{
		if(PlayerComp.bIsPerching)
			return false;

		ASandSharkSafePoint InitialSafePoint;
		if(MoveComp.HasGroundContact())
		{
			// Find SafePoint from the ground impact
			auto SafePoint = SandShark::SafePoint::GetSafePointForActor(MoveComp.GroundContact.Actor);
			if(SafePoint == nullptr)
				return false;

			InitialSafePoint = SafePoint;
		}
		else if(PlayerComp.GetHitUnderPlayer().IsValidBlockingHit())
		{
			// Find SafePoint from the HitUnderPlayer result
			auto SafePoint = SandShark::SafePoint::GetSafePointForActor(PlayerComp.GetHitUnderPlayer().Actor);
			if(SafePoint == nullptr)
				return false;

			InitialSafePoint = SafePoint;
		}
		else
		{
			return false;
		}

		auto SwingComp = UPlayerSwingComponent::Get(Player);
		if(SwingComp.Data.HasValidSwingPoint())
			return false;

		Params.InitialSafePoint = InitialSafePoint;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.bIsPerching)
			return true;

		if(MoveComp.HasGroundContact())
		{
			// See if we landed on something that's not a safe point
			auto SafePoint = SandShark::SafePoint::GetSafePointForActor(MoveComp.GroundContact.Actor);
			if(SafePoint == nullptr)
				return true;
		}
		else if(PlayerComp.GetHitUnderPlayer().IsValidBlockingHit())
		{
			// See if there's something solid under us that's not a safe point
			auto SafePoint = SandShark::SafePoint::GetSafePointForActor(PlayerComp.GetHitUnderPlayer().Actor);
			if(SafePoint == nullptr)
				return true;
		}

		auto SwingComp = UPlayerSwingComponent::Get(Player);
		if(SwingComp.Data.HasValidSwingPoint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSandSharkPlayerOnSafePointActivateParams Params)
	{
		PlayerComp.LastSafePoint = Params.InitialSafePoint;
		PlayerComp.bOnSafePoint = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Don't reset LastSafePoint because then it will be nullptr in capabilities that deactivate when bOnSafePoint is false, but still want to access LastSafePoint
		PlayerComp.bOnSafePoint = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if(PlayerComp.GetHitUnderPlayer().IsValidBlockingHit())
			{
				auto SafePoint = SandShark::SafePoint::GetSafePointForActor(PlayerComp.GetHitUnderPlayer().Actor);
				if(SafePoint == nullptr)
					return;

				// We are still on a safepoint, but it's not the same as before
				if(SafePoint != PlayerComp.LastSafePoint)
				{
					// Change last safe point
					PlayerComp.LastSafePoint = SafePoint;
				}
			}
		}
	}
};