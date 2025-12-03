class UIslandDroidZiplineAttachTargetable : UContextualMovesTargetableComponent
{
	default TargetableCategory = n"ContextualMoves";
	default UsableByPlayers = EHazeSelectPlayer::Both;
	default ActivationRange = 450.0;
	default AdditionalVisibleRange = 800.0;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		auto ZiplineComp = UIslandDroidZiplinePlayerComponent::Get(Query.Player);
		if(ZiplineComp.CurrentTargetable != nullptr)
			return false;

		return Super::CheckTargetable(Query);
	}
}