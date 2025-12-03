event void FTundraGrabberVinesGrabbedSignature(FTundraGrabberVinesGrabbedData Data);
event void FTundraGrabberVinesReleasedSignature(FTundraGrabberVinesReleasedData Data);
event void FTundraGrabberVinesDestroyedSignature();
class UTundraGrabberVinesResponseComponent : UActorComponent
{
	FTundraGrabberVinesGrabbedSignature OnGrabbed;
	FTundraGrabberVinesReleasedSignature OnReleased;
	FTundraGrabberVinesDestroyedSignature OnDestroyed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.JoinTeam(TundraGrabberVinesTags::TundraGrabberVinesResponseTeam);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.LeaveTeam(TundraGrabberVinesTags::TundraGrabberVinesResponseTeam);
	}
}

struct FTundraGrabberVinesGrabbedData
{
	ATundraGrabberVines Grabber;

	FTundraGrabberVinesGrabbedData(ATundraGrabberVines InGrabber)
	{
		Grabber = InGrabber;
	}
}

struct FTundraGrabberVinesReleasedData
{
	ATundraGrabberVines Grabber;

	FTundraGrabberVinesReleasedData(ATundraGrabberVines InGrabber)
	{
		Grabber = InGrabber;
	}
}