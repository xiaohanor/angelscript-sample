/**
 * This component is present on both the Player and AI split tooth.
 */
class UDentistSplitToothComponent : UActorComponent
{
	private AHazeActor HazeOwner;

	bool bIsSplit = false;
	bool bIsAI = false;

	UDentistSplitToothSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		Settings = UDentistSplitToothSettings::GetSettings(HazeOwner);
	}
};