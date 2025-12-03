UCLASS(Abstract)
class UIslandPlayerContextualMovesTargetingComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UContextualMovesWidget> DefaultContextualMoveWidget;

	UPROPERTY()
	TSubclassOf<UContextualMovesWidget> ContextualMovesWidget_Mio;

	UPROPERTY()
	TSubclassOf<UContextualMovesWidget> ContextualMovesWidget_Zoe;

	bool bPrimaryTargetBlockedByForceField = false;
}