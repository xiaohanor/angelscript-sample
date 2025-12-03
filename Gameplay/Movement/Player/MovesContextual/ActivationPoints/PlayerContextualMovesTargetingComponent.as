class UPlayerContextualMovesTargetingComponent : UActorComponent
{
	UPROPERTY()
	UClass DefaultContextualMoveWidget;

	UPROPERTY()
	UClass ContextualMovesWidget_Mio;

	UPROPERTY()
	UClass ContextualMovesWidget_Zoe;

	float AuraAnimationCooldownUntil = 0;
}