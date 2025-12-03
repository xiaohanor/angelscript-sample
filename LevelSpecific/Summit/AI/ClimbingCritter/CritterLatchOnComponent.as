class UCritterLatchOnComponent : UActorComponent
{
	private TArray<FName> FreeSockets;
	private TArray<FName> CrowdedSockets;
	private TMap<AHazeActor, FName> LatchersOn;
	private TArray<AHazeActor> CompleteLatchOn;

	USkeletalMeshComponent Mesh;
	float CrowdingDistance = 200.0;
	float LatchedOnTime = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;

		FreeSockets.Add(n"Head");
		FreeSockets.Add(n"LeftArm");
		FreeSockets.Add(n"RightArm");
		FreeSockets.Add(n"LeftUpLeg");
		FreeSockets.Add(n"RightUpLeg");
		FreeSockets.Add(n"Tail2");
		FreeSockets.Add(n"Tail3");
		FreeSockets.Add(n"Tail4");
		FreeSockets.Add(n"Tail5");
		FreeSockets.Add(n"Tail6");
		FreeSockets.Add(n"Tail7");

		CrowdedSockets.Add(n"LeftWingArm");
		CrowdedSockets.Add(n"RightWingArm");
	}

	FName GetBestFreeSocket(FVector Location) const
	{
		FName Socket = GetClosestFreeSocket(Location, FreeSockets);	
		if (Socket.IsNone())
			Socket = GetClosestFreeSocket(Location, CrowdedSockets);
		return Socket;
	}

	FName GetClosestFreeSocket(FVector Location, TArray<FName> Sockets) const
	{
		float ClosestDistSqr = BIG_NUMBER;
		int iBest = -1;
		for (int i = 0; i < Sockets.Num(); i++)
		{
			FVector SocketLoc = Mesh.GetSocketLocation(Sockets[i]);	
			float DistSqr = Location.DistSquared(SocketLoc);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestDistSqr = DistSqr;
				iBest = i;
			}
		}
		if (Sockets.IsValidIndex(iBest))
			return Sockets[iBest];
		return NAME_None;
	}

	void LatchOn(AHazeActor Latcher, FName Socket)
	{
		if (LatchersOn.Contains(Latcher))
			return;
		if (Socket.IsNone())
			return;

		// Latch on to socket
		LatchersOn.Add(Latcher, Socket);

		// Nearby free sockets are now crowded
		FVector SocketLoc =  Mesh.GetSocketLocation(Socket);
		for (int i = FreeSockets.Num() - 1; i >= 0; i--)
		{
			if (SocketLoc.IsWithinDist(Mesh.GetSocketLocation(FreeSockets[i]), CrowdingDistance))
			{
				CrowdedSockets.Add(FreeSockets[i]);	
				FreeSockets.RemoveAtSwap(i);
			}
		}							
	}

	void Release(AHazeActor Latcher)
	{
		CompleteLatchOn.RemoveSingleSwap(Latcher);
		if (CompleteLatchOn.Num() == 0)
			LatchedOnTime = BIG_NUMBER;

		FName Socket = NAME_None;
		LatchersOn.RemoveAndCopyValue(Latcher, Socket);
		if (Socket.IsNone())
			return;

		// Check if crowded or free
		FVector SocketLoc = Mesh.GetSocketLocation(Socket);
		if (IsCrowded(SocketLoc))
			CrowdedSockets.Add(Socket);
		else
			FreeSockets.Add(Socket);
		// For completeness we should really check if any other crowded sockets should move to free list as well, 
		// but this way we should get more variety
	}

	bool IsCrowded(FVector SocketLoc)
	{
		for (auto Slot : LatchersOn)
		{
			if (SocketLoc.IsWithinDist(Mesh.GetSocketLocation(Slot.Value), CrowdingDistance))
				return true;;
		}
		return false;
	}

	void LatchOnComplete(AHazeActor Critter)
	{
		CompleteLatchOn.AddUnique(Critter);
		float CurTime = Time::GameTimeSeconds;
		if (CurTime < LatchedOnTime)
			LatchedOnTime = CurTime;			
	}

	bool HasCompletedLatchOn(AHazeActor Critter)
	{
		return CompleteLatchOn.Contains(Critter);
	}

	float GetLatchedOnCrittersSpeedFactor()
	{
		if (Time::GameTimeSeconds < LatchedOnTime)
			return 1.0;

		float KillDuration = BIG_NUMBER;		
		for (AHazeActor Critter : CompleteLatchOn)
		{
			if (Critter == nullptr)
				continue;
			KillDuration = Math::Min(KillDuration, USummitClimbingCritterSettings::GetSettings(Critter).LatchOnKillDuration);
		}
		float LatchedOnDuration = Time::GetGameTimeSince(LatchedOnTime);
		return Math::Max(0.0, 1.0 - (LatchedOnDuration / KillDuration));
	}
}
