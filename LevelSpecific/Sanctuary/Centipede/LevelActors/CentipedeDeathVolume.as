class ACentipedeDeathVolume : APlayerTrigger
{
	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		if (!Player.HasControl())
			return;
		
		UPlayerCentipedeComponent PlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		auto LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(PlayerCentipedeComponent.Centipede);
		LavaIntoleranceComponent.SetHealth(0.0, true);
		LavaIntoleranceComponent.NetSetForceDeath(Player.IsMio());
		Super::TriggerOnPlayerEnter(Player);
	}
}