class UDarkMassTargetComponent : UTargetableComponent
{
	default TargetableCategory = n"DarkMass";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		// Filtering distance here would require us to get the user component
		//  since the default query is based on the player's distance
		return true;
	}
}