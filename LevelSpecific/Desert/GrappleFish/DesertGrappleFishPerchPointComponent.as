class UDesertGrappleFishPerchPointComponent : UPerchPointComponent
{
	default bShowForOtherPlayer = false;
	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (!Super::CheckTargetable(Query))
			return false;

		if (IsPlayerOnPerchPoint[Query.Player.OtherPlayer])
		{
			return false;
		}

		return true;
	}
}