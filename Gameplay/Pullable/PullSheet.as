

namespace Pullable
{

asset PullSheet of UHazeCapabilitySheet
{
	AddCapability(n"PlayerPullableInputCapability");
	AddCapability(n"PlayerPullableMovementCapability");
	AddCapability(n"PlayerMovementOvalDirectionInputCapability");
	AddCapability(n"PlayerMovementSquareDirectionInputCapability");

	Blocks.Add(CapabilityTags::Collision);
	Blocks.Add(CapabilityTags::Movement);
	Blocks.Add(CapabilityTags::GameplayAction);
};

}