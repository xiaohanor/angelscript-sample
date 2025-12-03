class USanctuaryWeeper2DViewComponent : USanctuaryWeeperViewComponent
{
	bool ShouldFreeze() override
	{
		return false;
		// AHazePlayerCharacter Onlooker;
		// return HasOnlooker(Onlooker);
	}

	bool ShouldDodge(FVector& Direction) override
	{
		AHazePlayerCharacter Onlooker;
		bool ShouldDodge = HasOnlooker(Onlooker);
		
		if(ShouldDodge)
		{
			FVector ProjectedLoc = Math::ClosestPointOnInfiniteLine(Onlooker.ViewLocation, Onlooker.ViewLocation + Onlooker.ViewRotation.Vector(), HazeOwner.ActorCenterLocation);
			FVector LeftVector = HazeOwner.ActorRightVector * -1;
			bool DodgeRight = (HazeOwner.ActorLocation + HazeOwner.ActorRightVector).Distance(ProjectedLoc) > (HazeOwner.ActorLocation + LeftVector).Distance(ProjectedLoc);
			if(DodgeRight)
				Direction = HazeOwner.ActorRightVector;
			else
				Direction = LeftVector;
		}
		
		return ShouldDodge;
	}

	private bool HasOnlooker(AHazePlayerCharacter& Onlooker)
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(WeeperSettings.FreezeIgnoreMioView && Player == Game::Mio)
				continue;
			if(WeeperSettings.FreezeIgnoreZoeView && Player == Game::Zoe)
				continue;

			if(!IsWithinAngle(Player))
				continue;
			
			if(!HasLineOfSight(Player))
				continue;
			
			if(Onlooker == nullptr)
				Onlooker = Player;
		}

		if(Onlooker != nullptr)
			return true;

		return false;
	}

	private bool IsWithinAngle(AHazePlayerCharacter ViewPlayer)
	{
		float Angle = WeeperSettings.Freeze2DAngle / 2;
	   	FVector Direction = (HazeOwner.ActorCenterLocation - ViewPlayer.ActorCenterLocation).GetSafeNormal();
		FVector FreezeConeDirection = ViewPlayer.ActorForwardVector;
		auto TopDownPlayerComp = USanctuaryWeeperTopDownPlayerComponent::Get(ViewPlayer);
		// if(TopDownPlayerComp != nullptr)
		// {
		// 	FreezeConeDirection = TopDownPlayerComp.LightConeDirection;
		// }

		// Debug::DrawDebugLine(ViewPlayer.ActorCenterLocation, ViewPlayer.ActorCenterLocation + FreezeConeDirection.RotateAngleAxis(Angle, FVector::UpVector) * 1000.0, LineColor = FLinearColor::Yellow, Thickness = 10.0);
		// Debug::DrawDebugLine(ViewPlayer.ActorCenterLocation, ViewPlayer.ActorCenterLocation + FreezeConeDirection.RotateAngleAxis(-Angle, FVector::UpVector) * 1000.0, LineColor = FLinearColor::Yellow, Thickness = 10.0);
		

		return FreezeConeDirection.GetAngleDegreesTo(Direction) < Angle;
	}


	bool HasLineOfSight(AHazePlayerCharacter ViewPlayer)
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		TraceSettings.IgnoreActor(ViewPlayer);
		TraceSettings.IgnoreActor(Owner);

		auto HitResult = TraceSettings.QueryTraceSingle(ViewPlayer.ActorCenterLocation, Cast<AHazeActor>(Owner).ActorCenterLocation);

		if(HitResult.bBlockingHit)
		{
			Debug::DrawDebugLine(HitResult.TraceStart, HitResult.ImpactPoint, FLinearColor::Red, 5, 0);
			return false;
		}

		return true;
	}
	
}