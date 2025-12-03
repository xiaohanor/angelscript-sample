struct FTundraSideInteractSwingPushEffectParams
{
	FTundraSideInteractSwingPushEffectParams(AHazePlayerCharacter In_PushingPlayer, AHazePlayerCharacter In_SwingingPlayer)
	{
		PushingPlayer = In_PushingPlayer;
		SwingingPlayer = In_SwingingPlayer;
	}

	UPROPERTY()
	AHazePlayerCharacter PushingPlayer;
	
	UPROPERTY()
	AHazePlayerCharacter SwingingPlayer;
}

struct FTundraSideInteractSwingInteractEffectParams
{
	FTundraSideInteractSwingInteractEffectParams(AHazePlayerCharacter In_InteractingPlayer)
	{
		InteractingPlayer = In_InteractingPlayer;
	}
	
	UPROPERTY()
	AHazePlayerCharacter InteractingPlayer;
}

struct FTundraSideInteractSwingLaunchEffectParams
{
	FTundraSideInteractSwingLaunchEffectParams(AHazePlayerCharacter In_LaunchedPlayer)
	{
		LaunchedPlayer = In_LaunchedPlayer;
	}
	
	UPROPERTY()
	AHazePlayerCharacter LaunchedPlayer;
}

UCLASS(Abstract)
class UTundraSideInteractSwingEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnterSwing(FTundraSideInteractSwingInteractEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExitSwing(FTundraSideInteractSwingInteractEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSnowMonkeyPunchSwing(FTundraSideInteractSwingPushEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingingPlayerLaunched(FTundraSideInteractSwingLaunchEffectParams Params) {}
}