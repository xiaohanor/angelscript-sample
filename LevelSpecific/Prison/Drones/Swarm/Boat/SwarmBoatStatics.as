namespace SwarmBoat
{
	UFUNCTION(BlueprintCallable, Category = "Swarm Boat")
	void EnterRapids(AHazeActor SplineActor)
	{
		auto BoatComp = UPlayerSwarmBoatComponent::Get(Drone::GetSwarmDronePlayer());
		BoatComp.EnterRapids(SplineActor);
		USwarmBoatEventHandler::Trigger_EnterRapids(Drone::GetSwarmDronePlayer());
	}

	UFUNCTION(BlueprintCallable, Category = "Swarm Boat")
	void ExitRapids()
	{
		auto BoatComp = UPlayerSwarmBoatComponent::Get(Drone::GetSwarmDronePlayer());
		BoatComp.ExitRapids();
		USwarmBoatEventHandler::Trigger_ExitRapids(Drone::GetSwarmDronePlayer());
	}
}