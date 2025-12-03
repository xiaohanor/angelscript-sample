class ASummitTeenDragonClimbRespawnPoint : ARespawnPoint
{
	default bCanMioUse = false;
	default bCanZoeUse = true;	

	//default ListedComponent.bDelistWhileActorDisabled = true;
	//default ListedComponent.OverrideListedClass = ASummitTeenDragonClimbRespawnPoint;

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		auto GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		if(!GeckoClimbComp.bWallClimbRespawnAllowed)
			return;

		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		Trace.UseCapsuleShape(Player.CapsuleComponent);

		const float WallTraceLength = 500.0;
		auto Hits = Trace.QueryTraceMulti(ActorLocation + (ActorUpVector * WallTraceLength), ActorLocation - (ActorUpVector * WallTraceLength));
		//TEMPORAL_LOG(Player).HitResults("Gecko Climb Respawn Trace", Hit, FHazeTraceShape::MakeCapsule(Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight));

		for(auto Hit : Hits)
		{
			auto ClimbableComp = UTeenDragonTailClimbableComponent::Get(Hit.Actor);
			if(ClimbableComp == nullptr)
				continue;

			FTeenDragonTailClimbParams ClimbParams;
			ClimbParams.ClimbComp = ClimbableComp;
			ClimbParams.ClimbUpVector = ClimbableComp.ForwardVector;
			ClimbParams.Location = Hit.Location;
			ClimbParams.WallNormal = ClimbableComp.ForwardVector;
			GeckoClimbComp.WallClimbRespawnParams.Set(ClimbParams);
			break;
		}
	}
}