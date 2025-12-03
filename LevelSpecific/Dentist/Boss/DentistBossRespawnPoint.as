class ADentistBossRespawnPoint : ARespawnPoint
{
	bool IsValidToRespawn(AHazePlayerCharacter Player) const override
	{
		auto RespawnTransform = GetPositionForPlayer(Player);

		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		FVector Location = RespawnTransform.Location + FVector::UpVector * Player.CapsuleComponent.CapsuleHalfHeight;
		auto Overlaps = Trace.QueryOverlaps(Location);

		auto TempLog = TEMPORAL_LOG(Player, f"Dentist Boss respawn point: {this}");
		TempLog.OverlapResults("Overlap Results", Overlaps);
		TempLog.Capsule("Capsule Trace", Location, Player.CapsuleComponent.CapsuleRadius, Player.CapsuleComponent.CapsuleHalfHeight, RespawnTransform.Rotator(), FLinearColor::Green);
		for(auto Overlap : Overlaps)
		{
			if(Overlap.bBlockingHit)
			{
				TempLog.Sphere(f"Blocking hit at: {Overlap.Actor}", Overlap.Actor.ActorLocation, 20);
				return false;
			}
		}

		return true;
	}
}