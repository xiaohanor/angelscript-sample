class UEnforcerHoveringComponent : UActorComponent
{
	UScenepointComponent HoverScenepoint;
	UScenepointComponent StuckWhenMovingToScenepoint;
	int StuckWithNoActionCounter = 0;
	TInstigated<ASkylineJetpackCombatZone> TargetBillboardZone;
}
