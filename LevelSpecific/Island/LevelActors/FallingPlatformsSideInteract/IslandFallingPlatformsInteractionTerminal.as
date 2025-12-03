asset IslandFallingPlatformsInteractionSheet of UHazeCapabilitySheet
{
	AddCapability(n"PlayerMovementOvalDirectionInputCapability");
	AddCapability(n"PlayerMovementSquareDirectionInputCapability");
	AddCapability(n"IslandFallingPlatformsPlayerMovePlatformCapability");
	Blocks.Add(CapabilityTags::Movement);
	Blocks.Add(CapabilityTags::GameplayAction);
}

UCLASS(Abstract)
class AIslandFallingPlatformsInteractionTerminal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.InteractionSheet = IslandFallingPlatformsInteractionSheet;
}