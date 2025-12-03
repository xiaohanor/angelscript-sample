class ATundraGrabberVines : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	AHazeActor GrabbedActor;

	UPROPERTY()
	TArray<AHazeActor> GrabbedActors;

	UFUNCTION()
	void Grab()
	{
		UHazeTeam Team = HazeTeam::GetTeam(TundraGrabberVinesTags::TundraGrabberVinesResponseTeam);
		if(Team == nullptr)
			return;
		TArray<AHazeActor> Members = Team.GetMembers();

		if(Members.Num() == 1)
			GrabbedActor = Members[0];

		for(AHazeActor Member: Members)
		{
			if (Member == nullptr)
				continue;
			if(!Member.ActorLocation.IsWithinDist(ActorLocation, 600))
				continue;
			UTundraGrabberVinesResponseComponent ResponseComp = UTundraGrabberVinesResponseComponent::GetOrCreate(Member);
			if(ResponseComp != nullptr)
				ResponseComp.OnGrabbed.Broadcast(FTundraGrabberVinesGrabbedData(this));
			GrabbedActors.AddUnique(Member);
		}
	}

	UFUNCTION()
	void Release()
	{
		TArray<AHazeActor> ReleaseActors = GrabbedActors;
		for(AHazeActor ReleaseActor: ReleaseActors)
		{
			UTundraGrabberVinesResponseComponent ResponseComp = UTundraGrabberVinesResponseComponent::GetOrCreate(ReleaseActor);
			if(ResponseComp != nullptr)
				ResponseComp.OnReleased.Broadcast(FTundraGrabberVinesReleasedData(this));
			GrabbedActors.RemoveSwap(ReleaseActor);
		}
		GrabbedActor = nullptr;
	}

	UFUNCTION()
	void Destroy()
	{
		TArray<AHazeActor> ReleaseActors = GrabbedActors;
		for(AHazeActor ReleaseActor: ReleaseActors)
		{
			UTundraGrabberVinesResponseComponent ResponseComp = UTundraGrabberVinesResponseComponent::GetOrCreate(ReleaseActor);
			if(ResponseComp != nullptr)
			{
				ResponseComp.OnReleased.Broadcast(FTundraGrabberVinesReleasedData(this));
				ResponseComp.OnDestroyed.Broadcast();
			}
			GrabbedActors.RemoveSwap(ReleaseActor);
		}
		GrabbedActor = nullptr;
	}
}

namespace TundraGrabberVinesTags
{
	const FName TundraGrabberVinesResponseTeam = n"TundraGrabberVinesResponseTeam";
}