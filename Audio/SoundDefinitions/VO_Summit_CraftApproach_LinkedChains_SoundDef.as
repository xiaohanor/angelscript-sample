
UCLASS(Abstract)
class UVO_Summit_CraftApproach_LinkedChains_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnLinkMelted(FSummitLinkedChainOnLinkMeltedParams SummitLinkedChainOnLinkMeltedParams){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	ASummitLinkedChain LinkedChain;
}