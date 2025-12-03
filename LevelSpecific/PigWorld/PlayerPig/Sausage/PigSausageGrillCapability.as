enum EPigWorldSausageGrillState
{
	None,
	Smoking,
	Flaming
}

class UPigSausageGrillCapability : UHazePlayerCapability
{
	// default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPlayerPigSausageComponent Sasuagecomp;

	float SmokeDuration = 0.1;
	float BurnDuration = 0.15;
	float DeathDuration = 1.5;



	float CookTimer;

	EPigWorldSausageGrillState GrillState;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Sasuagecomp = UPlayerPigSausageComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Sasuagecomp.bIsOnGrill)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Sasuagecomp.bIsOnGrill)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CookTimer = Time::GameTimeSeconds + SmokeDuration;

		FPigWorldSausageParams Params;
		Params.Player = Player;

		UPigSausageEventHandler::Trigger_OnGrillEvent(Player,Params);

		// Sasuagecomp.RemoveCondiments();

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FPigWorldSausageParams Params;
		Params.Player = Player;
		UPigSausageEventHandler::Trigger_OffGrillEvent(Player,Params);
		UPigSausageEventHandler::Trigger_StopFireEvent(Player);
		UPigSausageEventHandler::Trigger_StopSmokeEvent(Player);
		Sasuagecomp.GrillValue = Math::FloorToFloat(Sasuagecomp.GrillValue);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(GrillState == EPigWorldSausageGrillState::None)
		// {
		// 	UPigSausageEventHandler::Trigger_StopSmokeEvent(Player);

		// 	CookTimer = Time::GameTimeSeconds + SmokeDuration;
		// }
		// if(GrillState == EPigWorldSausageGrillState::Smoking)
		// {
		// 	UPigSausageEventHandler::Trigger_StopSmokeEvent(Player);

		// 	GrillState = EPigWorldSausageGrillState::None;
		// 	CookTimer = Time::GameTimeSeconds + SmokeDuration;
		// }
		// if(GrillState == EPigWorldSausageGrillState::Flaming)
		// {			
		// 	UPigSausageEventHandler::Trigger_StopFireEvent(Player);
		// 	UPigSausageEventHandler::Trigger_StopSmokeEvent(Player);

		// 	GrillState = EPigWorldSausageGrillState::None;
		// 	CookTimer = Time::GameTimeSeconds + BurnDuration;
		// }
		Sasuagecomp.GrillHotDog(DeltaTime);


	}
};