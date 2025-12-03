namespace RemoteHacking
{
	UFUNCTION(BlueprintCallable, Category = "Remote Hacking")
	void StartHacking(URemoteHackingResponseComponent ResponseComp)
	{
		auto HackingComp = URemoteHackingPlayerComponent::Get(Game::Mio);
		HackingComp.StartHacking(ResponseComp);
	}

	UFUNCTION(BlueprintCallable, Category = "Remote Hacking")
	void StopHacking()
	{
		auto HackingComp = URemoteHackingPlayerComponent::Get(Game::Mio);
		HackingComp.StopHacking();
	}

	UFUNCTION(BlueprintCallable, Category = "Remote Hacking")
	void ForceHack(URemoteHackingResponseComponent ResponseComp)
	{
		auto HackingComp = URemoteHackingPlayerComponent::Get(Game::Mio);
		HackingComp.ForceHack(ResponseComp);
	}
}