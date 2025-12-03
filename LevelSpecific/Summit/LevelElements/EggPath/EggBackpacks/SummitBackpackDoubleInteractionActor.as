/**
 * Doubleinteractionactor for playing slot animations on both backpack and players.
 * Not to be confused with BackpackDoubleInteract which is completely different :smoking:
 */
class ASummitBackpackDoubleInteractionActor : ADoubleInteractionActor
{
	UPROPERTY(EditAnywhere, Category = "Double Interaction Animations")
	TPerPlayer<FDoubleInteractionSettings> PlayerBackpackSettings;

	default LeftInteraction.InteractionSheet = SummitBackpackDoubleInteractionSheet;
	default RightInteraction.InteractionSheet = SummitBackpackDoubleInteractionSheet;
};

asset SummitBackpackDoubleInteractionSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USummitBackpackDoubleInteractionCapability);
	Capabilities.Add(USummitBackpackDoubleInteractionEnterAnimationCapability);
	Capabilities.Add(USummitBackpackDoubleInteractionMHAnimationCapability);
	Capabilities.Add(USummitBackpackDoubleInteractionCancelAnimationCapability);
	Capabilities.Add(USummitBackpackDoubleInteractionCompletedAnimationCapability);

	Blocks.Add(n"Movement");
	Blocks.Add(n"GameplayAction");
};