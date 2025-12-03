UCLASS(Abstract)
class ATundraRaptorCirclePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JoinTeam(TundraRaptorTags::TundraRaptorPointTeam);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(TundraRaptorTags::TundraRaptorPointTeam);
	}
}