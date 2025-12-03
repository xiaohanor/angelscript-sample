class AIslandJetpackRespawnPoint : ARespawnPoint
{
	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		Super::OnRespawnTriggered(Player);
		
		auto JetpackComp = UIslandJetpackComponent::Get(Player);
		JetpackComp.bActivatedExternally = true;
		JetpackComp.FillCharge();
	}
}